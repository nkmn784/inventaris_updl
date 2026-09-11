import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _salinKoordinat(BuildContext context, String lat, String long) {
    if (lat == '-' || long == '-' || lat.isEmpty || long.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titik koordinat tidak tersedia!')),
      );
      return;
    }
    final teksKoordinat = '$lat, $long';
    Clipboard.setData(ClipboardData(text: teksKoordinat));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Koordinat disalin: $teksKoordinat')),
    );
  }

  Future<void> _bukaGoogleMaps(
    BuildContext context,
    String lat,
    String long,
  ) async {
    if (lat == '-' || long == '-' || lat.isEmpty || long.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titik koordinat tidak tersedia!')),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$long',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String kategori = dataBarang['kategori'] ?? 'APAR';

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

        // Ambil data riwayat pergerakan stok
        List<dynamic> riwayatStokApd = currentData['riwayat_jumlah_apd'] ?? [];
        List<dynamic> riwayatStokAtk = currentData['riwayat_stok_atk'] ?? [];
        List<dynamic> riwayatStokAmenities =
            currentData['riwayat_stok_amenities'] ?? [];

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
                // PERBAIKAN: Mengubah 'AMENITIES' menjadi 'Amenities' agar foto tersembunyi dengan benar
                if (kategori != 'APD' &&
                    kategori != 'ATK' &&
                    kategori != 'Amenities' &&
                    currentData['foto_url'] != null &&
                    currentData['foto_url'].toString().isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 250,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(currentData['foto_url']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                if (kategori == 'APAR') _buildDetailApar(context, currentData),
                if (kategori == 'P3K') _buildDetailP3K(context, currentData),
                if (kategori == 'APD') ...[
                  _buildDetailApd(context, currentData),
                  _buildRiwayatPergerakanStok(riwayatStokApd),
                ],
                if (kategori == 'ATK') ...[
                  _buildDetailAtk(context, currentData),
                  _buildRiwayatPergerakanStok(riwayatStokAtk),
                ],
                // PERBAIKAN: Mengubah 'AMENITIES' menjadi 'Amenities' agar widget muncul
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

  // ==========================================
  // WIDGET DETAIL AMENITIES
  // ==========================================
  Widget _buildDetailAmenities(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Informasi Barang
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

        // 2. Data Transaksi
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

        // 3. Sisa Persediaan / Jumlah Stock
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

        // 4. Catatan (Muncul jika ada isinya saja)
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

  // ==========================================
  // WIDGET DETAIL ATK
  // ==========================================
  Widget _buildDetailAtk(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Informasi Barang
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

        // 2. Data Transaksi
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

        // 3. Sisa Persediaan / Jumlah Stock
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

        // 4. Catatan (Muncul jika ada isinya saja)
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

  // ==========================================
  // WIDGET RIWAYAT PERGERAKAN STOK
  // ==========================================
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
            // Tampilkan dari riwayat terbaru (paling atas)
            final riwayat = riwayatStok[riwayatStok.length - 1 - index];

            // 1. Format Tanggal dan Jam
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

            // 2. Format Pergerakan Stok (Masuk / Keluar)
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

  Widget _buildDetailApar(BuildContext context, Map<String, dynamic> data) {
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
                  data['nama_alat'] ?? 'Tanpa Nama',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(data['lokasi'] ?? 'Lokasi tidak diketahui'),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                _buildInfoRow('No APAR', data['no_apar'] ?? '-'),
                _buildInfoRow('Berat', '${data['berat'] ?? '-'} Kg'),
                _buildInfoRow(
                  'Tanggal Kadaluarsa',
                  _formatDate(data['tanggal_kadaluarsa']),
                ),
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
                  'Checklist Kondisi:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildChecklistItem('Label Pengisian', data['checklist_label']),
                _buildChecklistItem(
                  'Tekanan (Jarum Hijau)',
                  data['checklist_tekanan'],
                ),
                _buildChecklistItem('Safety Pin', data['checklist_safety_pin']),
                _buildChecklistItem('Handle', data['checklist_handle']),
                _buildChecklistItem(
                  'Selang & Nozzle',
                  data['checklist_selang'],
                ),
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
                  'Keterangan:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(data['keterangan'] ?? 'Tidak ada keterangan'),
                const Divider(height: 24, thickness: 1),
                _buildKoordinatWidget(context, data),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailP3K(BuildContext context, Map<String, dynamic> data) {
    Map<String, dynamic> items = Map<String, dynamic>.from(
      data['checklist_items'] ?? {},
    );

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
                  'Gedung/Ruang: ${data['gedung_ruang'] ?? data['lokasi'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kapasitas: ${data['kapasitas'] ?? 0} Org'),
                    Text('Existing: ${data['existing'] ?? '-'}'),
                    Text('Rekomendasi: ${data['rekomendasi'] ?? '-'}'),
                  ],
                ),
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
                  'Kelengkapan Item P3K',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ...items.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key),
                        Icon(
                          e.value == true ? Icons.check_circle : Icons.cancel,
                          color: e.value == true ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  );
                }),
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
                  'Tanggal Kadaluarsa Cairan/Obat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildInfoRow(
                  'Aquades (25ml)',
                  _formatDate(data['exp_aquades']),
                ),
                _buildInfoRow(
                  'Povidon Iodine',
                  _formatDate(data['exp_povidon']),
                ),
                _buildInfoRow('Alcohol 70%', _formatDate(data['exp_alcohol'])),
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
                  'Keterangan / Temuan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(data['keterangan'] ?? '-'),
                const Divider(height: 24, thickness: 1),
                _buildKoordinatWidget(context, data),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKoordinatWidget(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final String lat = data['latitude']?.toString() ?? '-';
    final String long = data['longitude']?.toString() ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Titik Koordinat GPS:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                  tooltip: 'Salin Koordinat',
                  onPressed: () => _salinKoordinat(context, lat, long),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.map_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                  tooltip: 'Buka di Google Maps',
                  onPressed: () => _bukaGoogleMaps(context, lat, long),
                ),
              ],
            ),
          ],
        ),
        Text('Latitude: $lat'),
        Text('Longitude: $long'),
      ],
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

  Widget _buildChecklistItem(String title, bool? value) {
    bool isTrue = value ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isTrue ? Icons.check_circle : Icons.cancel,
            color: isTrue ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(title),
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
