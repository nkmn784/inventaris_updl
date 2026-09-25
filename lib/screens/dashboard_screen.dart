import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Import Screen
import 'admin_panel_screen.dart';
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
import 'tambah_kategori_screen.dart';
import 'daftar_barang_dinamis_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  String _userName = 'Memuat...';
  bool _isAdmin = false;

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userName = data['nama'] ?? 'Petugas';
              _isAdmin = (data['role']?.toString().toLowerCase() == 'admin');
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userName = 'Admin (Legacy)';
              _isAdmin = true;
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching user: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      String query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _liveSearchResults = [];
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = true);
        _performLiveSearch(query);
      }
    });
  }

  Future<void> _performLiveSearch(String query) async {
    List<Map<String, dynamic>> results = [];
    String lowerQuery = query.toLowerCase();
    List<String> queryWords = lowerQuery.split(RegExp(r'\s+'));

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
                        setDialogState(
                          () => _selectedCategories[key] = value ?? true,
                        );
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(
                      () => _selectedCategories.updateAll((key, value) => true),
                    );
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
  // NOTIFIKASI STATUS MERAH (BOTTOM SHEET) DENGAN PENGURUTAN WAKTU
  // ====================================================================
  void _tampilkanNotifikasi() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
              'Peringatan (Status Merah)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<Widget>>(
                future: _generateSemuaPeringatan(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Gagal memuat data notifikasi.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  List<Widget> listPeringatan = snapshot.data ?? [];

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

  // HELPER UNTUK MENGAMBIL WAKTU TERAKHIR DATA DIUPDATE
  DateTime _getLatestDate(Map<String, dynamic> data) {
    List<String> dateFields = [
      'updated_at',
      'created_at',
      'tanggal_transaksi',
      'tanggal_pasang',
      'tanggal',
    ];
    for (String field in dateFields) {
      if (data[field] != null) {
        if (data[field] is Timestamp) {
          return (data[field] as Timestamp).toDate();
        } else if (data[field] is String) {
          try {
            return DateTime.parse(data[field]);
          } catch (_) {}
        }
      }
    }
    return DateTime(2000);
  }

  // MESIN PEMINDAI DATA STATIS & DINAMIS (DENGAN PENGURUTAN WAKTU)
  Future<List<Widget>> _generateSemuaPeringatan(BuildContext context) async {
    List<Map<String, dynamic>> listDataPeringatan = [];
    try {
      var statisSnapshots = await Future.wait([
        FirebaseFirestore.instance.collection('APAR').get(),
        FirebaseFirestore.instance.collection('Kotak P3K').get(),
        FirebaseFirestore.instance.collection('APD').get(),
        FirebaseFirestore.instance.collection('ATK').get(),
        FirebaseFirestore.instance.collection('Amenities').get(),
        FirebaseFirestore.instance.collection('Penerangan').get(),
      ]);

      var aparDocs = statisSnapshots[0].docs;
      var p3kDocs = statisSnapshots[1].docs;
      var apdDocs = statisSnapshots[2].docs;
      var atkDocs = statisSnapshots[3].docs;
      var amenitiesDocs = statisSnapshots[4].docs;
      var peneranganDocs = statisSnapshots[5].docs;

      // APAR
      for (var doc in aparDocs) {
        var data = doc.data() as Map<String, dynamic>;
        String status = data['keterangan'] ?? 'Tersedia';
        var spec = data['spesifikasi'] ?? {};
        String noApar = spec['No APAR'] ?? '-';

        String tglKadaluarsa = data['tanggal_kadaluarsa'] ?? '';
        bool isExpired = false;
        bool isAlmostExpired = false;
        if (tglKadaluarsa.isNotEmpty && tglKadaluarsa != '-') {
          try {
            List<String> parts = tglKadaluarsa.split('/');
            if (parts.length == 3) {
              DateTime expDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
              int diffDays = expDate.difference(DateTime.now()).inDays;
              if (diffDays < 0)
                isExpired = true;
              else if (diffDays <= 7)
                isAlmostExpired = true;
            }
          } catch (_) {}
        }
        if (status.toLowerCase() != 'tersedia' ||
            isExpired ||
            isAlmostExpired) {
          String notifTitle = 'APAR No. $noApar Bermasalah';
          String notifSubtitle =
              'Status: $status • Lokasi: ${data['lokasi'] ?? '-'}';
          Color iconColor = Colors.redAccent;
          IconData notifIcon = Icons.warning_amber_rounded;
          if (isExpired) {
            notifTitle = 'APAR No. $noApar KADALUARSA';
            notifSubtitle = 'Telah melewati batas tanggal kadaluarsa.';
            iconColor = Colors.red;
            notifIcon = Icons.error_outline;
          } else if (isAlmostExpired) {
            notifTitle = 'APAR No. $noApar HAMPIR KADALUARSA';
            notifSubtitle = 'Akan kadaluarsa dalam seminggu atau kurang.';
            iconColor = Colors.orange;
          }
          listDataPeringatan.add({
            'waktu': _getLatestDate(data),
            'widget': _buildNotifCard(
              context,
              icon: notifIcon,
              color: iconColor,
              title: notifTitle,
              subtitle: notifSubtitle,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailAparScreen(
                      docId: doc.id,
                      dataApar: data,
                      isAdmin: true,
                    ),
                  ),
                );
              },
            ),
          });
        }
      }

      // KOTAK P3K
      for (var doc in p3kDocs) {
        var data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> defisit = Map<String, dynamic>.from(
          data['defisit_p3k'] ?? {},
        );
        bool butuhIsiUlang = false;
        defisit.forEach((k, v) {
          if (v is int && v > 0) butuhIsiUlang = true;
        });
        Map<String, dynamic> expCairan = Map<String, dynamic>.from(
          data['kadaluarsa_cairan'] ?? {},
        );
        bool isExpired = false;
        bool isAlmostExpired = false;
        List<String> expiredItems = [];
        List<String> almostExpiredItems = [];
        expCairan.forEach((key, val) {
          if (val != null &&
              val.toString().isNotEmpty &&
              val.toString() != '-') {
            try {
              List<String> parts = val.toString().split('/');
              if (parts.length == 3) {
                DateTime expDate = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
                int diffDays = expDate.difference(DateTime.now()).inDays;
                if (diffDays < 0) {
                  isExpired = true;
                  expiredItems.add(key);
                } else if (diffDays <= 7) {
                  isAlmostExpired = true;
                  almostExpiredItems.add(key);
                }
              }
            } catch (_) {}
          }
        });
        if (butuhIsiUlang || isExpired || isAlmostExpired) {
          String notifTitle =
              '${data['nama_barang'] ?? 'Kotak P3K'} Butuh Isi Ulang';
          String notifSubtitle =
              'Lokasi: ${data['lokasi'] ?? '-'} • Item P3K kurang.';
          Color iconColor = Colors.orange;
          IconData notifIcon = Icons.medical_services;
          if (isExpired) {
            notifTitle = 'Cairan P3K KADALUARSA';
            notifSubtitle = 'Item kadaluarsa: ${expiredItems.join(', ')}';
            iconColor = Colors.red;
            notifIcon = Icons.warning_amber_rounded;
          } else if (isAlmostExpired) {
            notifTitle = 'Cairan P3K HAMPIR KADALUARSA';
            notifSubtitle = 'Segera cek: ${almostExpiredItems.join(', ')}';
            iconColor = Colors.deepOrange;
          }
          listDataPeringatan.add({
            'waktu': _getLatestDate(data),
            'widget': _buildNotifCard(
              context,
              icon: notifIcon,
              color: iconColor,
              title: notifTitle,
              subtitle: notifSubtitle,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailP3kScreen(
                      docId: doc.id,
                      dataP3k: data,
                      isAdmin: true,
                    ),
                  ),
                );
              },
            ),
          });
        }
      }

      // APD
      for (var doc in apdDocs) {
        var data = doc.data() as Map<String, dynamic>;
        String kondisi = data['kondisi'] ?? 'Baik';
        if (kondisi.toLowerCase() != 'baik') {
          listDataPeringatan.add({
            'waktu': _getLatestDate(data),
            'widget': _buildNotifCard(
              context,
              icon: Icons.security,
              color: Colors.redAccent,
              title: '${data['peralatan'] ?? 'APD'} Rusak',
              subtitle: 'Kondisi: $kondisi',
              onTap: () {
                Navigator.pop(context);
                data['kategori'] = 'APD';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailBarangScreen(
                      documentId: doc.id,
                      dataBarang: data,
                    ),
                  ),
                );
              },
            ),
          });
        }
      }

      // ATK
      for (var doc in atkDocs) {
        var data = doc.data() as Map<String, dynamic>;
        int stok =
            int.tryParse(
              (data['sisa_jumlah'] ?? data['jumlah'] ?? 0).toString(),
            ) ??
            0;
        if (stok <= 0) {
          listDataPeringatan.add({
            'waktu': _getLatestDate(data),
            'widget': _buildNotifCard(
              context,
              icon: Icons.edit_document,
              color: Colors.redAccent,
              title: '${data['nama_barang'] ?? 'ATK'} Stok Habis',
              subtitle: 'Sisa Stok: 0 ${data['satuan'] ?? 'Pcs'}',
              onTap: () {
                Navigator.pop(context);
                data['kategori'] = 'ATK';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailBarangScreen(
                      documentId: doc.id,
                      dataBarang: data,
                    ),
                  ),
                );
              },
            ),
          });
        }
      }

      // AMENITIES
      for (var doc in amenitiesDocs) {
        var data = doc.data() as Map<String, dynamic>;
        int stok =
            int.tryParse(
              (data['sisa_jumlah'] ?? data['jumlah'] ?? 0).toString(),
            ) ??
            0;
        if (stok <= 0) {
          listDataPeringatan.add({
            'waktu': _getLatestDate(data),
            'widget': _buildNotifCard(
              context,
              icon: Icons.spa,
              color: Colors.redAccent,
              title: '${data['nama_barang'] ?? 'Amenities'} Stok Habis',
              subtitle: 'Sisa Stok: 0 ${data['satuan'] ?? 'Pcs'}',
              onTap: () {
                Navigator.pop(context);
                data['kategori'] = 'Amenities';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailBarangScreen(
                      documentId: doc.id,
                      dataBarang: data,
                    ),
                  ),
                );
              },
            ),
          });
        }
      }

      // PENERANGAN
      for (var doc in peneranganDocs) {
        var data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'Normal';
        if (status.toLowerCase() != 'normal') {
          listDataPeringatan.add({
            'waktu': _getLatestDate(data),
            'widget': _buildNotifCard(
              context,
              icon: Icons.lightbulb,
              color: Colors.redAccent,
              title:
                  'Lampu ${data['kode_unik'] ?? '-'} (${status.toUpperCase()})',
              subtitle: 'Lokasi: ${data['gedung_ruangan'] ?? '-'}',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPeneranganScreen(
                      item: PeneranganModel.fromFirestore(data, doc.id),
                    ),
                  ),
                );
              },
            ),
          });
        }
      }

      // 2. PEMINDAI KATEGORI DINAMIS
      QuerySnapshot masterKategori = await FirebaseFirestore.instance
          .collection('Master_Kategori')
          .get();

      for (var katDoc in masterKategori.docs) {
        var katData = katDoc.data() as Map<String, dynamic>;
        String namaKategori = katData['nama_kategori'] ?? '';
        List<dynamic> skema = katData['skema_form'] ?? [];
        if (namaKategori.isEmpty) continue;

        QuerySnapshot itemSnap = await FirebaseFirestore.instance
            .collection(namaKategori)
            .get();
        for (var doc in itemSnap.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String docId = doc.id;

          String? statusBermasalah;
          String judulItem = 'Data $namaKategori';
          if (skema.isNotEmpty) {
            String labelPertama = skema[0]['label'];
            judulItem = data[labelPertama]?.toString() ?? judulItem;
          }

          data.forEach((key, value) {
            String keyLower = key.toLowerCase();
            if (keyLower.contains('status') || keyLower.contains('kondisi')) {
              String valLower = value.toString().toLowerCase();
              if (valLower.contains('rusak') ||
                  valLower.contains('perbaikan') ||
                  valLower.contains('hilang') ||
                  valLower.contains('kritis') ||
                  valLower.contains('mati')) {
                statusBermasalah = value.toString();
              }
            }
          });

          if (statusBermasalah != null) {
            listDataPeringatan.add({
              'waktu': _getLatestDate(data),
              'widget': _buildNotifCard(
                context,
                icon: Icons.inventory,
                color: Colors.orange.shade900,
                title: '$judulItem Bermasalah',
                subtitle: 'Kategori: $namaKategori • Status: $statusBermasalah',
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
              ),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error generating notifications: $e');
    }

    // === PENGURUTAN (YANG TERBARU DI ATAS) ===
    listDataPeringatan.sort((a, b) {
      DateTime waktuA = a['waktu'] as DateTime;
      DateTime waktuB = b['waktu'] as DateTime;
      return waktuB.compareTo(waktuA);
    });

    List<Widget> hasilAkhir = listDataPeringatan
        .map((e) => e['widget'] as Widget)
        .toList();
    return hasilAkhir;
  }

  // WIDGET HELPER KARTU NOTIFIKASI
  Widget _buildNotifCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
        actions: [
          if (_isAdmin)
            IconButton(
              tooltip: 'Panel Admin',
              icon: const Icon(Icons.settings_suggest),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),
        ],
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
                  'Selamat Datang, $_userName',
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
          // SEARCH BAR & DROPDOWN
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
                if (_searchController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
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
                                  if (kategori == 'Penerangan') {
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Master_Kategori')
                  .snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> semuaKategori = List.from(
                  _kategoriList,
                );

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  Map<String, IconData> kamusIcon = {
                    'Kotak Barang': Icons.inventory_2,
                    'Ruangan / Gedung': Icons.apartment,
                    'Kendaraan / Mobil': Icons.directions_car,
                    'Komputer / Elektronik': Icons.computer,
                    'Mesin / Listrik': Icons.electrical_services,
                    'Peralatan / Kunci': Icons.build,
                    'Dokumen / Arsip': Icons.folder_special,
                    'Kesehatan / Medis': Icons.medical_services,
                    'inventory_2': Icons.inventory_2,
                  };

                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String namaIconDisimpan = data['icon']?.toString() ?? '';
                    IconData iconFinal =
                        kamusIcon[namaIconDisimpan] ?? Icons.extension;

                    semuaKategori.add({
                      'nama': data['nama_kategori'] ?? 'Kategori Baru',
                      'icon': iconFinal,
                      'is_dinamis': true,
                      'skema_form': data['skema_form'],
                    });
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: semuaKategori.length,
                  itemBuilder: (context, index) {
                    final item = semuaKategori[index];
                    String namaKoleksi = item['nama'] == 'P3K'
                        ? 'Kotak P3K'
                        : item['nama'];

                    return FutureBuilder<AggregateQuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection(namaKoleksi)
                          .count()
                          .get(),
                      builder: (context, countSnapshot) {
                        if (countSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildKategoriCard(context, item, -1);
                        }
                        if (countSnapshot.hasError) {
                          return _buildKategoriCard(context, item, 0);
                        }
                        int totalRealTime = countSnapshot.data?.count ?? 0;
                        return _buildKategoriCard(context, item, totalRealTime);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_box),
              label: const Text('Buat Kategori'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TambahKategoriScreen(),
                  ),
                );
              },
            )
          : null,
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
            if (item['is_dinamis'] == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DaftarBarangDinamisScreen(
                    namaKategori: item['nama'],
                    skemaForm: item['skema_form'],
                  ),
                ),
              );
            } else if (item['nama'] == 'APAR') {
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
                  total == -1 ? 'Memuat...' : '$total items total',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
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
