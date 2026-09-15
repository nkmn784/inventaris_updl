import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import 'edit_apar_screen.dart';

class DetailAparScreen extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> dataBarang;

  const DetailAparScreen({
    super.key,
    required this.documentId,
    required this.dataBarang,
  });

  String _formatDate(dynamic tglVal) {
    if (tglVal == null) return '-';
    if (tglVal is Timestamp) {
      DateTime dt = tglVal.toDate();
      return '${dt.day}-${dt.month}-${dt.year}';
    } else if (tglVal is String) {
      if (tglVal.isEmpty) return '-';
      try {
        DateTime dt = DateTime.parse(tglVal);
        return '${dt.day}-${dt.month}-${dt.year}';
      } catch (_) {
        return tglVal;
      }
    }
    return tglVal.toString();
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
        String? fotoUrl = currentData['foto_url'] ?? currentData['image_url'];

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
                      builder: (context) => EditAparScreen(
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
                if (fotoUrl != null && fotoUrl.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 250,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(fotoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                _buildDetailApar(context, currentData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailApar(BuildContext context, Map<String, dynamic> data) {
    String namaAlat =
        data['nama_alat'] ??
        data['nama_barang'] ??
        data['nama'] ??
        'Tanpa Nama Alat';
    String lokasi =
        data['lokasi'] ?? data['gedung_ruang'] ?? 'Lokasi tidak diketahui';
    String noApar = data['no_apar'] ?? data['nomor_apar'] ?? '-';
    String berat =
        data['berat']?.toString() ?? data['kapasitas']?.toString() ?? '-';
    dynamic tglKadaluarsa = data['tanggal_kadaluarsa'] ?? data['exp_date'];
    String keterangan =
        data['keterangan'] ?? data['catatan'] ?? 'Tidak ada keterangan';

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
                  namaAlat,
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
                    Expanded(child: Text(lokasi)),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                _buildInfoRow('No APAR', noApar),
                _buildInfoRow('Berat', '$berat Kg'),
                _buildInfoRow('Tanggal Kadaluarsa', _formatDate(tglKadaluarsa)),
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
                Text(keterangan),
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

  Widget _buildChecklistItem(String title, dynamic value) {
    bool isTrue = value == true || value.toString().toLowerCase() == 'true';
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
