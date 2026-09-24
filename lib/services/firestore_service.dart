import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- FUNGSI MENGAMBIL DATA (STREAM) ---
  Stream<QuerySnapshot> getBarangByKategori(String kategori) {
    return _db.collection(kategori).snapshots();
  }

  // Tambahan agar kompatibel dengan pemanggilan stream di file baru
  Stream<QuerySnapshot> getBarangStream(String kategori) {
    return _db.collection(kategori).snapshots();
  }

  // Fungsi pencatat Log Aktivitas
  Future<void> catatLogAktivitas({
    required String tipeAksi, // Contoh: "TAMBAH", "EDIT", "HAPUS"
    required String kategori, // Contoh: "APAR", "Kotak P3K"
    required String detail, // Contoh: "Menambahkan APAR No 43"
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String namaPetugas = "Sistem / Unknown";
      String uidUser = "unknown";

      if (currentUser != null) {
        uidUser = currentUser.uid;

        // 1. Jadikan Email sebagai nama default jika profil tidak ditemukan
        namaPetugas = currentUser.email ?? "Admin";

        // 2. Coba cari nama aslinya di collection Users
        var userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(uidUser)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          var data = userDoc.data()!;
          if (data['nama'] != null &&
              data['nama'].toString().trim().isNotEmpty) {
            namaPetugas = data['nama']; // Timpa dengan nama asli jika ada
          }
        }
      }

      // Tembak data ke Log
      await FirebaseFirestore.instance.collection('Activity_Logs').add({
        'uid_user': uidUser,
        'nama_user': namaPetugas,
        'tipe_aksi': tipeAksi,
        'kategori': kategori,
        'detail': detail,
        'waktu': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal mencatat log: $e');
    }
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

  // --- FUNGSI EDIT DATA ---
  Future<void> editBarang(
    String koleksi,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection(koleksi).doc(docId).update(data);
    } catch (e) {
      throw Exception('Gagal mengupdate data: $e');
    }
  }

  // --- FUNGSI SIMPAN INSPEKSI & UPDATE DEFISIT P3K ---
  Future<void> simpanInspeksi({
    required String docIdBarang,
    required String namaBarang,
    required String namaPemeriksa,
    required Map<String, dynamic> hasilChecklist,
    required String catatan,
  }) async {
    try {
      // 1. Simpan riwayat ke koleksi riwayat_inspeksi
      await _db.collection('riwayat_inspeksi').add({
        'doc_id_barang': docIdBarang,
        'nama_barang': namaBarang,
        'nama_pemeriksa': namaPemeriksa,
        'hasil_checklist': hasilChecklist,
        'catatan': catatan,
        'tanggal': FieldValue.serverTimestamp(),
      });

      // 2. Jika ada item P3K yang kurang/defisit, update secara real-time di database P3K
      bool isP3KData = hasilChecklist.values.any(
        (val) => val is int || (val is String && val.contains('/')),
      );
      if (isP3KData) {
        Map<String, int> defisitMap = {};
        hasilChecklist.forEach((key, value) {
          if (value is int && value > 0) {
            defisitMap[key] = value;
          }
        });

        await _db.collection('P3K').doc(docIdBarang).update({
          'defisit_p3k': defisitMap,
          'terakhir_inspeksi': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw 'Gagal menyimpan hasil inspeksi: $e';
    }
  }
}
