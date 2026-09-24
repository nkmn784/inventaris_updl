import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'edit_barang_screen.dart';

class DetailBarangScreen extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> dataBarang;

  const DetailBarangScreen({
    super.key,
    required this.documentId,
    required this.dataBarang,
  });

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  // Fungsi otomatis memfilter dan menghapus riwayat > 1 tahun (365 hari) dari Firestore
  List<dynamic> _filterDanBersihkanRiwayat(
    String kategori,
    String docId,
    List<dynamic> riwayatAsli,
    String keyField,
  ) {
    if (riwayatAsli.isEmpty) return [];

    DateTime batasWaktu = DateTime.now().subtract(const Duration(days: 365));

    List<dynamic> riwayatTerbaru = riwayatAsli.where((element) {
      if (element is! Map<String, dynamic>) return true;
      String dateString = element['tanggal'] ?? element['tgl'] ?? '';
      DateTime? parsedDate = DateTime.tryParse(dateString);

      if (parsedDate == null) return true;
      return parsedDate.isAfter(batasWaktu);
    }).toList();

    if (riwayatTerbaru.length != riwayatAsli.length) {
      FirestoreService()
          .updateBarang(kategori, docId, {keyField: riwayatTerbaru})
          .catchError((e) {
            debugPrint('Gagal membersihkan riwayat $kategori di Firestore: $e');
          });
    }

    return riwayatTerbaru;
  }

  Widget _buildModernContainer({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _rowInfo(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            val,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String kategori = dataBarang['kategori'] ?? 'APD';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(kategori)
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.blue.shade50,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
              title: Text(
                'Detail $kategori',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Colors.blue.shade50,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
              title: Text(
                'Detail $kategori',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: const Center(
              child: Text('Data telah dihapus atau tidak ditemukan.'),
            ),
          );
        }

        final currentData = snapshot.data!.data() as Map<String, dynamic>;

        List<dynamic> riwayatStokApd = _filterDanBersihkanRiwayat(
          kategori,
          documentId,
          currentData['riwayat_jumlah_apd'] ?? [],
          'riwayat_jumlah_apd',
        );
        List<dynamic> riwayatStokAtk = _filterDanBersihkanRiwayat(
          kategori,
          documentId,
          currentData['riwayat_stok_atk'] ?? [],
          'riwayat_stok_atk',
        );
        List<dynamic> riwayatStokAmenities = _filterDanBersihkanRiwayat(
          kategori,
          documentId,
          currentData['riwayat_stok_amenities'] ?? [],
          'riwayat_stok_amenities',
        );

        return Scaffold(
          backgroundColor: Colors.blue.shade50,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
            title: Text(
              'Detail $kategori',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // AREA SCROLL: Hanya berisi detail data dan riwayat
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kategori == 'APD') ...[
                  _buildDetailApd(currentData),
                  _buildRiwayatPergerakanStok(riwayatStokApd),
                ] else ...[
                  _buildDetailAtkAmenities(currentData),
                  _buildRiwayatPergerakanStok(
                    kategori == 'ATK' ? riwayatStokAtk : riwayatStokAmenities,
                  ),
                ],
              ],
            ),
          ),

          // AREA FIXED BOTTOM BAR: Tombol akan selalu terlihat di bagian bawah layar
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade900.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditBarangScreen(
                              documentId: documentId,
                              dataBarang: currentData,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Data'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _konfirmasiHapus(context, kategori),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      label: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET DETAIL ATK & AMENITIES ---
  Widget _buildDetailAtkAmenities(Map<String, dynamic> data) {
    String catatan = (data['keterangan'] ?? data['catatan'])?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['nama_barang'] ?? 'Tanpa Nama Barang',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Satuan: ${data['satuan'] ?? '-'}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const Divider(height: 24),

              _rowInfo(
                'Tanggal Transaksi Terakhir',
                _formatDate(data['tanggal_transaksi']),
              ),
              _rowInfo(
                'Barang Masuk Terakhir',
                '${data['masuk'] ?? '0'} ${data['satuan'] ?? ''}',
              ),
              _rowInfo(
                'Barang Keluar Terakhir',
                '${data['keluar'] ?? '0'} ${data['satuan'] ?? ''}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),

        _buildModernContainer(
          color: Colors.blue.shade700,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sisa Persediaan Saat Ini',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Total Stok Aktif',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data['jumlah'] ?? data['sisa_jumlah'] ?? data['stok_sekarang'] ?? '0'} ${data['satuan'] ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (catatan.isNotEmpty) ...[
          const SizedBox(height: 15),
          _buildModernContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan Khusus',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  catatan,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- WIDGET DETAIL APD ---
  Widget _buildDetailApd(Map<String, dynamic> data) {
    String catatan = (data['keterangan'] ?? data['catatan'])?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['peralatan'] ?? 'Tanpa Nama Peralatan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const Divider(height: 24),
              _rowInfo('Masa Pakai', data['masa_pakai'] ?? '-'),
              _rowInfo('Tanggal Kadaluarsa', data['tanggal_kadaluarsa'] ?? '-'),
              _rowInfo('Kondisi', data['kondisi'] ?? '-'),
              _rowInfo('Tahun Pembelian', data['pembelian'] ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: 15),

        _buildModernContainer(
          color: Colors.blue.shade700,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sisa Persediaan Saat Ini',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Total Stok APD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data['jumlah'] ?? data['sisa_jumlah'] ?? '0'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (catatan.isNotEmpty) ...[
          const SizedBox(height: 15),
          _buildModernContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan Transaksi Terakhir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  catatan,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- WIDGET RIWAYAT PERGERAKAN ---
  Widget _buildRiwayatPergerakanStok(List<dynamic> riwayatStok) {
    if (riwayatStok.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Riwayat Pergerakan Stock',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue.shade900,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Mematikan scroll listview agar bisa digulir bersama layar
          itemCount: riwayatStok.length,
          itemBuilder: (context, index) {
            final riwayat = riwayatStok[riwayatStok.length - 1 - index];
            String dateString = riwayat['tanggal'] ?? riwayat['tgl'] ?? '';
            String tglFormat = dateString;
            try {
              if (dateString.isNotEmpty) {
                DateTime dt = DateTime.parse(dateString);
                tglFormat =
                    "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}  •  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              }
            } catch (_) {
              tglFormat = dateString;
            }

            int masuk = int.tryParse(riwayat['masuk']?.toString() ?? '0') ?? 0;
            int keluar =
                int.tryParse(riwayat['keluar']?.toString() ?? '0') ?? 0;

            int jumlahBaru =
                riwayat['jumlah_baru'] ??
                riwayat['sisa'] ??
                riwayat['jumlah'] ??
                0;
            int jumlahLama =
                riwayat['jumlah_lama'] ??
                (masuk > 0
                    ? (jumlahBaru - masuk)
                    : (keluar > 0 ? (jumlahBaru + keluar) : jumlahBaru));

            int selisih = riwayat['selisih'] ?? (jumlahBaru - jumlahLama);
            if (masuk > 0) selisih = masuk;
            if (keluar > 0) selisih = -keluar;

            bool isNambah = selisih > 0;
            bool isBerkurang = selisih < 0;
            Color badgeColor = isNambah
                ? Colors.green.shade700
                : (isBerkurang ? Colors.red.shade700 : Colors.grey.shade700);
            Color bgColor = isNambah
                ? Colors.green.shade50
                : (isBerkurang ? Colors.red.shade50 : Colors.grey.shade100);
            String tanda = isNambah ? '+' : '';

            String catatan = riwayat['catatan'] ?? riwayat['keterangan'] ?? '-';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tglFormat.isEmpty ? '-' : tglFormat,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          selisih == 0 ? 'Tetap' : '$tanda$selisih',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Stok Awal: $jumlahLama',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Akhir: $jumlahBaru',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  if (catatan != '-') ...[
                    const SizedBox(height: 6),
                    Text(
                      'Catatan: $catatan',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- DIALOG KONFIRMASI HAPUS ---
  void _konfirmasiHapus(BuildContext context, String kategori) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Data?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Data ini akan dihapus secara permanen. Apakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().hapusBarang(kategori, documentId);

              // --- SISIPKAN PENCATAT LOG DI SINI ---
              String namaBarang =
                  dataBarang['peralatan'] ??
                  dataBarang['nama_barang'] ??
                  'Barang';
              await FirestoreService().catatLogAktivitas(
                tipeAksi: 'HAPUS',
                kategori: kategori,
                detail: 'Menghapus data $kategori: $namaBarang',
              );
              // ----------------------------------------

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data $kategori berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
