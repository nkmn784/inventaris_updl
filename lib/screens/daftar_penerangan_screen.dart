import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'detail_penerangan_screen.dart';
import '../models/penerangan_model.dart';
import '../services/firestore_service.dart';
import 'tambah_penerangan_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DaftarPeneranganScreen extends StatefulWidget {
  final bool isAdmin;
  const DaftarPeneranganScreen({super.key, this.isAdmin = false});

  @override
  State<DaftarPeneranganScreen> createState() => _DaftarPeneranganScreenState();
}

class _DaftarPeneranganScreenState extends State<DaftarPeneranganScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  late Stream<QuerySnapshot> _peneranganStream;
  bool _canAdd = false;

  @override
  void initState() {
    super.initState();
    _peneranganStream = _firestoreService.getBarangByKategori('Penerangan');
    _cekPerizinan();
  }

  Future<void> _cekPerizinan() async {
    if (widget.isAdmin) {
      setState(() => _canAdd = true);
      return;
    }
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          var data = doc.data()!;
          if (data['role'] == 'Admin') {
            setState(() => _canAdd = true);
          } else {
            var perms = data['permissions'] ?? {};
            setState(() => _canAdd = perms['can_add_item'] ?? false);
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
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
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: const Text(
          'Manajemen Titik Penerangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Header Gradient & Search Bar Dinamis ala AparScreen
          Container(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 30.0,
              top: 16.0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade600],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari lokasi, gedung, atau kode unik...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // List Data dari Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _peneranganStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Terjadi kesalahan saat memuat data.'),
                  );
                }

                final dataDocs = snapshot.data?.docs ?? [];

                if (dataDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada data titik penerangan.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Mapping dan Filtering data
                final List<PeneranganModel> listPenerangan = dataDocs
                    .map((doc) {
                      return PeneranganModel.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                    })
                    .where((item) {
                      final gedung = item.gedungRuangan?.toLowerCase() ?? '';
                      final spesifik = item.lokasiSpesifik?.toLowerCase() ?? '';
                      final kode = item.kodeUnik?.toLowerCase() ?? '';
                      final merk = item.merkLampu?.toLowerCase() ?? '';
                      return gedung.contains(_searchQuery) ||
                          spesifik.contains(_searchQuery) ||
                          kode.contains(_searchQuery) ||
                          merk.contains(_searchQuery);
                    })
                    .toList();

                // --- MENGURUTKAN SESUAI ABJAD (Berdasarkan Gedung/Ruangan) ---
                listPenerangan.sort((a, b) {
                  String namaA = (a.gedungRuangan ?? '').toLowerCase();
                  String namaB = (b.gedungRuangan ?? '').toLowerCase();
                  return namaA.compareTo(namaB);
                });
                // -------------------------------------------------------------

                if (listPenerangan.isEmpty) {
                  return const Center(
                    child: Text(
                      'Data tidak ditemukan.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: listPenerangan.length,
                  itemBuilder: (context, index) {
                    final item = listPenerangan[index];
                    final rawData =
                        dataDocs[index].data() as Map<String, dynamic>;
                    final status = item.status ?? 'Normal';
                    final statusColor = _getStatusColor(status);

                    // Pengecekan inspeksi bulan ini
                    bool sudahInspeksiBulanIni = false;
                    if (rawData['tanggal_inspeksi'] != null) {
                      DateTime? tglTerakhir;
                      if (rawData['tanggal_inspeksi'] is Timestamp) {
                        tglTerakhir = (rawData['tanggal_inspeksi'] as Timestamp)
                            .toDate();
                      } else {
                        tglTerakhir = DateTime.tryParse(
                          rawData['tanggal_inspeksi'].toString(),
                        );
                      }

                      if (tglTerakhir != null) {
                        DateTime now = DateTime.now();
                        if (tglTerakhir.month == now.month &&
                            tglTerakhir.year == now.year) {
                          sudahInspeksiBulanIni = true;
                        }
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                            color: Colors.blue.shade700,
                            width: 5,
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Navigasi ke Halaman Detail
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPeneranganScreen(
                                  item: item,
                                  isAdmin: widget.isAdmin,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Icon Lampu dengan Warna Dinamis Sesuai Status
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.lightbulb,
                                    color: statusColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 15),

                                // Detail Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.gedungRuangan ?? 'Ruangan'} (${item.kodeUnik ?? '-'})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lokasi: ${item.lokasiSpesifik ?? '-'}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.merkLampu ?? '-'} • ${item.watt ?? '-'}W',
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status Badges di sebelah kanan
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      width: 95,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      alignment: Alignment.center,
                                      width: 95,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sudahInspeksiBulanIni
                                            ? Colors.blue.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        sudahInspeksiBulanIni
                                            ? 'Sudah Inspeksi'
                                            : 'Belum Inspeksi',
                                        style: TextStyle(
                                          color: sudahInspeksiBulanIni
                                              ? Colors.blue.shade700
                                              : Colors.orange.shade900,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _canAdd
          ? FloatingActionButton(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TambahPeneranganScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
