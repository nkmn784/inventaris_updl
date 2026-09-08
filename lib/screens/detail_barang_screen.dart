import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan import Firestore
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
    DateTime dt = DateTime.parse(isoDate);
    return '${dt.day}-${dt.month}-${dt.year}';
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

    // Menggunakan StreamBuilder agar data ter-update secara real-time dari Firestore
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

        // Ambil data terbaru langsung dari Firestore
        final currentData = snapshot.data!.data() as Map<String, dynamic>;

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
                        dataBarang:
                            currentData, // Mengirim data terbaru ke Edit Screen
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
              children: [
                // FOTO DITAMPILKAN DI ATAS
                if (currentData['foto_url'] != null &&
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

                // RENDER DETAIL SESUAI KATEGORI
                if (kategori == 'APAR') _buildDetailApar(context, currentData),
                if (kategori == 'P3K') _buildDetailP3K(context, currentData),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // DETAIL APAR
  // ==========================================
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

  // ==========================================
  // DETAIL P3K
  // ==========================================
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

  // ==========================================
  // WIDGET KOORDINAT GPS
  // ==========================================
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
