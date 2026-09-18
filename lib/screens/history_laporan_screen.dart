import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class HistoryLaporanScreen extends StatefulWidget {
  const HistoryLaporanScreen({super.key});

  @override
  State<HistoryLaporanScreen> createState() => _HistoryLaporanScreenState();
}

class _HistoryLaporanScreenState extends State<HistoryLaporanScreen> {
  bool _isExporting = false;

  // ==========================================
  // FUNGSI MEMBUKA DIALOG FILTER EXCEL
  // ==========================================
  void _showExportDialog(List<QueryDocumentSnapshot> allDocs) {
    String selectedKategori = 'APAR';
    int selectedBulan = DateTime.now().month;
    int selectedTahun = DateTime.now().year;

    final List<String> listKategori = [
      'APAR',
      'Kotak P3K',
      'ATK',
      'APD',
      'Amenities',
      'Penerangan',
    ];

    final List<Map<String, dynamic>> listBulan = [
      {'id': 0, 'nama': 'Semua Bulan'},
      {'id': 1, 'nama': 'Januari'},
      {'id': 2, 'nama': 'Februari'},
      {'id': 3, 'nama': 'Maret'},
      {'id': 4, 'nama': 'April'},
      {'id': 5, 'nama': 'Mei'},
      {'id': 6, 'nama': 'Juni'},
      {'id': 7, 'nama': 'Juli'},
      {'id': 8, 'nama': 'Agustus'},
      {'id': 9, 'nama': 'September'},
      {'id': 10, 'nama': 'Oktober'},
      {'id': 11, 'nama': 'November'},
      {'id': 12, 'nama': 'Desember'},
    ];

    List<int> listTahun = [0, 2024, 2025, 2026, 2027, 2028, 2029, 2030];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Download Laporan (Terbaru)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F3460),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jenis Alat / Kategori',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    value: selectedKategori,
                    items: listKategori
                        .map(
                          (val) =>
                              DropdownMenuItem(value: val, child: Text(val)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedKategori = val!),
                  ),
                  const SizedBox(height: 15),

                  if (selectedKategori != 'Penerangan') ...[
                    const Text(
                      'Bulan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      value: selectedBulan,
                      items: listBulan
                          .map(
                            (val) => DropdownMenuItem<int>(
                              value: val['id'],
                              child: Text(val['nama']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedBulan = val!),
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      'Tahun',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      value: selectedTahun,
                      items: listTahun
                          .map(
                            (val) => DropdownMenuItem<int>(
                              value: val,
                              child: Text(
                                val == 0 ? 'Semua Tahun' : val.toString(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedTahun = val!),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);

                    if (selectedKategori == 'Penerangan') {
                      _exportPeneranganDirect();
                      return;
                    }

                    // 1. Filter awal berdasarkan Kategori & Waktu (KODINGAN LAMA - JANGAN DIHAPUS)
                    List<QueryDocumentSnapshot> filteredDocs = allDocs.where((
                      doc,
                    ) {
                      var data = doc.data() as Map<String, dynamic>;
                      String namaBarang = (data['nama_barang'] ?? '')
                          .toLowerCase();
                      String kategoriDoc = (data['kategori'] ?? '')
                          .toLowerCase();

                      DateTime? tgl;
                      if (data['tanggal'] != null) {
                        tgl = (data['tanggal'] as Timestamp).toDate();
                      }

                      String keyword = selectedKategori.toLowerCase();
                      if (selectedKategori == 'Kotak P3K') keyword = 'p3k';

                      bool matchKat =
                          namaBarang.contains(keyword) ||
                          kategoriDoc.contains(keyword);

                      bool matchBul = true;
                      if (selectedBulan != 0 && tgl != null) {
                        matchBul = tgl.month == selectedBulan;
                      }

                      bool matchTah = true;
                      if (selectedTahun != 0 && tgl != null) {
                        matchTah = tgl.year == selectedTahun;
                      }

                      return matchKat && matchBul && matchTah;
                    }).toList();

                    // 2. LOGIKA HANYA AMBIL INSPEKSI TERBARU PER UNIT (KODINGAN LAMA)
                    Map<String, QueryDocumentSnapshot> latestDocsMap = {};
                    for (var doc in filteredDocs) {
                      var data = doc.data() as Map<String, dynamic>;

                      String identifier =
                          data['docIdBarang']?.toString() ??
                          data['id_barang']?.toString() ??
                          data['nama_barang']?.toString() ??
                          doc.id;

                      DateTime? currentTgl;
                      if (data['tanggal'] != null) {
                        currentTgl = (data['tanggal'] as Timestamp).toDate();
                      }

                      if (!latestDocsMap.containsKey(identifier)) {
                        latestDocsMap[identifier] = doc;
                      } else {
                        var existingData =
                            latestDocsMap[identifier]!.data()
                                as Map<String, dynamic>;
                        DateTime? existingTgl;
                        if (existingData['tanggal'] != null) {
                          existingTgl = (existingData['tanggal'] as Timestamp)
                              .toDate();
                        }

                        if (currentTgl != null &&
                            (existingTgl == null ||
                                currentTgl.isAfter(existingTgl))) {
                          latestDocsMap[identifier] = doc;
                        }
                      }
                    }

                    List<QueryDocumentSnapshot> finalUniqueDocs = latestDocsMap
                        .values
                        .toList();

                    // Khusus P3K, datanya tetap dieksport walau hasil riwayat di bulan tsb kosong
                    // (karena rekap master), tapi untuk kategori lain butuh data riwayat.
                    if (finalUniqueDocs.isEmpty &&
                        selectedKategori != 'Kotak P3K') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Data tidak ditemukan pada periode/kategori ini.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    _exportToExcel(
                      finalUniqueDocs,
                      selectedKategori,
                      bulan: selectedBulan,
                      tahun: selectedTahun,
                    );
                  },
                  child: const Text(
                    'Buat Excel',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // FUNGSI AMBIL DATA PENERANGAN LANGSUNG
  // ==========================================
  Future<void> _exportPeneranganDirect() async {
    setState(() => _isExporting = true);
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Penerangan')
          .get();
      List<QueryDocumentSnapshot> docs = snapshot.docs;

      if (docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Belum ada data titik penerangan sama sekali.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isExporting = false);
        return;
      }

      _exportToExcel(docs, 'Penerangan');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isExporting = false);
    }
  }

  // ==========================================
  // FUNGSI MEMBUAT FILE EXCEL (GABUNGAN KODINGAN LAMA & P3K BARU)
  // ==========================================
  Future<void> _exportToExcel(
    List<QueryDocumentSnapshot> docs,
    String kategori, {
    int bulan = 0,
    int tahun = 0,
  }) async {
    setState(() => _isExporting = true);

    try {
      // 3. AMBIL DATA MASTER UNTUK MENGISI KOLOM KOSONG
      Map<String, Map<String, dynamic>> masterData = {};
      if (kategori != 'Penerangan') {
        try {
          QuerySnapshot masterSnap = await FirebaseFirestore.instance
              .collection(kategori)
              .get();
          for (var mDoc in masterSnap.docs) {
            masterData[mDoc.id] = mDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('Gagal mengambil data master: $e');
        }
      }

      var excel = Excel.createExcel();
      String sheetName = kategori == 'Kotak P3K'
          ? 'TempSheet'
          : 'Laporan $kategori';

      Sheet? sheetObject;
      if (kategori != 'Kotak P3K') {
        sheetObject = excel[sheetName];
        excel.setDefaultSheet(sheetName);
      } else {
        excel.rename(excel.getDefaultSheet()!, 'TempSheet');
      }

      CellStyle titleStyle = CellStyle(bold: true, fontSize: 13);
      CellStyle headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D3D3D3'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
      );

      String tanggalUnduhStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

      // LOGIKA MEMBENTUK TEKS PERIODE BULAN & TAHUN
      List<String> namaBulan = [
        '',
        'JANUARI',
        'FEBRUARI',
        'MARET',
        'APRIL',
        'MEI',
        'JUNI',
        'JULI',
        'AGUSTUS',
        'SEPTEMBER',
        'OKTOBER',
        'NOVEMBER',
        'DESEMBER',
      ];
      String periodeText = '';
      if (bulan != 0 && tahun != 0) {
        periodeText = 'BULAN ${namaBulan[bulan]} $tahun';
      } else if (bulan != 0) {
        periodeText = 'BULAN ${namaBulan[bulan]}';
      } else if (tahun != 0) {
        periodeText = 'TAHUN $tahun';
      } else {
        periodeText = 'KESELURUHAN DATA';
      }
      if (kategori == 'Kotak P3K') {
        // --- SHEET 1: HASIL INSPEKSI ---
        Sheet sheet1 = excel['Hasil Inspeksi'];
        excel.setDefaultSheet('Hasil Inspeksi');

        sheet1.cell(CellIndex.indexByString("A1")).value = TextCellValue(
          'IDENTIFIKASI KEBUTUHAN KOTAK P3K',
        );
        sheet1.cell(CellIndex.indexByString("A1")).cellStyle = titleStyle;
        sheet1.cell(CellIndex.indexByString("A2")).value = TextCellValue(
          'DI PT PLN (PERSERO) UPDL PANDAAN',
        );
        sheet1.cell(CellIndex.indexByString("A2")).cellStyle = titleStyle;
        sheet1.cell(CellIndex.indexByString("A3")).value = TextCellValue(
          periodeText,
        );
        sheet1.cell(CellIndex.indexByString("A3")).cellStyle = titleStyle;

        // --- TAMBAHAN TANGGAL UNDUH DI SHEET 1 ---
        sheet1.cell(CellIndex.indexByString("A4")).value = TextCellValue(
          'Tanggal Unduh',
        );
        sheet1.cell(CellIndex.indexByString("B4")).value = TextCellValue(
          ': $tanggalUnduhStr',
        );

        List<String> p3kHeaders = [
          'No',
          'No Kotak P3K',
          'Gedung/Ruang',
          'Kapasitas',
          'Existing',
          'Rekomendasi',
          'Koordinat GPS',
          'Kasa Steril',
          'Perban (5cm)',
          'Perban (10cm)',
          'Plester 1.25cm',
          'Plester Cepat',
          'Kapas 25gr',
          'Mitela',
          'Gunting',
          'Peniti',
          'Sarung Tangan 1x',
          'Sarung Tangan Pasang',
          'Masker',
          'Pinset',
          'Senter',
          'Gelas Cuci Mata',
          'Plastik Bersih',
          'Aquades',
          'Povidone Iodine',
          'Alkohol 70%',
          'Buku Panduan',
          'Buku Catatan',
          'Keterangan',
        ];

        // Pergeseran Baris Header (Dari rowIndex: 5 menjadi rowIndex: 6 karena ada tanggal unduh di baris 4)
        for (int i = 0; i < p3kHeaders.length; i++) {
          var cell = sheet1.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 6),
          );
          cell.value = TextCellValue(p3kHeaders[i]);
          cell.cellStyle = headerStyle;
        }

        int rIdx = 7; // Mulai data dari baris ke-7
        int no = 1;
        List<String> list21Items = [
          'Kasa Steril',
          'Perban (Lebar 5 cm)',
          'Perban (Lebar 10 cm)',
          'Plester Lebar 1,25 cm',
          'Plester Cepat',
          'Kapas 25 gr',
          'Kain Segi Tiga (Mitela)',
          'Gunting',
          'Peniti',
          'Sarung Tangan Sekali Pakai',
          'Sarung Tangan (Pasangan)',
          'Masker',
          'Pinset',
          'Lampu Senter',
          'Gelas Cuci Mata',
          'Kantong Plastik Bersih',
          'Aquades',
          'Povidone Iodine',
          'Alkohol 70%',
          'Buku Panduan P3K',
          'Buku Catatan & Daftar Isi',
        ];

        final Map<String, List<int>> standarP3KMap = {
          'Kasa Steril': [20, 40, 40],
          'Perban (Lebar 5 cm)': [2, 4, 6],
          'Perban (Lebar 10 cm)': [2, 4, 6],
          'Plester Lebar 1,25 cm': [2, 4, 6],
          'Plester Cepat': [10, 15, 20],
          'Kapas 25 gr': [1, 2, 3],
          'Kain Segi Tiga (Mitela)': [2, 4, 6],
          'Gunting': [1, 1, 1],
          'Peniti': [12, 12, 12],
          'Sarung Tangan Sekali Pakai': [2, 3, 4],
          'Sarung Tangan (Pasangan)': [2, 4, 6],
          'Masker': [1, 1, 1],
          'Pinset': [1, 1, 1],
          'Lampu Senter': [1, 1, 1],
          'Gelas Cuci Mata': [1, 2, 3],
          'Kantong Plastik Bersih': [1, 1, 1],
          'Aquades': [1, 1, 1],
          'Povidone Iodine': [1, 1, 1],
          'Alkohol 70%': [1, 1, 1],
          'Buku Panduan P3K': [1, 1, 1],
          'Buku Catatan & Daftar Isi': [1, 1, 1],
        };

        masterData.forEach((docId, mData) {
          var spec = mData['spesifikasi'] ?? {};
          String tipe = spec['Tipe'] ?? 'A';
          int typeIndex = tipe.contains('B') ? 1 : (tipe.contains('C') ? 2 : 0);
          String kapasitas = tipe.contains('B')
              ? '50 orang'
              : (tipe.contains('C') ? '100 orang' : '25 orang');
          String noP3k = spec['No P3K'] ?? '-';
          sheet1
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIdx))
              .value = IntCellValue(
            no++,
          );
          sheet1
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIdx))
              .value = TextCellValue(
            noP3k,
          );
          sheet1
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIdx))
              .value = TextCellValue(
            mData['nama_barang'] ?? '-',
          );
          sheet1
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rIdx))
              .value = TextCellValue(
            kapasitas,
          );
          sheet1
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rIdx))
              .value = TextCellValue(
            tipe,
          );
          sheet1
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rIdx))
              .value = TextCellValue(
            '${tipe}A',
          );
          sheet1
              .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rIdx))
              .value = TextCellValue(
            mData['koordinat'] ?? '-',
          );

          Map<String, dynamic> defisit = Map<String, dynamic>.from(
            mData['defisit_p3k'] ?? {},
          );
          int colOffset = 7;
          for (var itemName in list21Items) {
            int maxStock = standarP3KMap[itemName]![typeIndex];
            int curDef = defisit[itemName] ?? 0;
            int curStock = maxStock - curDef;
            if (curStock < 0) curStock = 0;

            sheet1
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colOffset++,
                    rowIndex: rIdx,
                  ),
                )
                .value = TextCellValue(
              '$curStock / $maxStock',
            );
          }

          // Memasukkan data Keterangan di kolom paling akhir
          String ket =
              mData['keterangan']?.toString() ??
              mData['catatan']?.toString() ??
              '-';
          if (ket.trim().isEmpty) ket = '-';
          sheet1
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colOffset,
                  rowIndex: rIdx,
                ),
              )
              .value = TextCellValue(
            ket,
          );

          rIdx++;
        });

        // --- SHEET 2: BUKU CATATAN ---
        Sheet sheet2 = excel['Buku Catatan'];
        sheet2.cell(CellIndex.indexByString("A1")).value = TextCellValue(
          'RIWAYAT / BUKU CATATAN PENGGUNAAN KOTAK P3K',
        );
        sheet2.cell(CellIndex.indexByString("A1")).cellStyle = titleStyle;
        sheet2.cell(CellIndex.indexByString("A2")).value = TextCellValue(
          'Tanggal Unduh',
        );
        sheet2.cell(CellIndex.indexByString("B2")).value = TextCellValue(
          ': $tanggalUnduhStr',
        );
        List<String> catHeaders = [
          'No',
          'Nama Kotak / Lokasi',
          'Nama Pemakai',
          'Item yang Dipakai',
          'Jumlah',
          'Keperluan / Keluhan',
          'Tanggal & Waktu',
        ];

        // Pergeseran Baris Header Sheet 2 (Dari rowIndex: 3 menjadi rowIndex: 4)
        for (int i = 0; i < catHeaders.length; i++) {
          sheet2
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4))
              .value = TextCellValue(
            catHeaders[i],
          );
          sheet2
                  .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4))
                  .cellStyle =
              headerStyle;
        }

        try {
          QuerySnapshot usageSnap = await FirebaseFirestore.instance
              .collection('buku_catatan_p3k')
              .get();
          int cRow = 5; // Mulai baris data dari baris ke-5
          int cNo = 1;
          for (var uDoc in usageSnap.docs) {
            var uData = uDoc.data() as Map<String, dynamic>;

            // PERBAIKAN TANGGAL & WAKTU YANG SUPER ROBUST
            String tglStr = '-';

            // 1. Coba cari di field-field yang umum
            var rawTgl =
                uData['tanggal'] ??
                uData['waktu'] ??
                uData['created_at'] ??
                uData['createdAt'] ??
                uData['waktu_penggunaan'] ??
                uData['tanggal_penggunaan'] ??
                uData['timestamp'] ??
                uData['tgl'];

            // 2. Jika MASIH KOSONG, cari field apapun di dokumen itu yang bertipe Timestamp (Otomatis)
            if (rawTgl == null) {
              for (var value in uData.values) {
                if (value is Timestamp) {
                  rawTgl = value;
                  break;
                }
              }
            }

            // 3. Format nilai tanggalnya menjadi text
            if (rawTgl != null) {
              if (rawTgl is Timestamp) {
                tglStr = DateFormat('dd/MM/yyyy HH:mm').format(rawTgl.toDate());
              } else if (rawTgl is String) {
                tglStr = rawTgl;
              } else if (rawTgl is int) {
                // Berjaga-jaga jika formatnya angka milliseconds
                tglStr = DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(DateTime.fromMillisecondsSinceEpoch(rawTgl));
              } else {
                tglStr = rawTgl.toString();
              }
            }

            sheet2
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: cRow),
                )
                .value = IntCellValue(
              cNo++,
            );
            sheet2
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: cRow),
                )
                .value = TextCellValue(
              uData['nama_kotak'] ?? '-',
            );
            sheet2
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: cRow),
                )
                .value = TextCellValue(
              uData['nama_pemakai'] ?? '-',
            );
            sheet2
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: cRow),
                )
                .value = TextCellValue(
              uData['item_dipakai'] ?? '-',
            );
            sheet2
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: cRow),
                )
                .value = IntCellValue(
              int.tryParse(uData['jumlah'].toString()) ?? 1,
            );
            sheet2
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: cRow),
                )
                .value = TextCellValue(
              uData['keperluan'] ?? '-',
            );
            sheet2
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: cRow),
                )
                .value = TextCellValue(
              tglStr,
            );
            cRow++;
          }
        } catch (_) {}

        // --- SHEET 3: REKAPITULASI ---
        Sheet sheet3 = excel['Rekapitulasi'];
        sheet3.cell(CellIndex.indexByString("A1")).value = TextCellValue(
          'REKAPITULASI ALAT P3K PALING SERING DIPAKAI BULAN INI',
        );
        sheet3.cell(CellIndex.indexByString("A1")).cellStyle = titleStyle;
        sheet3.cell(CellIndex.indexByString("A2")).value = TextCellValue(
          'Tanggal Unduh',
        );
        sheet3.cell(CellIndex.indexByString("B2")).value = TextCellValue(
          ': $tanggalUnduhStr',
        );
        List<String> rekHeaders = [
          'Peringkat',
          'Nama Alat / Item P3K',
          'Total Penggunaan (Bulan Ini)',
        ];

        // Pergeseran Baris Header Sheet 3 (Dari rowIndex: 3 menjadi rowIndex: 4)
        for (int i = 0; i < rekHeaders.length; i++) {
          sheet3
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4))
              .value = TextCellValue(
            rekHeaders[i],
          );
          sheet3
                  .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4))
                  .cellStyle =
              headerStyle;
        }

        Map<String, int> usageCount = {};
        for (var itemName in list21Items) {
          usageCount[itemName] = 0;
        }

        try {
          QuerySnapshot usageSnap = await FirebaseFirestore.instance
              .collection('buku_catatan_p3k')
              .get();
          for (var uDoc in usageSnap.docs) {
            var uData = uDoc.data() as Map<String, dynamic>;
            String item = uData['item_dipakai'] ?? '';
            int qty = int.tryParse(uData['jumlah'].toString()) ?? 1;
            if (usageCount.containsKey(item)) {
              usageCount[item] = usageCount[item]! + qty;
            }
          }
        } catch (_) {}

        var sortedUsage = usageCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        int rRow = 4;
        int rank = 1;
        for (var entry in sortedUsage) {
          sheet3
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rRow))
              .value = IntCellValue(
            rank++,
          );
          sheet3
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rRow))
              .value = TextCellValue(
            entry.key,
          );
          sheet3
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rRow))
              .value = TextCellValue(
            '${entry.value} Pcs / Botol',
          );
          rRow++;
        }
      }
      // ==========================================================
      // KONDISI 2: PENERANGAN (KODINGAN LAMA)
      // ==========================================================
      else if (kategori == 'Penerangan' && sheetObject != null) {
        sheetObject.cell(CellIndex.indexByString("A1")).value = TextCellValue(
          'REKAPITULASI LAPORAN PENERANGAN',
        );
        sheetObject.cell(CellIndex.indexByString("A1")).cellStyle = titleStyle;
        sheetObject.cell(CellIndex.indexByString("A2")).value = TextCellValue(
          'PT. PLN (PERSERO) UPDL PANDAAN',
        );
        sheetObject.cell(CellIndex.indexByString("A2")).cellStyle = titleStyle;

        sheetObject.cell(CellIndex.indexByString("A3")).value = TextCellValue(
          periodeText,
        );
        sheetObject.cell(CellIndex.indexByString("A3")).cellStyle = titleStyle;

        sheetObject.cell(CellIndex.indexByString("A4")).value = TextCellValue(
          'Tanggal Unduh',
        );
        sheetObject.cell(CellIndex.indexByString("B4")).value = TextCellValue(
          ': $tanggalUnduhStr',
        );

        List<String> headers = [
          'Gedung/Ruangan',
          'Lokasi Spesifik',
          'Status',
          'Kode Unik',
          'Titik Koordinat',
          'Merk',
          'Jenis Lampu',
          'Daya Listrik (Watt)',
          'Petugas Pemasangan',
          'Catatan',
        ];
        for (int i = 0; i < headers.length; i++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5),
          );
          cell.value = TextCellValue(headers[i]);
          cell.cellStyle = headerStyle;
        }

        int rowIndex = 6;
        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          String koordinat =
              '${data['latitude'] ?? '-'}, ${data['longitude'] ?? '-'}';

          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['gedung_ruangan']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['lokasi_spesifik']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['status']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['kode_unik']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            koordinat,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['merk_lampu']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['jenis_lampu']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
              )
              .value = IntCellValue(
            int.tryParse(data['watt'].toString()) ?? 0,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['petugas_pasang']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['catatan']?.toString() ?? '-',
          );
          rowIndex++;
        }
      }
      // ==========================================================
      // KONDISI 3: APAR (KODINGAN LAMA)
      // ==========================================================
      else if (kategori == 'APAR' && sheetObject != null) {
        sheetObject.cell(CellIndex.indexByString("A1")).value = TextCellValue(
          'LAPORAN INSPEKSI APAR TERBARU',
        );
        sheetObject.cell(CellIndex.indexByString("A1")).cellStyle = titleStyle;
        sheetObject.cell(CellIndex.indexByString("A2")).value = TextCellValue(
          'PT. PLN (PERSERO) UPDL PANDAAN',
        );
        sheetObject.cell(CellIndex.indexByString("A2")).cellStyle = titleStyle;

        sheetObject.cell(CellIndex.indexByString("A3")).value = TextCellValue(
          periodeText,
        );
        sheetObject.cell(CellIndex.indexByString("A3")).cellStyle = titleStyle;

        sheetObject.cell(CellIndex.indexByString("A4")).value = TextCellValue(
          'Tanggal Unduh',
        );
        sheetObject.cell(CellIndex.indexByString("B4")).value = TextCellValue(
          ': $tanggalUnduhStr',
        );

        List<String> headers = [
          'NO',
          'TGL INSPEKSI',
          'LOKASI',
          'NAMA ALAT / MERK',
          'NO APAR',
          'BERAT (KG)',
          'PETUGAS',
          'TGL KADALUARSA',
          'KOORDINAT',
          'LABEL PENGISIAN',
          'TEKANAN',
          'SAFETY PIN',
          'HANDLE / TUAS',
          'SELANG & NOZZLE',
          'STATUS',
          'KETERANGAN',
        ];
        for (int i = 0; i < headers.length; i++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5),
          );
          cell.value = TextCellValue(headers[i]);
          cell.cellStyle = headerStyle;
        }

        int rowIndex = 6;
        int no = 1;
        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;

          String docIdBarang =
              data['docIdBarang']?.toString() ??
              data['id_barang']?.toString() ??
              '';
          String namaBarangRiwayat = data['nama_barang']?.toString() ?? '';

          String extractedNoApar = namaBarangRiwayat.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          int? noAparRiwayatInt = int.tryParse(extractedNoApar);

          Map<String, dynamic> master = {};

          if (docIdBarang.isNotEmpty && masterData.containsKey(docIdBarang)) {
            master = masterData[docIdBarang]!;
          }

          if (master.isEmpty && noAparRiwayatInt != null) {
            for (var m in masterData.values) {
              var spec = m['spesifikasi'];
              if (spec != null && spec is Map) {
                String noAparMasterStr =
                    spec['No APAR']?.toString().replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    ) ??
                    '';
                int? noAparMasterInt = int.tryParse(noAparMasterStr);
                if (noAparMasterInt == noAparRiwayatInt) {
                  master = m;
                  break;
                }
              }
            }
          }

          var spec = master['spesifikasi'] is Map
              ? master['spesifikasi'] as Map<String, dynamic>
              : {};

          String tanggalStr = '-';
          if (data['tanggal'] != null) {
            DateTime tgl = (data['tanggal'] as Timestamp).toDate();
            tanggalStr = DateFormat('dd MMM yyyy - HH:mm').format(tgl);
          }

          String lokasi =
              master['lokasi']?.toString() ?? data['lokasi']?.toString() ?? '-';
          String merk =
              master['nama_barang']?.toString() ??
              data['nama_barang']?.toString() ??
              'Powder';

          String noApar = spec['No APAR']?.toString() ?? extractedNoApar;
          if (noApar.isEmpty) noApar = '-';

          String berat =
              spec['Berat']?.toString() ?? data['berat']?.toString() ?? '-';
          String petugas = data['nama_pemeriksa']?.toString() ?? '-';
          String tglKadaluarsa =
              master['tanggal_kadaluarsa']?.toString() ??
              data['tgl_kadaluarsa']?.toString() ??
              '-';

          String koordinat = master['koordinat']?.toString() ?? '-';
          if (koordinat == '-' &&
              data['latitude'] != null &&
              data['longitude'] != null) {
            koordinat = '${data['latitude']}, ${data['longitude']}';
          }

          String keterangan = data['catatan']?.toString() ?? '-';
          if (keterangan.trim().isEmpty) keterangan = '-';

          String label = '-';
          String tekanan = '-';
          String safetyPin = '-';
          String handle = '-';
          String selang = '-';
          bool isGood = true;

          if (data['hasil_checklist'] != null) {
            Map<String, dynamic> cl = Map<String, dynamic>.from(
              data['hasil_checklist'],
            );
            cl.forEach((key, value) {
              String k = key.toLowerCase();
              String v = (value == true) ? 'v' : 'x';
              if (value == false) isGood = false;

              if (k.contains('label'))
                label = v;
              else if (k.contains('tekanan'))
                tekanan = v;
              else if (k.contains('safety') || k.contains('segel'))
                safetyPin = v;
              else if (k.contains('handle') || k.contains('tuas'))
                handle = v;
              else if (k.contains('selang') || k.contains('nozzle'))
                selang = v;
            });
          }

          String status = isGood ? 'GOOD' : 'RUSAK';

          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
              )
              .value = IntCellValue(
            no++,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            tanggalStr,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            lokasi,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            merk,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            noApar,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            berat,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            petugas,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            tglKadaluarsa,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            koordinat,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            label,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            tekanan,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            safetyPin,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            handle,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            selang,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            status,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            keterangan,
          );

          rowIndex++;
        }
      }
      // ==========================================================
      // KONDISI 4: KATEGORI LAINNYA (ATK, APD, Dll - KODINGAN LAMA)
      // ==========================================================
      else if (sheetObject != null) {
        sheetObject.cell(CellIndex.indexByString("A1")).value = TextCellValue(
          'LAPORAN INSPEKSI ${kategori.toUpperCase()}',
        );
        sheetObject.cell(CellIndex.indexByString("A1")).cellStyle = titleStyle;
        sheetObject.cell(CellIndex.indexByString("A2")).value = TextCellValue(
          'PT. PLN (PERSERO) UPDL PANDAAN',
        );
        sheetObject.cell(CellIndex.indexByString("A2")).cellStyle = titleStyle;

        sheetObject.cell(CellIndex.indexByString("A3")).value = TextCellValue(
          periodeText,
        );
        sheetObject.cell(CellIndex.indexByString("A3")).cellStyle = titleStyle;

        sheetObject.cell(CellIndex.indexByString("A4")).value = TextCellValue(
          'Tanggal Unduh',
        );
        sheetObject.cell(CellIndex.indexByString("B4")).value = TextCellValue(
          ': $tanggalUnduhStr',
        );

        List<String> headers = [
          'NO',
          'TGL INSPEKSI',
          'LOKASI / NAMA ALAT',
          'NAMA PEMERIKSA',
          'CATATAN',
          'RINCIAN CHECKLIST',
        ];
        for (int i = 0; i < headers.length; i++) {
          var cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5),
          );
          cell.value = TextCellValue(headers[i]);
          cell.cellStyle = headerStyle;
        }

        int rowIndex = 6;
        int no = 1;
        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;

          String tanggalStr = '-';
          if (data['tanggal'] != null) {
            DateTime tgl = (data['tanggal'] as Timestamp).toDate();
            tanggalStr = DateFormat('dd/MM/yyyy HH:mm').format(tgl);
          }

          String checklistStr = '';
          if (data['hasil_checklist'] != null) {
            Map<String, dynamic> cl = Map<String, dynamic>.from(
              data['hasil_checklist'],
            );
            cl.forEach((key, value) {
              String valStr = value.toString();
              if (value == true) valStr = 'Baik';
              if (value == false) valStr = 'Rusak / Hilang';
              checklistStr += '- $key: $valStr\n';
            });
          }

          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
              )
              .value = IntCellValue(
            no++,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            tanggalStr,
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['nama_barang']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['nama_pemeriksa']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            data['catatan']?.toString() ?? '-',
          );
          sheetObject
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            checklistStr.trim(),
          );
          rowIndex++;
        }
      }

      if (excel.tables.containsKey('TempSheet')) {
        excel.delete('TempSheet');
      }

      String fileNameKategori = kategori.replaceAll(" ", "_");
      String outputFileName =
          'Laporan_${fileNameKategori}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      List<int>? fileBytes = excel.encode();

      if (fileBytes != null) {
        if (kIsWeb) {
          final blob = html.Blob(
            [fileBytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = outputFileName;
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File Excel berhasil didownload di Browser!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          Directory tempDir = await getTemporaryDirectory();
          String outputPath = '${tempDir.path}/$outputFileName';
          File file = File(outputPath);

          await file.writeAsBytes(fileBytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Berhasil! Silakan pilih aplikasi untuk menyimpan filenya.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
          await Share.shareXFiles([
            XFile(outputPath),
          ], text: 'Laporan Inventaris ($kategori)');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ==========================================
  // DIALOG RINCIAN CHECKLIST
  // ==========================================
  void _showDetailDialog(Map<String, dynamic> data) {
    String tanggalStr = '-';
    if (data['tanggal'] != null) {
      DateTime tgl = (data['tanggal'] as Timestamp).toDate();
      tanggalStr = DateFormat('dd MMM yyyy HH:mm').format(tgl);
    }

    Map<String, dynamic> cl = data['hasil_checklist'] != null
        ? Map<String, dynamic>.from(data['hasil_checklist'])
        : {};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Detail Inspeksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F3460),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Alat: ${data['nama_barang'] ?? '-'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Petugas: ${data['nama_pemeriksa'] ?? '-'}'),
              Text('Tanggal: $tanggalStr'),
              const Divider(height: 20, thickness: 1.5),
              const Text(
                'Hasil Pemeriksaan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...cl.entries.map((entry) {
                String valStr = entry.value.toString();
                Color valColor = Colors.black87;
                if (entry.value == true) {
                  valStr = 'Baik';
                  valColor = Colors.green;
                }
                if (entry.value == false) {
                  valStr = 'Rusak';
                  valColor = Colors.red;
                }
                if (entry.value is int && (entry.value as int) > 0) {
                  valColor = Colors.red;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        valStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: valColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(height: 20, thickness: 1.5),
              const Text(
                'Catatan Tambahan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                data['catatan'] ?? '-',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Riwayat & Laporan',
          style: TextStyle(
            color: Color(0xFF0F3460),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F3460)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('riwayat_inspeksi')
            .orderBy('tanggal', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF149C94)),
            );
          }

          // Kumpulan raw data dari Firestore
          List<QueryDocumentSnapshot> allDocs = snapshot.hasData
              ? snapshot.data!.docs
              : [];

          // LOGIKA FILTER TAMPILAN UI HANYA MENAMPILKAN 1 DATA TERBARU PER ITEM
          Map<String, QueryDocumentSnapshot> latestUI_DocsMap = {};
          for (var doc in allDocs) {
            var data = doc.data() as Map<String, dynamic>;

            // Menggunakan nama barang sebagai identifier (misal: "APAR 1")
            String identifier =
                data['docIdBarang']?.toString() ??
                data['id_barang']?.toString() ??
                data['nama_barang']?.toString() ??
                doc.id;

            DateTime? currentTgl;
            if (data['tanggal'] != null) {
              currentTgl = (data['tanggal'] as Timestamp).toDate();
            }

            if (!latestUI_DocsMap.containsKey(identifier)) {
              latestUI_DocsMap[identifier] = doc;
            } else {
              var existingData =
                  latestUI_DocsMap[identifier]!.data() as Map<String, dynamic>;
              DateTime? existingTgl;
              if (existingData['tanggal'] != null) {
                existingTgl = (existingData['tanggal'] as Timestamp).toDate();
              }
              // Timpa dengan data yang lebih baru
              if (currentTgl != null &&
                  (existingTgl == null || currentTgl.isAfter(existingTgl))) {
                latestUI_DocsMap[identifier] = doc;
              }
            }
          }

          // Merubah kumpulan Map menjadi List lalu diurutkan sesuai tanggal paling baru ke terlama
          List<QueryDocumentSnapshot> uniqueUIDocs = latestUI_DocsMap.values
              .toList();
          uniqueUIDocs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            DateTime tglA = dataA['tanggal'] != null
                ? (dataA['tanggal'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            DateTime tglB = dataB['tanggal'] != null
                ? (dataB['tanggal'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            return tglB.compareTo(tglA); // descending order
          });

          return Column(
            children: [
              // 1. BAGIAN ATAS: LISTVIEW RIWAYAT (Di-filter hanya yang terbaru)
              Expanded(
                child: uniqueUIDocs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text(
                              'Belum ada riwayat inspeksi.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: uniqueUIDocs.length,
                        itemBuilder: (context, index) {
                          var data =
                              uniqueUIDocs[index].data()
                                  as Map<String, dynamic>;

                          String tanggalStr = '-';
                          if (data['tanggal'] != null) {
                            DateTime tgl = (data['tanggal'] as Timestamp)
                                .toDate();
                            tanggalStr = DateFormat(
                              'dd MMM yyyy • HH:mm',
                            ).format(tgl);
                          }

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF149C94,
                                ).withOpacity(0.1),
                                child: const Icon(
                                  Icons.fact_check,
                                  color: Color(0xFF149C94),
                                ),
                              ),
                              title: Text(
                                data['nama_barang'] ?? 'Tanpa Nama',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Petugas: ${data['nama_pemeriksa'] ?? '-'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    tanggalStr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: () => _showDetailDialog(data),
                            ),
                          );
                        },
                      ),
              ),

              // 2. BAGIAN BAWAH: TOMBOL DOWNLOAD EXCEL
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3), // Efek bayangan ke atas
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting
                          ? null
                          : () => _showExportDialog(
                              allDocs,
                            ), // Tetap lempar allDocs agar Excel filtering berjalan sempurna
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download, color: Colors.white),
                      label: Text(
                        _isExporting
                            ? 'Sedang Membuat Excel...'
                            : 'Download Laporan Excel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
