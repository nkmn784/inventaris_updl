import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'daftar_barang_screen.dart';
import 'apar_screen.dart';
import 'daftar_penerangan_screen.dart';
import 'p3k_screen.dart';
import 'history_laporan_screen.dart';
import 'login_screen.dart';
import 'global_search_screen.dart';
import 'detail_barang_screen.dart';
import 'detail_penerangan_screen.dart';
import '../models/penerangan_model.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  // State untuk Filter Kategori (Default semuanya terpilih)
  final Map<String, bool> _selectedCategories = {
    'APAR': true,
    'Kotak P3K': true,
    'APD': true,
    'ATK': true,
    'Amenities': true,
    'Penerangan': true,
  };

  // State untuk Live Search Dropdown
  List<Map<String, dynamic>> _liveSearchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk menangani pencarian real-time (Live Search)
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false)
      _debounce!.cancel(); // Batalkan pencarian jika user masih ngetik

    // Set jeda 500 milidetik (setengah detik)
    _debounce = Timer(const Duration(milliseconds: 500), () {
      String query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _liveSearchResults = [];
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = true);
        _performLiveSearch(
          query,
        ); // Firebase HANYA dipanggil 1 kali setelah selesai ngetik!
      }
    });
  }

  // Mengambil data dari kategori yang dicentang saja
  Future<void> _performLiveSearch(String query) async {
    List<Map<String, dynamic>> results = [];
    String lowerQuery = query.toLowerCase();
    List<String> queryWords = lowerQuery.split(RegExp(r'\s+'));

    // Ambil hanya kategori yang dicentang oleh user di pop-up filter
    List<String> activeCollections = _selectedCategories.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    try {
      for (String col in activeCollections) {
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

          String searchString = '$col $nama $lokasi $kode $spesifikasiStr'
              .toLowerCase();

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
      debugPrint('Live Search Error: $e');
    }

    if (mounted && _searchController.text.trim().isNotEmpty) {
      setState(() {
        _liveSearchResults = results;
        _isSearching = false;
      });
    }
  }

  // --- POP-UP FILTER KATEGORI (IKON TUNE) ---
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Filter Kategori Pencarian',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _selectedCategories.keys.map((String key) {
                    return CheckboxListTile(
                      title: Text(key),
                      value: _selectedCategories[key],
                      activeColor: Colors.blue.shade800,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          _selectedCategories[key] = value ?? true;
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedCategories.updateAll((key, value) => true);
                    });
                    setState(() {});
                  },
                  child: const Text(
                    'Pilih Semua',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getIconForCategory(String kategori) {
    if (kategori == 'APAR') return Icons.fire_extinguisher;
    if (kategori == 'Kotak P3K') return Icons.medical_services;
    if (kategori == 'Penerangan') return Icons.lightbulb_outline;
    if (kategori == 'APD') return Icons.health_and_safety;
    if (kategori == 'ATK') return Icons.edit_note;
    if (kategori == 'Amenities') return Icons.spa;
    return Icons.inventory_2;
  }

  final List<Map<String, dynamic>> _kategoriList = [
    {'nama': 'APAR', 'total': 150, 'icon': Icons.fire_extinguisher},
    {'nama': 'P3K', 'total': 45, 'icon': Icons.medical_services},
    {'nama': 'APD', 'total': 200, 'icon': Icons.security},
    {'nama': 'ATK', 'total': 320, 'icon': Icons.folder_shared},
    {
      'nama': 'Amenities',
      'total': 85,
      'icon': Icons.cleaning_services_outlined,
    },
    {'nama': 'Penerangan', 'total': 60, 'icon': Icons.lightbulb_outline},
  ];

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() => _selectedIndex = index);
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryLaporanScreen()),
      );
    } else if (index == 2) {
      _tampilkanNotifikasi();
    } else if (index == 3) {
      _tampilkanDialogLogout();
    }
  }

  // ====================================================================
  // NOTIFIKASI STATUS MERAH SEMUA KATEGORI (APAR, P3K, APD, ATK, AMENITIES, PENERANGAN)
  // ====================================================================
  void _tampilkanNotifikasi() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notifikasi & Peringatan (Status Merah)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<QuerySnapshot>>(
                future: Future.wait([
                  FirebaseFirestore.instance.collection('APAR').get(),
                  FirebaseFirestore.instance.collection('Kotak P3K').get(),
                  FirebaseFirestore.instance.collection('APD').get(),
                  FirebaseFirestore.instance.collection('ATK').get(),
                  FirebaseFirestore.instance.collection('Amenities').get(),
                  FirebaseFirestore.instance.collection('Penerangan').get(),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Gagal memuat data notifikasi.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  var aparDocs = snapshot.data![0].docs;
                  var p3kDocs = snapshot.data![1].docs;
                  var apdDocs = snapshot.data![2].docs;
                  var atkDocs = snapshot.data![3].docs;
                  var amenitiesDocs = snapshot.data![4].docs;
                  var peneranganDocs = snapshot.data![5].docs;

                  List<Widget> listPeringatan = [];

                  // 1. APAR (Status != Tersedia)
                  for (var doc in aparDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String status = data['keterangan'] ?? 'Tersedia';
                    if (status.toLowerCase() != 'tersedia') {
                      var spec = data['spesifikasi'] ?? {};
                      String noApar = spec['No APAR'] ?? '-';
                      String docId = doc.id;
                      listPeringatan.add(
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade100.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context); // Tutup bottom sheet
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
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              'APAR No. $noApar Bermasalah',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              'Status: $status • Lokasi: ${data['lokasi'] ?? '-'}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  // 2. Kotak P3K (Defisit > 0)
                  for (var doc in p3kDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    Map<String, dynamic> defisit = Map<String, dynamic>.from(
                      data['defisit_p3k'] ?? {},
                    );
                    bool butuhIsiUlang = false;
                    defisit.forEach((k, v) {
                      if (v is int && v > 0) butuhIsiUlang = true;
                    });
                    if (butuhIsiUlang) {
                      String docId = doc.id;
                      listPeringatan.add(
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade100.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context);
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
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(
                                Icons.medical_services,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              '${data['nama_barang'] ?? 'Kotak P3K'} Butuh Isi Ulang',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            subtitle: Text(
                              'Lokasi: ${data['lokasi'] ?? '-'} • Item P3K kurang.',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  // 3. APD (Kondisi != Baik)
                  for (var doc in apdDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String kondisi = data['kondisi'] ?? 'Baik';
                    if (kondisi.toLowerCase() != 'baik') {
                      String docId = doc.id;
                      data['kategori'] = 'APD'; // Pastikan kategori terbaca
                      listPeringatan.add(
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade100.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailBarangScreen(
                                    documentId: docId,
                                    dataBarang: data,
                                  ),
                                ),
                              );
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              child: Icon(Icons.security, color: Colors.white),
                            ),
                            title: Text(
                              '${data['peralatan'] ?? 'APD'} Rusak / Bermasalah',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            subtitle: Text('Kondisi: $kondisi'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  // 4. ATK (Stok <= 0)
                  for (var doc in atkDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    int stok =
                        int.tryParse(
                          (data['sisa_jumlah'] ??
                                  data['jumlah'] ??
                                  data['stok_sekarang'] ??
                                  0)
                              .toString(),
                        ) ??
                        0;
                    if (stok <= 0) {
                      String docId = doc.id;
                      data['kategori'] = 'ATK'; // Pastikan kategori terbaca
                      listPeringatan.add(
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade100.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailBarangScreen(
                                    documentId: docId,
                                    dataBarang: data,
                                  ),
                                ),
                              );
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              child: Icon(
                                Icons.edit_document,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              '${data['nama_barang'] ?? 'ATK'} Stok Habis',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              'Sisa Stok: 0 ${data['satuan'] ?? 'Pcs'}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  // 5. Amenities (Stok <= 0)
                  for (var doc in amenitiesDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    int stok =
                        int.tryParse(
                          (data['sisa_jumlah'] ??
                                  data['jumlah'] ??
                                  data['stok_sekarang'] ??
                                  0)
                              .toString(),
                        ) ??
                        0;
                    if (stok <= 0) {
                      String docId = doc.id;
                      data['kategori'] =
                          'Amenities'; // Pastikan kategori terbaca
                      listPeringatan.add(
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade100.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailBarangScreen(
                                    documentId: docId,
                                    dataBarang: data,
                                  ),
                                ),
                              );
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              child: Icon(Icons.spa, color: Colors.white),
                            ),
                            title: Text(
                              '${data['nama_barang'] ?? 'Amenities'} Stok Habis',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              'Sisa Stok: 0 ${data['satuan'] ?? 'Pcs'}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  // 6. Penerangan (Status != Normal)
                  for (var doc in peneranganDocs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String status = data['status'] ?? 'Normal';
                    if (status.toLowerCase() != 'normal') {
                      String docId = doc.id;
                      listPeringatan.add(
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade100.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context);
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
                            },
                            leading: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              child: Icon(Icons.lightbulb, color: Colors.white),
                            ),
                            title: Text(
                              'Lampu ${data['kode_unik'] ?? '-'} (${status.toUpperCase()})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              'Lokasi: ${data['gedung_ruangan'] ?? '-'} - ${data['lokasi_spesifik'] ?? '-'}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  if (listPeringatan.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 60,
                            color: Colors.green,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada peringatan atau status merah!',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(children: listPeringatan);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tampilkanDialogLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLN UPDL INVENTORY',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade200,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CONTAINER SEARCH BAR + LIVE SEARCH DROPDOWN
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GlobalSearchScreen(searchQuery: value.trim()),
                        ),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari alat, no unik, atau lokasi...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                    suffixIcon: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      tooltip: 'Filter Kategori',
                      onPressed: _showFilterDialog,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                // --- KOTAK DROPDOWN LIVE SEARCH ---
                if (_searchController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : _liveSearchResults.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'Barang tidak ditemukan',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _liveSearchResults.length,
                            itemBuilder: (context, index) {
                              var item = _liveSearchResults[index];
                              String kategori = item['kategori_sumber'];
                              String docId = item['doc_id'];
                              String nama =
                                  item['nama_barang'] ??
                                  item['peralatan'] ??
                                  item['nama_apd'] ??
                                  item['nama_atk'] ??
                                  item['nama_alat'] ??
                                  item['nama'] ??
                                  item['gedung_ruangan'] ??
                                  'Tanpa Nama';
                              String lokasi =
                                  item['lokasi'] ??
                                  item['lokasi_spesifik'] ??
                                  '-';
                              String? imageUrl =
                                  item['image_url'] ?? item['foto_url'];

                              return ListTile(
                                dense: true,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      (imageUrl != null &&
                                          imageUrl.toString().isNotEmpty)
                                      ? Image.network(
                                          imageUrl,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            _getIconForCategory(kategori),
                                            color: Colors.blue,
                                          ),
                                        )
                                      : Icon(
                                          _getIconForCategory(kategori),
                                          color: Colors.blue,
                                        ),
                                ),
                                title: Text(
                                  nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  'Kategori: $kategori • Lokasi: $lokasi',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                ),
                                onTap: () {
                                  if (kategori == 'APAR') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailAparScreen(
                                          docId: docId,
                                          dataApar: item,
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
                                          dataP3k: item,
                                          isAdmin: true,
                                        ),
                                      ),
                                    );
                                  } else if (kategori == 'Penerangan') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailPeneranganScreen(
                                              item:
                                                  PeneranganModel.fromFirestore(
                                                    item,
                                                    docId,
                                                  ),
                                            ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailBarangScreen(
                                              documentId: docId,
                                              dataBarang: item,
                                            ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Icon(Icons.category_rounded, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Text(
                  'Kategori Barang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _kategoriList.length,
              itemBuilder: (context, index) {
                final item = _kategoriList[index];
                String namaKoleksi = item['nama'] == 'P3K'
                    ? 'Kotak P3K'
                    : item['nama'];

                return FutureBuilder<AggregateQuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection(namaKoleksi)
                      .count()
                      .get(), // Mengambil jumlah total dokumen saja secara efisien
                  builder: (context, snapshot) {
                    int totalRealTime = 0;
                    if (snapshot.hasData) {
                      totalRealTime = snapshot.data!.count ?? 0;
                    }
                    return _buildKategoriCard(context, item, totalRealTime);
                  },
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue.shade800,
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_rounded),
                label: 'Laporan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_rounded),
                label: 'Notifikasi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.logout_rounded),
                label: 'Logout',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKategoriCard(
    BuildContext context,
    Map<String, dynamic> item,
    int total,
  ) {
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
        border: Border(left: BorderSide(color: Colors.blue.shade700, width: 5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (item['nama'] == 'APAR') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AparScreen()),
              );
            } else if (item['nama'] == 'P3K') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const P3kScreen()),
              );
            } else if (item['nama'] == 'Penerangan') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DaftarPeneranganScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DaftarBarangScreen(namaKategori: item['nama']),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'],
                  color: Colors.blue.shade700,
                  size: 26,
                ),
              ),
              title: Text(
                item['nama'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade900,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$total items total',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
