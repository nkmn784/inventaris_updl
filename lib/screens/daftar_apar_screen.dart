import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

import '../../services/firestore_service.dart';
// Pastikan Anda membuat file ini nanti:
import 'tambah_apar_screen.dart';
import 'detail_apar_screen.dart';

class DaftarAparScreen extends StatefulWidget {
  const DaftarAparScreen({super.key});

  @override
  State<DaftarAparScreen> createState() => _DaftarAparScreenState();
}

class _DaftarAparScreenState extends State<DaftarAparScreen> {
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

  // ==========================================
  // EXPORT EXCEL KHUSUS APAR
  // ==========================================
  Future<void> _unduhLaporanExcel() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Menyiapkan laporan APAR...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('APAR')
          .get();

      if (snapshot.docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data APAR untuk diekspor.')),
        );
        setState(() => _isExporting = false);
        return;
      }

      var excel = Excel.createExcel();
      String sheetName = 'APAR';
      String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheet, sheetName);
      Sheet sheetObject = excel[sheetName];

      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      DateTime now = DateTime.now();
      String bulanTahun = '${_namaBulan(now.month).toUpperCase()} ${now.year}';
      String tanggalHariIni =
          '${now.day.toString().padLeft(2, '0')} ${_namaBulan(now.month)} ${now.year}';

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
        String tglClean = rawTgl.contains('T') ? rawTgl.split('T')[0] : rawTgl;

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
          'Laporan_APAR_${DateTime.now().millisecondsSinceEpoch}';

      await FileSaver.instance.saveFile(
        name: '$namaFile.xlsx',
        bytes: Uint8List.fromList(fileBytes),
        mimeType: MimeType.microsoftExcel,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan APAR berhasil diunduh!'),
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
        title: const Text(
          'Daftar APAR',
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
                hintText: 'Cari no apar, lokasi, atau nama alat...',
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
              stream: FirestoreService().getBarangByKategori('APAR'),
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
                          Icons.fire_extinguisher,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada data APAR',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final dokumen = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  String searchString =
                      '${data['nama_alat'] ?? ''} ${data['no_apar'] ?? ''} ${data['lokasi'] ?? ''}';
                  return searchString.toLowerCase().contains(_searchQuery);
                }).toList();

                if (dokumen.isEmpty) {
                  return Center(
                    child: Text(
                      'APAR tidak ditemukan',
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
                    String? imageUrl = data['foto_url'];

                    // Info Khusus APAR
                    String judulUtama = 'APAR No. ${data['no_apar'] ?? '-'}';
                    String infoHighlight = '${data['berat'] ?? '-'} Kg';
                    String infoSekunder = 'Lokasi: ${data['lokasi'] ?? '-'}';

                    bool tekananAman = data['checklist_tekanan'] ?? true;
                    bool pinAman = data['checklist_safety_pin'] ?? true;
                    bool isWarning = (!tekananAman || !pinAman);

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
                                    Icons.fire_extinguisher,
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
                          // Buat salinan data dan pastikan kategori 'APAR' ikut dikirim
                          final Map<String, dynamic> dataLengkap =
                              Map<String, dynamic>.from(data);
                          dataLengkap['kategori'] =
                              'APAR'; // <-- KUNCI UTAMA AGAR KOLEKSI FIRESTORE TIDAK SALAH

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailAparScreen(
                                dataBarang: dataLengkap,
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
            MaterialPageRoute(builder: (context) => const TambahAparScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
