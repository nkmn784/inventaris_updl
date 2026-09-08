import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- FUNGSI MENGAMBIL DATA (STREAM) ---
  Stream<QuerySnapshot> getBarangByKategori(String kategori) {
    return _db.collection(kategori).snapshots();
  }

  // --- FUNGSI TAMBAH DATA ---
  Future<void> tambahBarang(String kategori, Map<String, dynamic> data) async {
    try {
      await _db.collection(kategori).add(data);
    } catch (e) {
      throw 'Gagal menambah data: $e';
    }
  }

  // --- FUNGSI UPDATE DATA ---
  Future<void> updateBarang(
    String kategori,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection(kategori).doc(docId).update(data);
    } catch (e) {
      throw 'Gagal mengupdate data: $e';
    }
  }

  // --- FUNGSI HAPUS DATA ---
  Future<void> hapusBarang(String kategori, String docId) async {
    try {
      await _db.collection(kategori).doc(docId).delete();
    } catch (e) {
      throw 'Gagal menghapus data: $e';
    }
  }
}
