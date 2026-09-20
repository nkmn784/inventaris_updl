import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'daftar_barang_screen.dart';
import 'apar_screen.dart';
import 'daftar_penerangan_screen.dart';
import 'p3k_screen.dart';
import 'history_laporan_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

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
      setState(() {
        _selectedIndex = index;
      });
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

  // ==========================================
  // NOTIFIKASI OTOMATIS BERDASARKAN STATUS ALAT
  // ==========================================
  // ==========================================
  // NOTIFIKASI OTOMATIS BERDASARKAN STATUS ALAT
  // ==========================================
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
              'Notifikasi & Peringatan Alat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('APAR')
                    .snapshots(),
                builder: (context, snapshotApar) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Kotak P3K')
                        .snapshots(),
                    builder: (context, snapshotP3k) {
                      List<Widget> listPeringatan = [];

                      // 1. Cek Temuan Masalah di APAR (selain Tersedia)
                      if (snapshotApar.hasData && snapshotApar.data != null) {
                        for (var doc in snapshotApar.data!.docs) {
                          // <-- DIPERBAIKI (menggunakan .data()!.docs)
                          var data = doc.data() as Map<String, dynamic>;
                          String status = data['keterangan'] ?? 'Tersedia';
                          var spec = data['spesifikasi'] ?? {};
                          String noApar = spec['No APAR'] ?? '-';

                          if (status.toLowerCase() != 'tersedia') {
                            // CONTOH UNTUK APAR (Terapkan gaya yang sama pada P3K di bawahnya)
                            listPeringatan.add(
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade100.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.blue.shade50,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red.shade50,
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    'APAR No. $noApar Bermasalah',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Lokasi: ${data['lokasi'] ?? '-'} • Status: $status',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      }

                      // 2. Cek Temuan Defisit / Butuh Isi Ulang di Kotak P3K
                      if (snapshotP3k.hasData && snapshotP3k.data != null) {
                        for (var doc in snapshotP3k.data!.docs) {
                          // <-- DIPERBAIKI (menggunakan .data()!.docs)
                          var data = doc.data() as Map<String, dynamic>;
                          Map<String, dynamic> defisit =
                              Map<String, dynamic>.from(
                                data['defisit_p3k'] ?? {},
                              );
                          bool butuhIsiUlang = false;
                          defisit.forEach((k, v) {
                            if (v is int && v > 0) butuhIsiUlang = true;
                          });

                          if (butuhIsiUlang) {
                            listPeringatan.add(
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade100.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.blue.shade50,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors
                                        .orange
                                        .shade50, // Disesuaikan agar lebih soft
                                    child: const Icon(
                                      Icons.medical_services,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  title: Text(
                                    '${data['nama_barang'] ?? 'Kotak P3K'} Butuh Isi Ulang',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors
                                          .blue
                                          .shade900, // Disamakan dengan APAR
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Lokasi: ${data['lokasi'] ?? '-'} • Item P3K ada yang kurang.',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: const Text(
                                    'Isi Ulang',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      }

                      if (listPeringatan.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 50,
                                color: Colors.green,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Semua alat aman dan tersedia!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView(children: listPeringatan);
                    },
                  );
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Tambahkan 'async' di sini
            onPressed: () async {
              // 1. Tutup popup dialog konfirmasi terlebih dahulu
              Navigator.pop(context);

              // 2. Hapus sesi login dari Firebase
              await FirebaseAuth.instance.signOut();

              // 3. Arahkan paksa kembali ke halaman Login
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
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
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
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

                // Sinkronisasi total item real-time untuk APAR dan P3K
                if (item['nama'] == 'APAR' || item['nama'] == 'P3K') {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(
                          item['nama'] == 'P3K' ? 'Kotak P3K' : 'APAR',
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      int totalRealTime = snapshot.hasData
                          ? snapshot.data!.docs.length
                          : 0;
                      return _buildKategoriCard(context, item, totalRealTime);
                    },
                  );
                }

                return _buildKategoriCard(context, item, item['total']);
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
