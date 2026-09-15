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
      return '${dt.day}-${dt.month}-${dt.year}';
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

      if (parsedDate == null)
        return true; // Pertahankan jika format tanggal tidak valid
      return parsedDate.isAfter(batasWaktu);
    }).toList();

    // Jika ada data yang berumur lebih dari 1 tahun, perbarui Firestore
    if (riwayatTerbaru.length != riwayatAsli.length) {
      FirestoreService()
          .editBarang(kategori, docId, {keyField: riwayatTerbaru})
          .catchError((e) {
            debugPrint('Gagal membersihkan riwayat $kategori di Firestore: $e');
          });
    }

    return riwayatTerbaru;
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
            appBar: AppBar(title: Text('Detail $kategori')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text('Detail $kategori')),
            body: const Center(
              child: Text('Data telah dihapus atau tidak ditemukan.'),
            ),
          );
        }

        final currentData = snapshot.data!.data() as Map<String, dynamic>;

        // Menyaring dan membersihkan riwayat pergerakan stok untuk setiap kategori
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
          appBar: AppBar(
            title: Text('Detail $kategori'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
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
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _konfirmasiHapus(context, kategori),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kategori == 'APD') ...[
                  _buildDetailApd(context, currentData),
                  _buildRiwayatPergerakanStok(riwayatStokApd),
                ],
                if (kategori == 'ATK') ...[
                  _buildDetailAtk(context, currentData),
                  _buildRiwayatPergerakanStok(riwayatStokAtk),
                ],
                if (kategori == 'Amenities') ...[
                  _buildDetailAmenities(context, currentData),
                  _buildRiwayatPergerakanStok(riwayatStokAmenities),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailAmenities(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['nama_barang'] ?? 'Tanpa Nama Barang',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24, thickness: 1),
                _buildInfoRow('Satuan', data['satuan']?.toString() ?? '-'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Transaksi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildInfoRow(
                  'Tanggal Transaksi',
                  _formatDate(data['tanggal_transaksi']),
                ),
                _buildInfoRow(
                  'Barang Masuk',
                  '${data['masuk']?.toString() ?? '0'} ${data['satuan'] ?? ''}',
                ),
                _buildInfoRow(
                  'Barang Keluar',
                  '${data['keluar']?.toString() ?? '0'} ${data['satuan'] ?? ''}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sisa Persediaan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jumlah Stock Saat Ini',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${data['jumlah'] ?? data['sisa_jumlah'] ?? data['stok_sekarang'] ?? '0'} ${data['satuan'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if ((data['keterangan'] ?? data['catatan']) != null &&
            (data['keterangan'] ?? data['catatan']).toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Text(
                    (data['keterangan'] ?? data['catatan']).toString(),
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailAtk(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['nama_barang'] ?? 'Tanpa Nama Barang',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24, thickness: 1),
                _buildInfoRow('Satuan', data['satuan']?.toString() ?? '-'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Transaksi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildInfoRow(
                  'Tanggal Transaksi',
                  _formatDate(data['tanggal_transaksi']),
                ),
                _buildInfoRow(
                  'Barang Masuk',
                  '${data['masuk']?.toString() ?? '0'} ${data['satuan'] ?? ''}',
                ),
                _buildInfoRow(
                  'Barang Keluar',
                  '${data['keluar']?.toString() ?? '0'} ${data['satuan'] ?? ''}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sisa Persediaan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Jumlah Stock Saat Ini',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${data['jumlah'] ?? data['sisa_jumlah'] ?? data['stok_sekarang'] ?? '0'} ${data['satuan'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if ((data['keterangan'] ?? data['catatan']) != null &&
            (data['keterangan'] ?? data['catatan']).toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Text(
                    (data['keterangan'] ?? data['catatan']).toString(),
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRiwayatPergerakanStok(List<dynamic> riwayatStok) {
    if (riwayatStok.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'Riwayat Pergerakan Stock:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: riwayatStok.length,
          itemBuilder: (context, index) {
            final riwayat = riwayatStok[riwayatStok.length - 1 - index];
            String dateString = riwayat['tanggal'] ?? riwayat['tgl'] ?? '';
            String tglFormat = dateString;
            try {
              if (dateString.isNotEmpty) {
                DateTime dt = DateTime.parse(dateString);
                tglFormat =
                    "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} Jam ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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
                ? Colors.green
                : (isBerkurang ? Colors.red : Colors.grey);
            String tanda = isNambah ? '+' : '';

            String catatan = riwayat['catatan'] ?? riwayat['keterangan'] ?? '-';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.amber.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tglFormat.isEmpty ? '-' : tglFormat,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: badgeColor.withOpacity(0.5),
                            ),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Stok: $jumlahLama ',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.grey,
                        ),
                        Text(
                          ' Jumlah Terakhir: $jumlahBaru',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catatan: $catatan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailApd(BuildContext context, Map<String, dynamic> data) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['peralatan'] ?? 'Tanpa Nama Peralatan',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24, thickness: 1),
            _buildInfoRow('Jumlah', data['jumlah']?.toString() ?? '-'),
            _buildInfoRow('Masa Pakai', data['masa_pakai'] ?? '-'),
            _buildInfoRow(
              'Tanggal Kadaluarsa',
              data['tanggal_kadaluarsa'] ?? '-',
            ),
            _buildInfoRow('Kondisi', data['kondisi'] ?? '-'),
            _buildInfoRow('Pembelian', data['pembelian'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _konfirmasiHapus(BuildContext context, String kategori) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin hapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().hapusBarang(kategori, documentId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
