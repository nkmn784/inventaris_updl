class PeneranganModel {
  String? id;
  String? kategori;
  String? gedungRuangan;
  String? lokasiSpesifik;
  double? latitude;
  double? longitude;
  String? merkLampu;
  String? jenisLampu;
  int? watt;
  String? kodeUnik;
  String? status;
  String? petugasPasang;
  String? tanggalPasang;
  String? catatan;
  List<dynamic>? riwayatPergantian;

  PeneranganModel({
    this.id,
    this.kategori,
    this.gedungRuangan,
    this.lokasiSpesifik,
    this.latitude,
    this.longitude,
    this.merkLampu,
    this.jenisLampu,
    this.watt,
    this.kodeUnik,
    this.status,
    this.petugasPasang,
    this.tanggalPasang,
    this.catatan,
    this.riwayatPergantian,
  });

  // Mengubah data dari Firestore menjadi Objek Dart
  factory PeneranganModel.fromFirestore(Map<String, dynamic> json, String id) {
    return PeneranganModel(
      id: id,
      kategori: json['kategori'] ?? '',
      gedungRuangan: json['gedung_ruangan'] ?? '',
      lokasiSpesifik: json['lokasi_spesifik'] ?? '',
      latitude: (json['latitude'] != null) ? json['latitude'].toDouble() : 0.0,
      longitude: (json['longitude'] != null)
          ? json['longitude'].toDouble()
          : 0.0,
      merkLampu: json['merk_lampu'] ?? '',
      jenisLampu: json['jenis_lampu'] ?? '',
      watt: json['watt'] ?? 0,
      kodeUnik: json['kode_unik'] ?? '',
      status: json['status'] ?? '',
      petugasPasang: json['petugas_pasang'] ?? '',
      tanggalPasang: json['tanggal_pasang'] ?? '',
      catatan: json['catatan'] ?? '',
      riwayatPergantian: json['riwayat_pergantian'] ?? [],
    );
  }

  // Mengubah Objek Dart menjadi data untuk dikirim ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'kategori': kategori,
      'gedung_ruangan': gedungRuangan,
      'lokasi_spesifik': lokasiSpesifik,
      'latitude': latitude,
      'longitude': longitude,
      'merk_lampu': merkLampu,
      'jenis_lampu': jenisLampu,
      'watt': watt,
      'kode_unik': kodeUnik,
      'status': status,
      'petugas_pasang': petugasPasang,
      'tanggal_pasang': tanggalPasang,
      'catatan': catatan,
      'riwayat_pergantian': riwayatPergantian,
    };
  }
}
