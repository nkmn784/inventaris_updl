import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import '../services/firestore_service.dart';
import 'tambah_barang_screen.dart';
import 'detail_barang_screen.dart';

class DaftarBarangScreen extends StatefulWidget {
  final String namaKategori;

  const DaftarBarangScreen({super.key, required this.namaKategori});

  @override
  State<DaftarBarangScreen> createState() => _DaftarBarangScreenState();
}

class _DaftarBarangScreenState extends State<DaftarBarangScreen> {
  String _searchQuery = '';
  bool _isExporting = false;

  String _namaBulan(int bulan) {
    const listBulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return listBulan[bulan - 1];
  }

  // Helper untuk format tanggal terakhir di-edit
  String _formatTanggalEdit(Map<String, dynamic> data) {
    dynamic val =
        data['updated_at'] ??
        data['tanggal_edit'] ??
        data['terakhir_diubah'] ??
        data['updatedAt'];

    if (val == null) return '';

    if (val is Timestamp) {
      DateTime dt = val.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } else if (val is String && val.trim().isNotEmpty) {
      if (val.contains('T')) {
        return val.split('T')[0];
      }
      return val;
    }
    return '';
  }

  String _getItemValue(
    Map<String, dynamic> docData,
    Map<String, dynamic> checklistMap,
    List<String> fieldAliases, {
    String defaultValue = '✓',
  }) {
    for (var alias in fieldAliases) {
      if (docData.containsKey(alias) &&
          docData[alias] != null &&
          docData[alias].toString().trim().isNotEmpty) {
        var val = docData[alias];
        if (val is bool) return val ? '✓' : 'x';
        return val.toString();
      }
    }

    if (checklistMap.isNotEmpty) {
      for (var alias in fieldAliases) {
        if (checklistMap.containsKey(alias) && checklistMap[alias] != null) {
          var val = checklistMap[alias];
          if (val is bool) return val ? '✓' : 'x';
          return val.toString();
        }
        for (var entry in checklistMap.entries) {
          String cleanKey = entry.key
              .toLowerCase()
              .replaceAll(RegExp(r'[_-]'), ' ')
              .trim();
          String cleanAlias = alias
              .toLowerCase()
              .replaceAll(RegExp(r'[_-]'), ' ')
              .trim();

          if (cleanKey == cleanAlias) {
            var val = entry.value;
            if (val is bool) return val ? '✓' : 'x';
            return val.toString();
          }
        }
      }
    }
    return defaultValue;
  }

  // ==========================================
  // EXPORT EXCEL
  // ==========================================
  Future<void> _unduhLaporanExcel() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Text('Menyiapkan laporan ${widget.namaKategori}...'),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection(widget.namaKategori)
          .get();

      if (snapshot.docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
        );
        setState(() => _isExporting = false);
        return;
      }

      var excel = Excel.createExcel();
      String sheetName = widget.namaKategori;
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheet, sheetName);
      Sheet sheetObject = excel[sheetName];

      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
      CellStyle centerAlign = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
      );

      DateTime now = DateTime.now();
      String bulanTahun = '${_namaBulan(now.month).toUpperCase()} ${now.year}';
      String tanggalHariIni =
          '${now.day.toString().padLeft(2, '0')} ${_namaBulan(now.month)} ${now.year}';

      String kategoriUpper = widget.namaKategori.toUpperCase();

      // EXCEL APAR
      if (kategoriUpper.contains('APAR')) {
        sheetObject.cell(CellIndex.indexByString('C1')).value = TextCellValue(
          'ALAT PEMADAM API RINGAN (APAR)',
        );
        sheetObject.cell(CellIndex.indexByString('C1')).cellStyle = headerStyle;
        sheetObject.cell(CellIndex.indexByString('C2')).value = TextCellValue(
          'BULAN / TAHUN : $bulanTahun',
        );

        sheetObject.cell(CellIndex.indexByString('A4')).value = TextCellValue(
          'Pemeriksa',
        );
        sheetObject.cell(CellIndex.indexByString('C4')).value = TextCellValue(
          ': Arya Junadi',
        );
        sheetObject.cell(CellIndex.indexByString('A5')).value = TextCellValue(
          'Tanggal Pemeriksaan',
        );
        sheetObject.cell(CellIndex.indexByString('C5')).value = TextCellValue(
          ': $tanggalHariIni',
        );

        List<String> headers = [
          'NO',
          'LOKASI',
          'NAMA ALAT (MERK)',
          'NO APAR',
          'BERAT (KG)',
          'TGL KADALUARSA',
          'Label Pengisian',
          'Tekanan',
          'Safety Pin',
          'Handle',
          'Selang & Nozzle',
          'Keterangan',
          'Latitude',
          'Longitude',
        ];

        for (int i = 0; i < headers.length; i++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 6),
          );
          cell.value = TextCellValue(headers[i]);
          cell.cellStyle = headerStyle;
        }

        int rowIndex = 7;
        int nomorUrut = 1;

        for (var doc in snapshot.docs) {
          final data = doc.data();

          String setCeklis(dynamic val) {
            if (val == true) return '✓';
            if (val == false) return 'x';
            return '-';
          }

          String rawTgl = data['tanggal_kadaluarsa']?.toString() ?? '-';
          String tglClean = rawTgl.contains('T')
              ? rawTgl.split('T')[0]
              : rawTgl;

          List<String> rowData = [
            nomorUrut.toString(),
            data['lokasi']?.toString() ?? '-',
            data['nama_alat']?.toString() ?? '-',
            data['no_apar']?.toString() ?? '-',
            data['berat']?.toString() ?? '-',
            tglClean,
            setCeklis(data['checklist_label']),
            setCeklis(data['checklist_tekanan']),
            setCeklis(data['checklist_safety_pin']),
            setCeklis(data['checklist_handle']),
            setCeklis(data['checklist_selang']),
            data['keterangan']?.toString() ?? '-',
            data['latitude']?.toString() ?? '-',
            data['longitude']?.toString() ?? '-',
          ];

          for (int i = 0; i < rowData.length; i++) {
            sheetObject
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: i,
                    rowIndex: rowIndex,
                  ),
                )
                .value = TextCellValue(
              rowData[i],
            );
          }
          rowIndex++;
          nomorUrut++;
        }

        // EXCEL P3K
      } else if (kategoriUpper.contains('P3K')) {
        sheetObject.cell(CellIndex.indexByString('B1')).value = TextCellValue(
          'IDENTIFIKASI KEBUTUHAN KOTAK P3K',
        );
        sheetObject.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;
        sheetObject.cell(CellIndex.indexByString('B2')).value = TextCellValue(
          'DI PT PLN (PERSERO) UPDL PANDAAN',
        );
        sheetObject.cell(CellIndex.indexByString('B3')).value = TextCellValue(
          'BULAN $bulanTahun',
        );

        List<String> headersP3K = [
          'No',
          'Gedung/Ruang',
          'KAPASITAS',
          'EXISTING',
          'REKOMENDASI',
          'KASA STERIL',
          'PERBAN (5CM)',
          'PERBAN (10CM)',
          'PLASTER (1,25CM)',
          'PLASTER CEPAT',
          'KAPAS',
          'KAIN SEGTIGA',
          'GUNTING',
          'PENITI',
          'SARUNG TANGAN SEKALIPAKAI',
          'SARUNG TANGAN PASANGAN',
          'MASKER',
          'PINSET',
          'LAMPU SENTER',
          'GELAS CUCI MATA',
          'KANTUNG PLASTIK BERSIH',
          'AQUADES (25ML)',
          'POVIDON',
          'ALCOHOL 70%',
          'BUKU PANDUAN',
          'BUKU CATATAN',
          'DAFTAR ISI KOTAK P3K',
          'Kekurangan',
          'Latitude',
          'Longitude',
        ];

        for (int i = 0; i < headersP3K.length; i++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4),
          );
          cell.value = TextCellValue(headersP3K[i]);
          cell.cellStyle = headerStyle;
        }

        List<List<String>> itemAliases = [
          ['kasa_steril', 'KASA STERIL', 'kasa steril'],
          ['perban_5cm', 'PERBAN (5CM)', 'perban 5cm'],
          ['perban_10cm', 'PERBAN (10CM)', 'perban 10cm'],
          ['plaster_1_25cm', 'PLASTER (1,25CM)', 'plaster 1.25cm'],
          ['plaster_cepat', 'PLASTER CEPAT'],
          ['kapas', 'KAPAS'],
          ['kain_segtiga', 'KAIN SEGTIGA', 'kain segitiga'],
          ['gunting', 'GUNTING'],
          ['peniti', 'PENITI'],
          ['sarung_tangan_sekalipakai', 'SARUNG TANGAN SEKALIPAKAI'],
          ['sarung_tangan_pasangan', 'SARUNG TANGAN PASANGAN'],
          ['masker', 'MASKER'],
          ['pinset', 'PINSET'],
          ['lampu_senter', 'LAMPU SENTER'],
          ['gelas_cuci_mata', 'GELAS CUCI MATA'],
          ['kantung_plastik_bersih', 'KANTUNG PLASTIK BERSIH'],
          ['exp_aquades', 'AQUADES (25ML)', 'aquades'],
          ['exp_povidon', 'POVIDON', 'povidon'],
          ['exp_alcohol', 'ALCOHOL 70%', 'alcohol'],
          ['buku_panduan', 'BUKU PANDUAN'],
          ['buku_catatan', 'BUKU CATATAN'],
          ['daftar_isi_kotak', 'DAFTAR ISI KOTAK P3K'],
        ];

        int rowIndex = 5;
        int nomorUrut = 1;

        for (var doc in snapshot.docs) {
          final data = doc.data();
          Map<String, dynamic> checklistMap = Map<String, dynamic>.from(
            data['checklist_items'] ?? {},
          );

          List<String> rowData = [
            nomorUrut.toString(),
            data['gedung_ruang']?.toString() ??
                data['lokasi']?.toString() ??
                '-',
            data['kapasitas']?.toString() ?? '-',
            data['existing']?.toString() ?? '-',
            data['rekomendasi']?.toString() ?? '-',
          ];

          for (int i = 0; i < itemAliases.length; i++) {
            rowData.add(_getItemValue(data, checklistMap, itemAliases[i]));
          }

          rowData.add(
            data['kekurangan']?.toString() ??
                data['keterangan']?.toString() ??
                '-',
          );
          rowData.add(data['latitude']?.toString() ?? '-');
          rowData.add(data['longitude']?.toString() ?? '-');

          for (int i = 0; i < rowData.length; i++) {
            sheetObject
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: i,
                    rowIndex: rowIndex,
                  ),
                )
                .value = TextCellValue(
              rowData[i],
            );
          }
          rowIndex++;
          nomorUrut++;
        }

        // EXCEL APD
      } else if (kategoriUpper.contains('APD')) {
        sheetObject.merge(
          CellIndex.indexByString('A1'),
          CellIndex.indexByString('G1'),
          customValue: TextCellValue('INVENTARIS PERALATAN K3 (APD)'),
        );
        sheetObject.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;

        List<String> headersAPD = [
          'No.',
          'Peralatan',
          'Jumlah',
          'Masa Pakai',
          'Tanggal Kadaluwarsa',
          'Kondisi',
          'Pembelian',
        ];

        for (int i = 0; i < headersAPD.length; i++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
          );
          cell.value = TextCellValue(headersAPD[i]);
          cell.cellStyle = headerStyle;
        }

        int rowIndex = 3;
        int nomorUrut = 1;

        String formatData(dynamic data) {
          if (data == null || data.toString().trim().isEmpty) return '-';
          return data.toString();
        }

        for (var doc in snapshot.docs) {
          final data = doc.data();
          List<String> rowData = [
            nomorUrut.toString(),
            formatData(
              data['peralatan'] ??
                  data['nama_apd'] ??
                  data['nama_barang'] ??
                  data['nama'],
            ),
            formatData(data['jumlah'] ?? data['stok'] ?? data['qty']),
            formatData(data['masa_pakai']),
            formatData(data['tanggal_kadaluarsa']),
            formatData(data['kondisi']),
            formatData(data['pembelian']),
          ];

          for (int i = 0; i < rowData.length; i++) {
            var cell = sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
            );
            cell.value = TextCellValue(rowData[i]);

            if (i != 1) {
              cell.cellStyle = centerAlign;
            }
          }
          rowIndex++;
          nomorUrut++;
        }

        rowIndex += 2;
        String tanggalTTD = '${now.day} ${_namaBulan(now.month)} ${now.year}';

        sheetObject.merge(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
          customValue: TextCellValue(tanggalTTD),
        );
        sheetObject
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: 5,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            centerAlign;

        rowIndex++;
        sheetObject.merge(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
          customValue: TextCellValue('TL K3L & KAM'),
        );
        sheetObject
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: 5,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            centerAlign;

        rowIndex += 4;
        sheetObject.merge(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
          customValue: TextCellValue('ANUGRA PUTRA PERMANA'),
        );
        sheetObject
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: 5,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            centerAlign;

        // EXCEL ATK
      } else if (kategoriUpper.contains('ATK')) {
        sheetObject.merge(
          CellIndex.indexByString('A1'),
          CellIndex.indexByString('G1'),
          customValue: TextCellValue(
            'LAPORAN INVENTARIS ALAT TULIS KANTOR (ATK)',
          ),
        );
        sheetObject.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;

        sheetObject.cell(CellIndex.indexByString('A2')).value = TextCellValue(
          'BULAN / TAHUN : $bulanTahun',
        );

        List<String> headersATK = [
          'No.',
          'Nama Barang',
          'Jumlah',
          'Satuan',
          'Lokasi / Ruang',
          'Kondisi',
          'Keterangan',
        ];

        for (int i = 0; i < headersATK.length; i++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3),
          );
          cell.value = TextCellValue(headersATK[i]);
          cell.cellStyle = headerStyle;
        }

        int rowIndex = 4;
        int nomorUrut = 1;

        String formatData(dynamic data) {
          if (data == null || data.toString().trim().isEmpty) return '-';
          return data.toString();
        }

        for (var doc in snapshot.docs) {
          final data = doc.data();
          List<String> rowData = [
            nomorUrut.toString(),
            formatData(data['nama_barang'] ?? data['nama_atk'] ?? data['nama']),
            formatData(data['jumlah'] ?? data['stok'] ?? data['qty']),
            formatData(data['satuan']),
            formatData(data['lokasi'] ?? data['gedung_ruang']),
            formatData(data['kondisi']),
            formatData(data['keterangan']),
          ];

          for (int i = 0; i < rowData.length; i++) {
            var cell = sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
            );
            cell.value = TextCellValue(rowData[i]);

            if (i != 1) {
              cell.cellStyle = centerAlign;
            }
          }
          rowIndex++;
          nomorUrut++;
        }

        // KATEGORI LAINNYA
      } else {
        sheetObject.cell(CellIndex.indexByString('A1')).value = TextCellValue(
          'LAPORAN DATA ${widget.namaKategori.toUpperCase()}',
        );
        sheetObject.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
        sheetObject.cell(CellIndex.indexByString('A2')).value = TextCellValue(
          'BULAN / TAHUN : $bulanTahun',
        );

        List<String> headersLain = [
          'NO',
          'NAMA BARANG',
          'LOKASI',
          'KETERANGAN',
          'LATITUDE',
          'LONGITUDE',
        ];

        for (int i = 0; i < headersLain.length; i++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3),
          );
          cell.value = TextCellValue(headersLain[i]);
          cell.cellStyle = headerStyle;
        }

        int rowIndex = 4;
        int nomorUrut = 1;

        for (var doc in snapshot.docs) {
          final data = doc.data();
          List<String> rowData = [
            nomorUrut.toString(),
            data['nama_barang']?.toString() ??
                data['nama']?.toString() ??
                data['nama_alat']?.toString() ??
                '-',
            data['lokasi']?.toString() ?? '-',
            data['keterangan']?.toString() ?? '-',
            data['latitude']?.toString() ?? '-',
            data['longitude']?.toString() ?? '-',
          ];

          for (int i = 0; i < rowData.length; i++) {
            sheetObject
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: i,
                    rowIndex: rowIndex,
                  ),
                )
                .value = TextCellValue(
              rowData[i],
            );
          }
          rowIndex++;
          nomorUrut++;
        }
      }

      var fileBytes = excel.encode();
      if (fileBytes == null) throw Exception("Gagal membuat file Excel");

      final String namaFile =
          'Laporan_${widget.namaKategori}_${DateTime.now().millisecondsSinceEpoch}';

      await FileSaver.instance.saveFile(
        name: '$namaFile.xlsx',
        bytes: Uint8List.fromList(fileBytes),
        mimeType: MimeType.microsoftExcel,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan ${widget.namaKategori} berhasil diunduh!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh laporan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: Text(
          widget.namaKategori,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.blue),
                  tooltip: 'Unduh Laporan Excel',
                  onPressed: _unduhLaporanExcel,
                ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari ${widget.namaKategori.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().getBarangByKategori(
                widget.namaKategori,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Terjadi kesalahan saat memuat data.'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada data ${widget.namaKategori}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final dokumen = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final kategoriData = (data['kategori'] ?? widget.namaKategori)
                      .toString()
                      .toUpperCase();

                  String searchString = '';
                  if (kategoriData.contains('APAR')) {
                    searchString =
                        '${data['nama_alat'] ?? ''} ${data['no_apar'] ?? ''} ${data['lokasi'] ?? ''}';
                  } else if (kategoriData.contains('P3K')) {
                    searchString =
                        '${data['gedung_ruang'] ?? ''} ${data['lokasi'] ?? ''}';
                  } else if (kategoriData.contains('APD')) {
                    searchString =
                        '${data['peralatan'] ?? data['nama_apd'] ?? data['nama_barang'] ?? ''} ${data['kondisi'] ?? ''} ${data['pembelian'] ?? ''}';
                  } else if (kategoriData.contains('ATK')) {
                    searchString =
                        '${data['nama_barang'] ?? data['nama_atk'] ?? data['nama'] ?? ''} ${data['lokasi'] ?? data['gedung_ruang'] ?? ''} ${data['keterangan'] ?? ''}';
                  } else {
                    searchString =
                        '${data['nama_barang'] ?? data['nama'] ?? data['nama_alat'] ?? ''} ${data['lokasi'] ?? ''}';
                  }

                  return searchString.toLowerCase().contains(_searchQuery);
                }).toList();

                if (dokumen.isEmpty) {
                  return Center(
                    child: Text(
                      'Barang tidak ditemukan',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dokumen.length,
                  itemBuilder: (context, index) {
                    final data = dokumen[index].data() as Map<String, dynamic>;
                    final docId = dokumen[index].id;
                    final kategoriData =
                        (data['kategori'] ?? widget.namaKategori)
                            .toString()
                            .toUpperCase();

                    String judulUtama = '';
                    String infoHighlight = '';
                    String infoSekunder = '';
                    bool isWarning = false;
                    String? imageUrl = data['foto_url'];

                    // Format Tanggal Edit Terakhir
                    String tglEdit = _formatTanggalEdit(data);
                    String labelTanggalEdit = tglEdit.isNotEmpty
                        ? 'Diubah: $tglEdit'
                        : '';

                    // ==========================================
                    // APAR
                    // ==========================================
                    if (kategoriData.contains('APAR')) {
                      // DIUBAH: Menampilkan No APAR sebagai judul utama
                      judulUtama = 'APAR No. ${data['no_apar'] ?? '-'}';
                      // DIUBAH: Menampilkan berat sebagai highlight
                      infoHighlight = '${data['berat'] ?? '-'} Kg';
                      // DIUBAH: Menampilkan lokasi di bawah judul/highlight
                      infoSekunder = 'Lokasi: ${data['lokasi'] ?? '-'}';

                      bool tekananAman = data['checklist_tekanan'] ?? true;
                      bool pinAman = data['checklist_safety_pin'] ?? true;
                      isWarning = (!tekananAman || !pinAman);

                      // ==========================================
                      // P3K
                      // ==========================================
                    } else if (kategoriData.contains('P3K')) {
                      judulUtama =
                          data['gedung_ruang'] ??
                          data['lokasi'] ??
                          'Tanpa Nama Ruangan';
                      infoHighlight = '${data['kapasitas'] ?? 0} Org';
                      infoSekunder = labelTanggalEdit.isNotEmpty
                          ? labelTanggalEdit
                          : 'Ext: ${data['existing'] ?? '-'}';
                      isWarning = false;

                      // ==========================================
                      // APD (ALAT PELINDUNG DIRI)
                      // ==========================================
                    } else if (kategoriData.contains('APD')) {
                      judulUtama =
                          data['peralatan'] ??
                          data['nama_apd'] ??
                          data['nama_barang'] ??
                          'APD Tanpa Nama';

                      dynamic rawJml =
                          data['jumlah'] ?? data['stok'] ?? data['qty'];
                      infoHighlight = 'Jml: ${rawJml ?? 0}';

                      if (labelTanggalEdit.isNotEmpty) {
                        infoSekunder = labelTanggalEdit;
                      } else if (data['pembelian'] != null &&
                          data['pembelian'].toString().isNotEmpty) {
                        infoSekunder = 'Pembelian: ${data['pembelian']}';
                      } else {
                        infoSekunder = 'Kondisi: ${data['kondisi'] ?? 'Baik'}';
                      }

                      isWarning =
                          (data['kondisi']?.toString().toLowerCase().contains(
                            'rusak',
                          ) ??
                          false);

                      // ==========================================
                      // ATK (ALAT TULIS KANTOR)
                      // ==========================================
                    } else if (kategoriData.contains('ATK')) {
                      judulUtama =
                          data['nama_barang'] ??
                          data['nama_atk'] ??
                          data['nama'] ??
                          'ATK Tanpa Nama';

                      dynamic rawJml =
                          data['sisa_jumlah'] ??
                          data['stok_sekarang'] ??
                          data['jumlah'] ??
                          data['stok'] ??
                          data['qty'] ??
                          0;

                      String satuan =
                          (data['satuan'] != null &&
                              data['satuan'].toString().trim().isNotEmpty)
                          ? ' ${data['satuan']}'
                          : '';

                      infoHighlight = 'Jml: $rawJml$satuan';

                      String tglTransaksi = '';
                      if (data['tanggal_transaksi'] != null) {
                        DateTime? dt = DateTime.tryParse(
                          data['tanggal_transaksi'].toString(),
                        );
                        if (dt != null) {
                          tglTransaksi =
                              '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                        }
                      }

                      String infoTanggal = tglTransaksi.isNotEmpty
                          ? 'Tgl Update: $tglTransaksi'
                          : labelTanggalEdit;

                      if (infoTanggal.isNotEmpty) {
                        infoSekunder = infoTanggal;
                      } else if (data['lokasi'] != null &&
                          data['lokasi'].toString().isNotEmpty) {
                        infoSekunder = 'Lokasi: ${data['lokasi']}';
                      } else {
                        infoSekunder =
                            'Keterangan: ${data['keterangan'] ?? '-'}';
                      }

                      isWarning =
                          (rawJml.toString() == '0' ||
                          (data['kondisi']?.toString().toLowerCase().contains(
                                'habis',
                              ) ??
                              false));

                      // ==========================================
                      // KATEGORI LAIN
                      // ==========================================
                    } else {
                      judulUtama =
                          data['nama_barang'] ??
                          data['nama'] ??
                          data['nama_alat'] ??
                          'Barang Tanpa Nama';

                      dynamic rawJml =
                          data['jumlah'] ?? data['stok'] ?? data['qty'];
                      infoHighlight = rawJml != null
                          ? 'Jml: $rawJml'
                          : (data['kondisi']?.toString() ?? 'Aktif');

                      infoSekunder = labelTanggalEdit.isNotEmpty
                          ? labelTanggalEdit
                          : '${data['lokasi'] ?? '-'}';
                      isWarning = false;
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade200,
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.broken_image,
                                          color: Colors.grey.shade400,
                                        ),
                                  )
                                : Icon(
                                    kategoriData.contains('APAR')
                                        ? Icons.fire_extinguisher
                                        : kategoriData.contains('P3K')
                                        ? Icons.medical_services
                                        : kategoriData.contains('APD')
                                        ? Icons.health_and_safety
                                        : kategoriData.contains('ATK')
                                        ? Icons.edit_note
                                        : Icons.inventory_2,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        title: Text(
                          judulUtama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isWarning
                                      ? Colors.red.shade50
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  infoHighlight,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isWarning
                                        ? Colors.red.shade700
                                        : Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  infoSekunder,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isWarning
                                        ? Colors.red
                                        : Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailBarangScreen(
                                dataBarang: data,
                                documentId: docId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahBarangScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
