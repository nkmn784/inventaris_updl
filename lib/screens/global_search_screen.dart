import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORT SEMUA HALAMAN DETAIL ---
import 'detail_barang_screen.dart';
import 'apar_screen.dart';
import 'p3k_screen.dart';
import 'detail_penerangan_screen.dart';
import '../models/penerangan_model.dart';

class GlobalSearchScreen extends StatefulWidget {
  final String searchQuery;

  const GlobalSearchScreen({super.key, required this.searchQuery});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    // 1. Bersihkan spasi berlebih dan pisahkan kata kunci
    String query = widget.searchQuery.toLowerCase().trim();
    List<String> queryWords = query.split(RegExp(r'\s+'));

    List<Map<String, dynamic>> results = [];

    List<String> collections = [
      'APAR',
      'Kotak P3K',
      'APD',
      'ATK',
      'Amenities',
      'Penerangan',
    ];

    try {
      for (String col in collections) {
        QuerySnapshot snap = await FirebaseFirestore.instance
            .collection(col)
            .get();

        for (var doc in snap.docs) {
          var data = doc.data() as Map<String, dynamic>;

          String nama =
              data['nama_barang'] ??
              data['peralatan'] ??
              data['nama_apd'] ??
              data['nama_atk'] ??
              data['nama_alat'] ??
              data['nama'] ??
              data['gedung_ruangan'] ??
              '';

          String lokasi = data['lokasi'] ?? data['lokasi_spesifik'] ?? '';

          String kode = data['kode_unik'] ?? '';
          String spesifikasiStr = '';
          if (data['spesifikasi'] != null && data['spesifikasi'] is Map) {
            spesifikasiStr = (data['spesifikasi'] as Map).values.join(' ');
          }

          // 2. Tambahkan variabel 'col' (kategori) ke dalam string pencarian
          String searchString = '$col $nama $lokasi $kode $spesifikasiStr'
              .toLowerCase();

          // 3. Pencarian Fleksibel (Semua kata yang diketik harus ada di string pencarian)
          bool isMatch = true;
          for (String word in queryWords) {
            if (!searchString.contains(word)) {
              isMatch = false;
              break;
            }
          }

          if (isMatch) {
            data['kategori_sumber'] = col;
            data['doc_id'] = doc.id;
            results.add(data);
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching: $e');
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  // Menentukan Ikon Bawaan Jika Foto Tidak Ada
  IconData _getIconForCategory(String kategori) {
    if (kategori == 'APAR') return Icons.fire_extinguisher;
    if (kategori == 'Kotak P3K') return Icons.medical_services;
    if (kategori == 'Penerangan') return Icons.lightbulb_outline;
    if (kategori == 'APD') return Icons.health_and_safety;
    if (kategori == 'ATK') return Icons.edit_note;
    if (kategori == 'Amenities') return Icons.spa;
    return Icons.inventory_2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: Text(
          'Hasil Pencarian: "${widget.searchQuery}"',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak menemukan "${widget.searchQuery}" di semua kategori.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                var data = _searchResults[index];
                String kategori = data['kategori_sumber'];
                String docId = data['doc_id'];

                // 1. Ambil Data Nama & Lokasi
                String namaBarang =
                    data['nama_barang'] ??
                    data['peralatan'] ??
                    data['nama_apd'] ??
                    data['nama_atk'] ??
                    data['nama_alat'] ??
                    data['nama'] ??
                    data['gedung_ruangan'] ??
                    'Tanpa Nama';
                String lokasi =
                    data['lokasi'] ?? data['lokasi_spesifik'] ?? '-';
                String? imageUrl = data['image_url'] ?? data['foto_url'];

                // 2. Format Penamaan Khusus (APAR, P3K, Penerangan)
                var spec = data['spesifikasi'] ?? {};
                if (kategori == 'APAR' && spec['No APAR'] != null) {
                  namaBarang = 'APAR No. ${spec['No APAR']} ($namaBarang)';
                } else if (kategori == 'Kotak P3K' && spec['No P3K'] != null) {
                  namaBarang = 'Kotak P3K No. ${spec['No P3K']} ($namaBarang)';
                } else if (kategori == 'Penerangan' &&
                    data['kode_unik'] != null) {
                  namaBarang = 'Lampu ${data['kode_unik']} ($namaBarang)';
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade100),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    // 3. LOGIKA FOTO & IKON YANG DISAMAKAN
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            (imageUrl != null &&
                                imageUrl.toString().trim().isNotEmpty)
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      _getIconForCategory(kategori),
                                      color: Colors.blue.shade700,
                                    ),
                              )
                            : Icon(
                                _getIconForCategory(kategori),
                                color: Colors.blue.shade700,
                              ),
                      ),
                    ),
                    title: Text(
                      namaBarang,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Kategori: $kategori',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Lokasi: $lokasi',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    onTap: () {
                      // 4. LOGIKA ROUTING HALAMAN DETAIL SESUAI KATEGORI
                      try {
                        if (kategori == 'APAR') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailAparScreen(
                                docId: docId,
                                dataApar: data,
                                isAdmin: true,
                              ),
                            ),
                          );
                        } else if (kategori == 'Kotak P3K') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailP3kScreen(
                                docId: docId,
                                dataP3k: data,
                                isAdmin: true,
                              ),
                            ),
                          );
                        } else if (kategori == 'Penerangan') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPeneranganScreen(
                                item: PeneranganModel.fromFirestore(
                                  data,
                                  docId,
                                ),
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailBarangScreen(
                                documentId: docId,
                                dataBarang: data,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tidak dapat membuka detail alat ini.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
