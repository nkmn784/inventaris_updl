import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/penerangan_model.dart';
import '../services/firestore_service.dart';
import 'edit_penerangan_screen.dart';

class DetailPeneranganScreen extends StatefulWidget {
  final PeneranganModel item;

  const DetailPeneranganScreen({super.key, required this.item});

  @override
  State<DetailPeneranganScreen> createState() => _DetailPeneranganScreenState();
}

class _DetailPeneranganScreenState extends State<DetailPeneranganScreen> {
  late List<dynamic> _riwayatList;

  @override
  void initState() {
    super.initState();
    _riwayatList = List.from(widget.item.riwayatPergantian ?? []);
    _bersihkanRiwayatLamaOtomatis();
  }

  // Fungsi otomatis menghapus riwayat > 1 tahun (365 hari) dari Firestore dan memori lokal
  Future<void> _bersihkanRiwayatLamaOtomatis() async {
    if (_riwayatList.isEmpty) return;

    DateTime batasWaktu = DateTime.now().subtract(const Duration(days: 365));

    List<dynamic> riwayatTerbaru = _riwayatList.where((element) {
      final data = element as Map<String, dynamic>;
      String tglStr = data['tanggal'] ?? data['tanggalGanti'] ?? '';
      DateTime? parsedDate = DateTime.tryParse(tglStr);

      if (parsedDate == null) return true;
      return parsedDate.isAfter(batasWaktu);
    }).toList();

    if (riwayatTerbaru.length != _riwayatList.length) {
      setState(() {
        _riwayatList = riwayatTerbaru;
      });

      try {
        await FirestoreService().editBarang('Penerangan', widget.item.id!, {
          'riwayat_pergantian': riwayatTerbaru,
        });
      } catch (e) {
        debugPrint('Gagal membersihkan riwayat otomatis di Firestore: $e');
      }
    }
  }

  Future<void> _bukaPeta(BuildContext context, double? lat, double? lng) async {
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat GPS tidak valid / tidak ditemukan.'),
        ),
      );
      return;
    }

    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka peta: $e')));
      }
    }
  }

  void _konfirmasiHapus(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Titik Lampu?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Yakin ingin menghapus titik lampu di ${widget.item.lokasiSpesifik}? Data yang dihapus tidak dapat dikembalikan.',
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
              try {
                await FirestoreService().hapusBarang(
                  'Penerangan',
                  widget.item.id!,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'mati':
      case 'rusak':
        return Colors.red;
      case 'hilang':
      case 'fraud':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.item.status ?? 'Normal';
    Color statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Detail Titik Penerangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _konfirmasiHapus(context),
            tooltip: 'Hapus Data',
          ),
        ],
      ),
      // Tombol dipindah ke bawah agar selalu menempel (sticky)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditPeneranganScreen(item: widget.item),
                  ),
                );

                if (result == true && context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.build_circle_outlined, size: 24),
              label: const Text(
                'LAPORKAN & GANTI LAMPU',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Kode Unik & Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'KODE UNIK LAMPU',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.kodeUnik ?? '-',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6.0,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Status: ${status.toUpperCase()}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Informasi Lokasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3460),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.business,
                    'Gedung / Ruangan',
                    widget.item.gedungRuangan,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.my_location,
                    'Lokasi Spesifik',
                    widget.item.lokasiSpesifik,
                  ),
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Titik Koordinat (GPS)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.item.latitude}, ${widget.item.longitude}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _bukaPeta(
                          context,
                          widget.item.latitude,
                          widget.item.longitude,
                        ),
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('Buka Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Spesifikasi & Pemasangan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3460),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.lightbulb_outline,
                    'Merk & Jenis',
                    '${widget.item.merkLampu} - ${widget.item.jenisLampu}',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.bolt,
                    'Daya Listrik',
                    '${widget.item.watt} Watt',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.person_outline,
                    'Petugas Pasang',
                    widget.item.petugasPasang,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.notes,
                    'Catatan',
                    widget.item.catatan?.isEmpty ?? true
                        ? 'Tidak ada catatan'
                        : widget.item.catatan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- BAGIAN RIWAYAT PERGANTIAN ---
            const Text(
              'Riwayat Pemeliharaan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F3460),
              ),
            ),
            const SizedBox(height: 8),
            _buildRiwayatList(),
            const SizedBox(
              height: 20,
            ), // Spasi aman di bagian bawah agar tidak tertutup tombol sticky
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatList() {
    if (_riwayatList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Belum ada riwayat pemeliharaan dalam 1 tahun terakhir.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    List<dynamic> riwayat = List.from(_riwayatList.reversed);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: riwayat.length,
      itemBuilder: (context, index) {
        final data = riwayat[index] as Map<String, dynamic>;

        bool isGantiBaru =
            data['tindakan'] == 'Ganti Bohlam Baru' || data['kodeLama'] != null;

        String tgl = data['tanggal'] ?? data['tanggalGanti'] ?? '-';
        if (tgl.length > 10) tgl = tgl.substring(0, 10);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border(
              left: BorderSide(
                color: isGantiBaru
                    ? Colors.blue.shade700
                    : Colors.orange.shade700,
                width: 5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isGantiBaru
                          ? Colors.blue.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isGantiBaru ? 'GANTI BOHLAM' : 'UBAH STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isGantiBaru
                            ? Colors.blue.shade700
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                  Text(
                    tgl,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 16),
              Text(
                'Petugas: ${data['petugas'] ?? '-'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              if (data['statusBaru'] != null)
                Text(
                  'Status: ${data['statusBaru']}',
                  style: const TextStyle(fontSize: 13),
                ),
              if (data['kodeLampu'] != null)
                Text(
                  'Kode: ${data['kodeLampu']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              if (data['merkLampu'] != null || data['watt'] != null)
                Text(
                  'Spesifikasi: ${data['merkLampu'] ?? '-'} (${data['watt'] ?? '-'} Watt)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                    fontSize: 13,
                  ),
                ),
              if (data['catatan'] != null &&
                  data['catatan'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Catatan: ${data['catatan']}',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
