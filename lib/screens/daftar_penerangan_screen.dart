import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'detail_penerangan_screen.dart';
// TODO: Sesuaikan path import ini dengan struktur folder Anda
import '../models/penerangan_model.dart';
import '../services/firestore_service.dart';
import 'tambah_penerangan_screen.dart';

class DaftarPeneranganScreen extends StatefulWidget {
  const DaftarPeneranganScreen({super.key});

  @override
  State<DaftarPeneranganScreen> createState() => _DaftarPeneranganScreenState();
}

class _DaftarPeneranganScreenState extends State<DaftarPeneranganScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  // Mengatur warna indikator berdasarkan status lampu
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        title: const Text(
          'Daftar Titik Penerangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade800,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari lokasi atau kode unik...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // List Data dari Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getBarangByKategori('Penerangan'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Terjadi kesalahan saat memuat data.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final dataDocs = snapshot.data?.docs ?? [];

                if (dataDocs.isEmpty) {
                  return const Center(
                    child: Text('Belum ada data titik penerangan.'),
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
                      final lokasi = item.gedungRuangan?.toLowerCase() ?? '';
                      final spesifik = item.lokasiSpesifik?.toLowerCase() ?? '';
                      final kode = item.kodeUnik?.toLowerCase() ?? '';
                      return lokasi.contains(_searchQuery) ||
                          spesifik.contains(_searchQuery) ||
                          kode.contains(_searchQuery);
                    })
                    .toList();

                if (listPenerangan.isEmpty) {
                  return const Center(child: Text('Data tidak ditemukan.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listPenerangan.length,
                  itemBuilder: (context, index) {
                    final item = listPenerangan[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Navigasi ke Halaman Detail
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailPeneranganScreen(item: item),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon & Status Color
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    item.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.lightbulb,
                                  color: _getStatusColor(item.status),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Detail Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.gedungRuangan ??
                                          'Lokasi Tidak Diketahui',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.lokasiSpesifik ?? '-',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Kode: ${item.kodeUnik ?? '-'}',
                                            style: TextStyle(
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.merkLampu} ${item.watt}W',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
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
      ),
    );
  }
}
