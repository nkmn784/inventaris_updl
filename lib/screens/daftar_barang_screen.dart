import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as exc;
import 'package:file_saver/file_saver.dart';
import '../services/firestore_service.dart';
import 'tambah_barang_screen.dart';
import 'detail_barang_screen.dart';

class DaftarBarangScreen extends StatefulWidget {
  final String namaKategori;

  const DaftarBarangScreen({super.key, required this.namaKategori});

  // ==============================================================
  // FUNGSI STATIC EXPORT EXCEL (Dipanggil dari History Laporan)
  // ==============================================================
  static String _namaBulan(int bulan) {
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

  static Future<void> unduhLaporanExcel(
    BuildContext context,
    String namaKategori,
  ) async {
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
              Text('Menyiapkan laporan $namaKategori...'),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection(namaKategori)
          .get();

      if (snapshot.docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
        );
        return;
      }

      var excel = exc.Excel.createExcel();
      String sheetName = namaKategori;
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      String kategoriUpper = namaKategori.toUpperCase();

      // ==============================================================
      // GAYA TABEL (WARNA ABU-ABU & GARIS PEMBATAS)
      // ==============================================================
      exc.CellStyle headerStyle = exc.CellStyle(
        bold: true,
        horizontalAlign: exc.HorizontalAlign.Center,
        verticalAlign: exc.VerticalAlign.Center,
        backgroundColorHex: exc.ExcelColor.fromHexString(
          '#D3D3D3',
        ), // Warna Abu-abu
        leftBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
        rightBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
        topBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
        bottomBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
      );

      exc.CellStyle dataCenterStyle = exc.CellStyle(
        horizontalAlign: exc.HorizontalAlign.Center,
        verticalAlign: exc.VerticalAlign.Center,
        leftBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
        rightBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
        topBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
        bottomBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
      );

      exc.CellStyle dataLeftStyle = exc.CellStyle(
        horizontalAlign: exc.HorizontalAlign.Left,
        verticalAlign: exc.VerticalAlign.Center,
        leftBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
        rightBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
        topBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
        bottomBorder: exc.Border(borderStyle: exc.BorderStyle.Thin),
      );

      DateTime now = DateTime.now();
      String bulanTahun = '${_namaBulan(now.month).toUpperCase()} ${now.year}';

      // ==============================================================
      // EXCEL APD
      // ==============================================================
      if (kategoriUpper.contains('APD')) {
        excel.rename(defaultSheet, sheetName);
        exc.Sheet sheetObject = excel[sheetName];

        sheetObject.merge(
          exc.CellIndex.indexByString('A1'),
          exc.CellIndex.indexByString('G1'),
          customValue: exc.TextCellValue('INVENTARIS PERALATAN K3 (APD)'),
        );
        sheetObject
            .cell(exc.CellIndex.indexByString('A1'))
            .cellStyle = exc.CellStyle(
          bold: true,
          horizontalAlign: exc.HorizontalAlign.Center,
        );

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
            exc.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
          );
          cell.value = exc.TextCellValue(headersAPD[i]);
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
              exc.CellIndex.indexByColumnRow(
                columnIndex: i,
                rowIndex: rowIndex,
              ),
            );
            cell.value = exc.TextCellValue(rowData[i]);

            if (i == 1) {
              cell.cellStyle = dataLeftStyle;
            } else {
              cell.cellStyle = dataCenterStyle;
            }
          }
          rowIndex++;
          nomorUrut++;
        }

        // Tanda Tangan
        rowIndex += 2;
        String tanggalTTD = '${now.day} ${_namaBulan(now.month)} ${now.year}';
        sheetObject.merge(
          exc.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          exc.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
          customValue: exc.TextCellValue(tanggalTTD),
        );
        sheetObject
            .cell(
              exc.CellIndex.indexByColumnRow(
                columnIndex: 5,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = exc.CellStyle(
          horizontalAlign: exc.HorizontalAlign.Center,
        );

        rowIndex++;
        sheetObject.merge(
          exc.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          exc.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
          customValue: exc.TextCellValue('TL K3L & KAM'),
        );
        sheetObject
            .cell(
              exc.CellIndex.indexByColumnRow(
                columnIndex: 5,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = exc.CellStyle(
          horizontalAlign: exc.HorizontalAlign.Center,
        );

        rowIndex += 4;
        sheetObject.merge(
          exc.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
          exc.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
          customValue: exc.TextCellValue('ANUGRA PUTRA PERMANA'),
        );
        sheetObject
            .cell(
              exc.CellIndex.indexByColumnRow(
                columnIndex: 5,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = exc.CellStyle(
          horizontalAlign: exc.HorizontalAlign.Center,
          bold: true,
        );

        // ==============================================================
        // EXCEL ATK & AMENITIES (SATU SEL / MERGE RAPI)
        // ==============================================================
      } else if (kategoriUpper.contains('ATK') ||
          kategoriUpper.contains('AMENITIES')) {
        bool isFirst = true;

        for (var doc in snapshot.docs) {
          final data = doc.data();
          String rawName =
              data['nama_barang'] ??
              data['nama_atk'] ??
              data['nama'] ??
              'Tanpa Nama';

          String cleanSheetName = rawName
              .replaceAll(RegExp(r'[\\/?*\[\]:]'), '')
              .trim();
          if (cleanSheetName.length > 31)
            cleanSheetName = cleanSheetName.substring(0, 31);
          if (cleanSheetName.isEmpty)
            cleanSheetName = 'Item ${doc.id.substring(0, 4)}';

          int suffix = 1;
          String finalSheetName = cleanSheetName;
          while (excel.tables.containsKey(finalSheetName) &&
              (!isFirst || defaultSheet != finalSheetName)) {
            finalSheetName =
                '${cleanSheetName.substring(0, cleanSheetName.length > 28 ? 28 : cleanSheetName.length)}_$suffix';
            suffix++;
          }

          if (isFirst) {
            excel.rename(defaultSheet, finalSheetName);
            isFirst = false;
          }

          exc.Sheet sheetObject = excel[finalSheetName];

          exc.CellStyle boldTitleStyle = exc.CellStyle(bold: true);

          // Kop Surat
          sheetObject.cell(exc.CellIndex.indexByString('A1')).value =
              exc.TextCellValue('PT PLN (PERSERO)');
          sheetObject.cell(exc.CellIndex.indexByString('A1')).cellStyle =
              boldTitleStyle;
          sheetObject.cell(exc.CellIndex.indexByString('A2')).value =
              exc.TextCellValue('MONITORING STOK BARANG');
          sheetObject.cell(exc.CellIndex.indexByString('A2')).cellStyle =
              boldTitleStyle;

          // Merge A4 sampai C4 untuk Nama Barang (Menjadi satu kesatuan sel)
          sheetObject.merge(
            exc.CellIndex.indexByString('A4'),
            exc.CellIndex.indexByString('C4'),
          );
          sheetObject.cell(exc.CellIndex.indexByString('A4')).value =
              exc.TextCellValue('Nama Barang : $rawName');
          sheetObject.cell(exc.CellIndex.indexByString('A4')).cellStyle =
              boldTitleStyle;

          // Merge D4 sampai E4 untuk Satuan (Menjadi satu kesatuan sel)
          String satuan = data['satuan'] ?? '-';
          sheetObject.merge(
            exc.CellIndex.indexByString('D4'),
            exc.CellIndex.indexByString('E4'),
          );
          sheetObject.cell(exc.CellIndex.indexByString('D4')).value =
              exc.TextCellValue('Satuan : $satuan');
          sheetObject.cell(exc.CellIndex.indexByString('D4')).cellStyle =
              boldTitleStyle;

          // Table Headers (5 Kolom Rapat)
          List<String> atkHeaders = [
            'Tgl.',
            'Masuk',
            'Keluar',
            'Sisa Persediaan',
            'Catatan',
          ];
          for (int i = 0; i < atkHeaders.length; i++) {
            var cell = sheetObject.cell(
              exc.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 6),
            );
            cell.value = exc.TextCellValue(atkHeaders[i]);
            cell.cellStyle = headerStyle;
          }

          List<dynamic> riwayat = [];
          if (kategoriUpper.contains('ATK')) {
            riwayat = data['riwayat_stok_atk'] ?? [];
          } else {
            riwayat = data['riwayat_stok_amenities'] ?? [];
          }

          int rIdx = 7;

          String formatTgl(String? isoDate) {
            if (isoDate == null || isoDate.isEmpty) return '-';
            try {
              DateTime dt = DateTime.parse(isoDate);
              return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
            } catch (_) {
              return isoDate;
            }
          }

          if (riwayat.isEmpty) {
            sheetObject
                .cell(
                  exc.CellIndex.indexByColumnRow(
                    columnIndex: 0,
                    rowIndex: rIdx,
                  ),
                )
                .value = exc.TextCellValue(
              formatTgl(data['tanggal_transaksi'] ?? data['updated_at']),
            );
            sheetObject
                .cell(
                  exc.CellIndex.indexByColumnRow(
                    columnIndex: 1,
                    rowIndex: rIdx,
                  ),
                )
                .value = exc.TextCellValue(
              data['masuk']?.toString() ?? '-',
            );
            sheetObject
                .cell(
                  exc.CellIndex.indexByColumnRow(
                    columnIndex: 2,
                    rowIndex: rIdx,
                  ),
                )
                .value = exc.TextCellValue(
              data['keluar']?.toString() ?? '-',
            );

            String sisa =
                data['sisa_jumlah']?.toString() ??
                data['jumlah']?.toString() ??
                '0';
            sheetObject
                .cell(
                  exc.CellIndex.indexByColumnRow(
                    columnIndex: 3,
                    rowIndex: rIdx,
                  ),
                )
                .value = exc.TextCellValue(
              sisa,
            );
            sheetObject
                .cell(
                  exc.CellIndex.indexByColumnRow(
                    columnIndex: 4,
                    rowIndex: rIdx,
                  ),
                )
                .value = exc.TextCellValue(
              data['keterangan'] ?? 'Stok Awal',
            );

            for (int c = 0; c <= 4; c++) {
              sheetObject
                  .cell(
                    exc.CellIndex.indexByColumnRow(
                      columnIndex: c,
                      rowIndex: rIdx,
                    ),
                  )
                  .cellStyle = (c == 4)
                  ? dataLeftStyle
                  : dataCenterStyle;
            }
            rIdx++;
          } else {
            for (var history in riwayat) {
              String tgl = formatTgl(history['tanggal'] ?? history['tgl']);
              String masuk = history['masuk']?.toString() ?? '-';
              if (masuk == '0') masuk = '-';
              String keluar = history['keluar']?.toString() ?? '-';
              if (keluar == '0') keluar = '-';

              String sisa =
                  history['jumlah_baru']?.toString() ??
                  history['sisa']?.toString() ??
                  history['jumlah']?.toString() ??
                  '0';
              String catatan =
                  history['catatan'] ?? history['keterangan'] ?? '-';

              sheetObject
                  .cell(
                    exc.CellIndex.indexByColumnRow(
                      columnIndex: 0,
                      rowIndex: rIdx,
                    ),
                  )
                  .value = exc.TextCellValue(
                tgl,
              );
              sheetObject
                  .cell(
                    exc.CellIndex.indexByColumnRow(
                      columnIndex: 1,
                      rowIndex: rIdx,
                    ),
                  )
                  .value = exc.TextCellValue(
                masuk,
              );
              sheetObject
                  .cell(
                    exc.CellIndex.indexByColumnRow(
                      columnIndex: 2,
                      rowIndex: rIdx,
                    ),
                  )
                  .value = exc.TextCellValue(
                keluar,
              );
              sheetObject
                  .cell(
                    exc.CellIndex.indexByColumnRow(
                      columnIndex: 3,
                      rowIndex: rIdx,
                    ),
                  )
                  .value = exc.TextCellValue(
                sisa,
              );
              sheetObject
                  .cell(
                    exc.CellIndex.indexByColumnRow(
                      columnIndex: 4,
                      rowIndex: rIdx,
                    ),
                  )
                  .value = exc.TextCellValue(
                catatan,
              );

              for (int c = 0; c <= 4; c++) {
                sheetObject
                    .cell(
                      exc.CellIndex.indexByColumnRow(
                        columnIndex: c,
                        rowIndex: rIdx,
                      ),
                    )
                    .cellStyle = (c == 4)
                    ? dataLeftStyle
                    : dataCenterStyle;
              }
              rIdx++;
            }
          }
        }

        // ==============================================================
        // KATEGORI LAINNYA
        // ==============================================================
      } else {
        excel.rename(defaultSheet, sheetName);
        exc.Sheet sheetObject = excel[sheetName];

        sheetObject.merge(
          exc.CellIndex.indexByString('A1'),
          exc.CellIndex.indexByString('F1'),
          customValue: exc.TextCellValue(
            'LAPORAN DATA ${namaKategori.toUpperCase()}',
          ),
        );
        sheetObject
            .cell(exc.CellIndex.indexByString('A1'))
            .cellStyle = exc.CellStyle(
          bold: true,
          horizontalAlign: exc.HorizontalAlign.Center,
        );

        sheetObject.cell(exc.CellIndex.indexByString('A2')).value =
            exc.TextCellValue('BULAN / TAHUN : $bulanTahun');

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
            exc.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3),
          );
          cell.value = exc.TextCellValue(headersLain[i]);
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
            var cell = sheetObject.cell(
              exc.CellIndex.indexByColumnRow(
                columnIndex: i,
                rowIndex: rowIndex,
              ),
            );
            cell.value = exc.TextCellValue(rowData[i]);
            if (i == 1 || i == 3) {
              cell.cellStyle = dataLeftStyle;
            } else {
              cell.cellStyle = dataCenterStyle;
            }
          }
          rowIndex++;
          nomorUrut++;
        }
      }

      var fileBytes = excel.encode();
      if (fileBytes == null) throw Exception("Gagal membuat file Excel");

      final String namaFile =
          'Laporan_${namaKategori}_${DateTime.now().millisecondsSinceEpoch}';

      await FileSaver.instance.saveFile(
        name: '$namaFile.xlsx',
        bytes: Uint8List.fromList(fileBytes),
        mimeType: MimeType.microsoftExcel,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan $namaKategori berhasil diunduh!'),
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
  State<DaftarBarangScreen> createState() => _DaftarBarangScreenState();
}

class _DaftarBarangScreenState extends State<DaftarBarangScreen> {
  String _searchQuery = '';

  // ✔️ 1. Deklarasikan variabel stream
  late Stream<QuerySnapshot> _barangStream;

  // ✔️ 2. Inisialisasi stream di dalam initState agar hanya dipanggil 1 kali
  @override
  void initState() {
    super.initState();
    _barangStream = FirestoreService().getBarangByKategori(widget.namaKategori);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: Text(
          widget.namaKategori,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 30.0,
              top: 16.0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade600],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(76),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari ${widget.namaKategori.toLowerCase()}...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _barangStream,
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
                  if (kategoriData.contains('APD')) {
                    searchString =
                        '${data['peralatan'] ?? data['nama_apd'] ?? data['nama_barang'] ?? ''} ${data['kondisi'] ?? ''} ${data['pembelian'] ?? ''}';
                  } else if (kategoriData.contains('ATK') ||
                      kategoriData.contains('AMENITIES')) {
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
                    String statusBadge = 'TERSEDIA';
                    String? imageUrl = data['foto_url'] ?? data['image_url'];

                    String tglEdit = _formatTanggalEdit(data);
                    String labelTanggalEdit = tglEdit.isNotEmpty
                        ? 'Diubah: $tglEdit'
                        : '';

                    if (kategoriData.contains('APD')) {
                      judulUtama =
                          data['peralatan'] ??
                          data['nama_apd'] ??
                          data['nama_barang'] ??
                          'APD Tanpa Nama';
                      dynamic rawJml =
                          data['jumlah'] ?? data['stok'] ?? data['qty'] ?? 0;
                      infoHighlight = 'Jml: $rawJml';

                      statusBadge = (data['kondisi'] ?? 'BAIK')
                          .toString()
                          .toUpperCase();
                      isWarning =
                          statusBadge.contains('RUSAK') ||
                          rawJml.toString() == '0';

                      if (labelTanggalEdit.isNotEmpty) {
                        infoSekunder = labelTanggalEdit;
                      } else if (data['pembelian'] != null &&
                          data['pembelian'].toString().isNotEmpty) {
                        infoSekunder = 'Pembelian: ${data['pembelian']}';
                      } else {
                        infoSekunder =
                            'Masa Pakai: ${data['masa_pakai'] ?? '-'}';
                      }
                    } else if (kategoriData.contains('ATK') ||
                        kategoriData.contains('AMENITIES')) {
                      judulUtama =
                          data['nama_barang'] ??
                          data['nama_atk'] ??
                          data['nama'] ??
                          'Tanpa Nama';
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

                      if (rawJml.toString() == '0' ||
                          (data['kondisi']?.toString().toUpperCase().contains(
                                'HABIS',
                              ) ??
                              false)) {
                        statusBadge = 'HABIS';
                        isWarning = true;
                      } else {
                        statusBadge = (data['kondisi'] ?? 'TERSEDIA')
                            .toString()
                            .toUpperCase();
                        isWarning = false;
                      }

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
                      statusBadge = (data['kondisi'] ?? 'TERSEDIA')
                          .toString()
                          .toUpperCase();
                      isWarning = false;
                    }

                    Color leftBorderColor = isWarning
                        ? Colors.red.shade700
                        : Colors.blue.shade700;
                    Color badge1Color = isWarning
                        ? Colors.red.shade700
                        : Colors.blue.shade700;
                    Color badge2Color = isWarning
                        ? Colors.red.shade700
                        : Colors.green.shade700;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100.withAlpha(128),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: leftBorderColor,
                                width: 5,
                              ),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
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
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            imageUrl != null &&
                                                imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.broken_image,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                              )
                                            : Icon(
                                                kategoriData.contains('APD')
                                                    ? Icons.health_and_safety
                                                    : kategoriData.contains(
                                                        'ATK',
                                                      )
                                                    ? Icons.edit_note
                                                    : kategoriData.contains(
                                                        'AMENITIES',
                                                      )
                                                    ? Icons.spa
                                                    : Icons.inventory_2,
                                                color: Colors.blue.shade700,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            judulUtama,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.blue.shade900,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            infoSekunder,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badge1Color.withAlpha(25),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            infoHighlight.toUpperCase(),
                                            style: TextStyle(
                                              color: badge1Color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badge2Color.withAlpha(25),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            statusBadge,
                                            style: TextStyle(
                                              color: badge2Color,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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
        backgroundColor: Colors.blue.shade800,
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
