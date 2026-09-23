import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManajemenKategoriScreen extends StatelessWidget {
  const ManajemenKategoriScreen({super.key});

  // Fungsi Keamanan Ganda (Safety Guard) Sebelum Menghapus Kategori
  Future<void> _hapusKategoriSafely(
    BuildContext context,
    String docId,
    String namaKategori,
  ) async {
    // 1. Cek apakah koleksi barang tersebut masih ada isinya di Firestore
    var querySnapshot = await FirebaseFirestore.instance
        .collection(namaKategori)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Jika masih ada isinya, BLOKIR penghapusan!
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Tidak Dapat Dihapus',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Kategori "$namaKategori" masih memuat ${querySnapshot.docs.length} data barang.\n\nHarap kosongkan atau hapus semua barang di dalam kategori ini terlebih dahulu demi keamanan data.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Mengerti',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      // 2. Jika benar-benar kosong (0 item), munculkan konfirmasi hapus blueprint
      if (!context.mounted) return;
      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Blueprint Kategori?'),
          content: Text(
            'Kategori "$namaKategori" kosong dan akan dihapus permanen dari master.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Hapus blueprint dari koleksi Master_Kategori
        await FirebaseFirestore.instance
            .collection('Master_Kategori')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kategori berhasil dihapus!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Manajemen Kategori',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Master_Kategori')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada kategori dinamis yang dibuat.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String namaKategori = data['nama_kategori'] ?? 'Tanpa Nama';
              String docId = docs[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.folder_special,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  title: Text(
                    namaKategori,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3460),
                    ),
                  ),
                  subtitle: const Text('Kategori Dinamis CMS (Blueprint)'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    tooltip: 'Hapus Kategori',
                    onPressed: () =>
                        _hapusKategoriSafely(context, docId, namaKategori),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
