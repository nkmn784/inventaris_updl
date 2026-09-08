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

  // Helper untuk nama bulan Indonesia
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

  // Helper untuk mengambil status item P3K dari Map / Doc
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
              .replaceAll('_', ' ')
              .replaceAll('-', ' ')
              .trim();
          String cleanAlias = alias
              .toLowerCase()
              .replaceAll('_', ' ')
              .replaceAll('-', ' ')
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
  // FUNGSI LANGSUNG UNDUH LAPORAN EXCEL
  // ==========================================
  Future<void> _unduhLaporanExcel() async {
    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Menyiapkan & mengunduh laporan ${widget.namaKategori}...',
          ),
          duration: const Duration(seconds: 2),
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
        return;
      }

      var excel = Excel.createExcel();
      String sheetName = widget.namaKategori;
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheet, sheetName);
      Sheet sheetObject = excel[sheetName];

      DateTime now = DateTime.now();
      String bulanTahun = '${_namaBulan(now.month).toUpperCase()} ${now.year}';
      String tanggalHariIni =
          '${now.day.toString().padLeft(2, '0')} ${_namaBulan(now.month)} ${now.year}';

      if (widget.namaKategori == 'APAR') {
        sheetObject.cell(CellIndex.indexByString('C1')).value = TextCellValue(
          'ALAT PEMADAM API RINGAN (APAR)',
        );
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
          sheetObject
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 6))
              .value = TextCellValue(
            headers[i],
          );
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
      } else if (widget.namaKategori == 'P3K') {
        sheetObject.cell(CellIndex.indexByString('B1')).value = TextCellValue(
          'IDENTIFIKASI KEBUTUHAN KOTAK P3K',
        );
        sheetObject.cell(CellIndex.indexByString('B2')).value = TextCellValue(
          'DI PT PLN (PERSERO) UPDL PANDAAN',
        );
        sheetObject.cell(CellIndex.indexByString('B3')).value = TextCellValue(
          'BULAN $bulanTahun',
        );

        sheetObject.cell(CellIndex.indexByString('E1')).value = TextCellValue(
          'A : 25 orang',
        );
        sheetObject.cell(CellIndex.indexByString('E2')).value = TextCellValue(
          'B : 50 orang',
        );
        sheetObject.cell(CellIndex.indexByString('E3')).value = TextCellValue(
          'C : 100 orang',
        );

        // Header disatukan seluruhnya dalam 1 baris (rowIndex: 4)
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
          sheetObject
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4))
              .value = TextCellValue(
            headersP3K[i],
          );
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

        int rowIndex = 5; // Baris data dimulai tepat pada rowIndex 5
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
            String itemVal = _getItemValue(data, checklistMap, itemAliases[i]);
            rowData.add(itemVal);
          }

          String kekurangan =
              data['kekurangan']?.toString() ??
              data['keterangan']?.toString() ??
              '-';
          rowData.add(kekurangan);
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
      }

      var fileBytes = excel.encode();
      if (fileBytes == null) throw Exception("Gagal membuat file Excel");

      final Uint8List uint8List = Uint8List.fromList(fileBytes);
      final String namaFile =
          'Laporan_${widget.namaKategori}_${DateTime.now().millisecondsSinceEpoch}';

      await FileSaver.instance.saveFile(
        name: '$namaFile.xlsx',
        bytes: uint8List,
        mimeType: MimeType.microsoftExcel,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Laporan ${widget.namaKategori} berhasil diunduh ke perangkat!',
          ),
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
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.blue),
            tooltip: 'Unduh Laporan Excel',
            onPressed: () => _unduhLaporanExcel(),
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
                hintText:
                    'Cari ${widget.namaKategori.toLowerCase()} / koordinat...',
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
                        Text('Belum ada data ${widget.namaKategori}'),
                      ],
                    ),
                  );
                }

                final dokumen = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final kategoriData = data['kategori'] ?? widget.namaKategori;

                  String searchString = '';
                  if (kategoriData == 'APAR') {
                    searchString =
                        '${data['nama_alat']} ${data['no_apar']} ${data['lokasi']} ${data['latitude']} ${data['longitude']}';
                  } else if (kategoriData == 'P3K') {
                    searchString =
                        '${data['gedung_ruang']} ${data['lokasi']} ${data['latitude']} ${data['longitude']}';
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
                        data['kategori'] ?? widget.namaKategori;

                    String judulUtama = '';
                    String infoHighlight = '';
                    String infoSekunder = '';
                    bool isWarning = false;
                    String? imageUrl = data['foto_url'];

                    String lat = data['latitude']?.toString() ?? '';
                    String lng = data['longitude']?.toString() ?? '';
                    String infoKoordinat = (lat.isNotEmpty && lng.isNotEmpty)
                        ? ' 📍 ($lat, $lng)'
                        : '';

                    if (kategoriData == 'APAR') {
                      judulUtama =
                          data['nama_alat'] != null &&
                              data['nama_alat'].toString().isNotEmpty
                          ? data['nama_alat']
                          : 'APAR No. ${data['no_apar'] ?? '-'}';
                      infoHighlight = '${data['berat'] ?? '-'} Kg';
                      infoSekunder = '${data['lokasi'] ?? '-'}$infoKoordinat';

                      bool tekananAman = data['checklist_tekanan'] ?? true;
                      bool pinAman = data['checklist_safety_pin'] ?? true;
                      isWarning = (!tekananAman || !pinAman);
                    } else if (kategoriData == 'P3K') {
                      judulUtama =
                          data['gedung_ruang'] ??
                          data['lokasi'] ??
                          'Tanpa Nama Ruangan';
                      infoHighlight = '${data['kapasitas'] ?? 0} Org';
                      infoSekunder =
                          'Ext: ${data['existing'] ?? '-'}$infoKoordinat';
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
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            image: imageUrl != null && imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageUrl == null || imageUrl.isEmpty
                              ? Icon(
                                  kategoriData == 'APAR'
                                      ? Icons.fire_extinguisher
                                      : Icons.medical_services,
                                  color: Colors.grey,
                                )
                              : null,
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
