import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import '../services/firestore_service.dart';
import 'detail_p3k_screen.dart';
import 'tambah_p3k_screen.dart';

class DaftarP3kScreen extends StatefulWidget {
  const DaftarP3kScreen({super.key});

  @override
  State<DaftarP3kScreen> createState() => _DaftarP3kScreenState();
}

class _DaftarP3kScreenState extends State<DaftarP3kScreen> {
  String _searchQuery = '';
  bool _isExporting = false;
  final String namaKategori = 'P3K';

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

  Future<void> _unduhLaporanExcel() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menyiapkan laporan P3K...'),
          duration: Duration(seconds: 2),
        ),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection(namaKategori)
          .get();

      if (snapshot.docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data P3K untuk diekspor.')),
        );
        setState(() => _isExporting = false);
        return;
      }

      var excel = Excel.createExcel();
      String sheetName = 'P3K';
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheet, sheetName);
      Sheet sheetObject = excel[sheetName];

      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      DateTime now = DateTime.now();
      String bulanTahun = '${_namaBulan(now.month).toUpperCase()} ${now.year}';

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
          data['gedung_ruang']?.toString() ?? data['lokasi']?.toString() ?? '-',
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
                CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
              )
              .value = TextCellValue(
            rowData[i],
          );
        }
        rowIndex++;
        nomorUrut++;
      }

      var fileBytes = excel.encode();
      if (fileBytes == null) throw Exception("Gagal membuat file Excel");

      final String namaFile =
          'Laporan_P3K_${DateTime.now().millisecondsSinceEpoch}';

      await FileSaver.instance.saveFile(
        name: '$namaFile.xlsx',
        bytes: Uint8List.fromList(fileBytes),
        mimeType: MimeType.microsoftExcel,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan P3K berhasil diunduh!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh laporan P3K: $e'),
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
        title: const Text(
          'Daftar Kotak P3K',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                  tooltip: 'Unduh Laporan Excel P3K',
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
                hintText: 'Cari gedung atau ruang P3K...',
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
              stream: FirestoreService().getBarangByKategori(namaKategori),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Terjadi kesalahan saat memuat data P3K.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada data P3K',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final dokumen = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  String searchString =
                      '${data['gedung_ruang'] ?? ''} ${data['lokasi'] ?? ''}';
                  return searchString.toLowerCase().contains(_searchQuery);
                }).toList();

                if (dokumen.isEmpty) {
                  return Center(
                    child: Text(
                      'Kotak P3K tidak ditemukan',
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

                    String judulUtama =
                        data['gedung_ruang'] ??
                        data['lokasi'] ??
                        'Tanpa Nama Ruangan';
                    String infoHighlight = '${data['kapasitas'] ?? 0} Org';
                    String tglEdit = _formatTanggalEdit(data);
                    String infoSekunder = tglEdit.isNotEmpty
                        ? 'Diubah: $tglEdit'
                        : 'Ext: ${data['existing'] ?? '-'}';
                    String? imageUrl = data['foto_url'];

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
                                : const Icon(
                                    Icons.medical_services,
                                    color: Colors.red,
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
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  infoHighlight,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
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
                                    color: Colors.grey.shade600,
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
                              builder: (context) => DetailP3kScreen(
                                documentId:
                                    docId, // Sesuaikan dengan nama variabel ID dokumen Anda (misal: docId / documentId)
                                dataBarang: data, // Mengirim data P3K
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
      // Tombol tambah dapat diarahkan ke form penambahan P3K atau TambahBarangScreen
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahP3kScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
