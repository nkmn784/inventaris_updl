import 'package:flutter/material.dart';
import 'daftar_barang_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Simulasi data kategori (Nanti akan kita hubungkan ke Firestore)
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

  // Fungsi untuk memunculkan dialog Tambah / Edit Kategori
  void _tampilkanFormKategori({String? currentName, int? index}) {
    final TextEditingController controller = TextEditingController(
      text: currentName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          currentName == null ? 'Tambah Jenis Barang' : 'Edit Jenis Barang',
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nama Jenis Barang (Cth: APAR)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  if (currentName == null) {
                    // Tambah data baru
                    _kategoriList.add({
                      'nama': controller.text,
                      'total': 0,
                      'icon': Icons.inventory,
                    });
                  } else {
                    // Edit data
                    _kategoriList[index!]['nama'] = controller.text;
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Fungsi Hapus Kategori
  void _hapusKategori(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jenis Barang'),
        content: Text('Yakin ingin menghapus ${_kategoriList[index]['nama']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _kategoriList.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
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
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        title: const Text(
          'STOCKFLOW - Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Kembali ke halaman login
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Search Bar di atas
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade800,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.tune),
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

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // List Kategori Barang (Sesuai panel Dashboard di desain)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _kategoriList.length,
              itemBuilder: (context, index) {
                final item = _kategoriList[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item['icon'], color: Colors.blue.shade700),
                    ),
                    title: Text(
                      item['nama'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${item['total']} items total',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol Edit Jenis Barang
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _tampilkanFormKategori(
                            currentName: item['nama'],
                            index: index,
                          ),
                        ),
                        // Tombol Hapus Jenis Barang
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _hapusKategori(index),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    onTap: () {
                      // Berpindah ke Halaman Daftar Barang sesuai kategori yang diklik
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DaftarBarangScreen(namaKategori: item['nama']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Tombol Tambah Kategori di sudut kanan bawah
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        onPressed: () => _tampilkanFormKategori(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
