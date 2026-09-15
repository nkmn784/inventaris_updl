import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import 'edit_p3k_screen.dart';

class DetailP3kScreen extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> dataBarang;

  const DetailP3kScreen({
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

  void _konfirmasiHapus(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data P3K'),
        content: const Text('Yakin hapus data P3K ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().hapusBarang('P3K', documentId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('P3K')
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail P3K')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail P3K')),
            body: const Center(
              child: Text('Data P3K telah dihapus atau tidak ditemukan.'),
            ),
          );
        }

        final currentData = snapshot.data!.data() as Map<String, dynamic>;
        Map<String, dynamic> items = Map<String, dynamic>.from(
          currentData['checklist_items'] ?? {},
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail P3K'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditP3kScreen(
                        documentId: documentId,
                        dataBarang: currentData,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _konfirmasiHapus(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gedung/Ruang: ${currentData['gedung_ruang'] ?? currentData['lokasi'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kapasitas: ${currentData['kapasitas'] ?? 0} Org',
                            ),
                            Text('Existing: ${currentData['existing'] ?? '-'}'),
                            Text(
                              'Rekomendasi: ${currentData['rekomendasi'] ?? '-'}',
                            ),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                                  e.value == true
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: e.value == true
                                      ? Colors.green
                                      : Colors.red,
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
                          _formatDate(currentData['exp_aquades']),
                        ),
                        _buildInfoRow(
                          'Povidon Iodine',
                          _formatDate(currentData['exp_povidon']),
                        ),
                        _buildInfoRow(
                          'Alcohol 70%',
                          _formatDate(currentData['exp_alcohol']),
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
                          'Keterangan / Temuan:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(currentData['keterangan'] ?? '-'),
                        const Divider(height: 24, thickness: 1),
                        _buildKoordinatWidget(context, currentData),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
}
