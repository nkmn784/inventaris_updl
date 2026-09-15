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

    // UBAH DI SINI: Mengubah dari 90 hari menjadi 365 hari (1 tahun)
    DateTime batasWaktu = DateTime.now().subtract(const Duration(days: 365));

    // Filter hanya yang usianya masih dalam 1 tahun terakhir (<= 365 hari)
    List<dynamic> riwayatTerbaru = _riwayatList.where((element) {
      final data = element as Map<String, dynamic>;
      String tglStr = data['tanggal'] ?? data['tanggalGanti'] ?? '';
      DateTime? parsedDate = DateTime.tryParse(tglStr);

      if (parsedDate == null)
        return true; // Pertahankan jika format tanggal tidak valid
      return parsedDate.isAfter(batasWaktu);
    }).toList();

    // Jika jumlah data berkurang (artinya ada yang kedaluwarsa dan dihapus)
    if (riwayatTerbaru.length != _riwayatList.length) {
      setState(() {
        _riwayatList = riwayatTerbaru;
      });

      // Update / hapus permanen data di database Firestore untuk menghemat penyimpanan
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
        title: const Text(
          'Hapus Titik Lampu?',
          style: TextStyle(color: Colors.red),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                    const SnackBar(content: Text('Data berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Detail Titik Penerangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _konfirmasiHapus(context),
            tooltip: 'Hapus Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      spreadRadius: 2,
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.kodeUnik ?? '-',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8.0,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.item.status?.toLowerCase() == 'normal'
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Status: ${widget.item.status?.toUpperCase() ?? '-'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Informasi Lokasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                            foregroundColor: Colors.blue.shade800,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Spesifikasi & Pemasangan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
            ),
            const SizedBox(height: 24),

            // --- BAGIAN RIWAYAT PERGANTIAN ---
            const Text(
              'Riwayat Pemeliharaan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildRiwayatList(),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
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
                icon: const Icon(Icons.build_circle_outlined, size: 28),
                label: const Text(
                  'LAPORKAN & GANTI LAMPU',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatList() {
    if (_riwayatList.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              // UBAH DI SINI: Mengubah teks keterangan dari 3 bulan menjadi 1 tahun
              'Belum ada riwayat pemeliharaan dalam 1 tahun terakhir.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Membalik urutan agar riwayat paling baru muncul di atas
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

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                            ? Colors.blue.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGantiBaru ? 'GANTI BOHLAM' : 'UBAH STATUS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isGantiBaru
                              ? Colors.blue.shade800
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (data['statusBaru'] != null)
                  Text('Status: ${data['statusBaru']}'),
                if (data['kodeLampu'] != null)
                  Text(
                    'Kode: ${data['kodeLampu']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                if (data['merkLampu'] != null || data['watt'] != null)
                  Text(
                    'Spesifikasi: ${data['merkLampu'] ?? '-'} (${data['watt'] ?? '-'} Watt)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
