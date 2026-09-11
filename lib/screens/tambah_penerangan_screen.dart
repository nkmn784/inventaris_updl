import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// Import model dan service milik Anda
import '../models/penerangan_model.dart';
import '../services/firestore_service.dart';

class TambahPeneranganScreen extends StatefulWidget {
  const TambahPeneranganScreen({super.key});

  @override
  State<TambahPeneranganScreen> createState() => _TambahPeneranganScreenState();
}

class _TambahPeneranganScreenState extends State<TambahPeneranganScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk input teks
  final TextEditingController _gedungCtrl = TextEditingController();
  final TextEditingController _lokasiSpesifikCtrl = TextEditingController();
  final TextEditingController _merkCtrl = TextEditingController();
  final TextEditingController _wattCtrl = TextEditingController();
  final TextEditingController _petugasCtrl = TextEditingController();
  final TextEditingController _catatanCtrl = TextEditingController();

  String _jenisLampuTerpilih = 'LED Bulb';
  final List<String> _listJenisLampu = [
    'LED Bulb',
    'Neon / TL',
    'Downlight',
    'Halogen',
    'Lampu Jalan (PJU)',
  ];

  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void dispose() {
    _gedungCtrl.dispose();
    _lokasiSpesifikCtrl.dispose();
    _merkCtrl.dispose();
    _wattCtrl.dispose();
    _petugasCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  // Fungsi untuk Generate Kode Unik (4 Karakter Alfanumerik)
  String _generateKodeUnik() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  // Fungsi untuk mendapatkan koordinat GPS saat ini
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Layanan lokasi (GPS) tidak aktif. Mohon nyalakan GPS Anda.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Buka pengaturan HP.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapat lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  // Fungsi untuk menyimpan data ke Firestore menggunakan Model dan Service
  Future<void> _simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap ambil titik koordinat (GPS) terlebih dahulu!'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String kodeUnik = _generateKodeUnik();

    try {
      // Memasukkan data ke dalam Model
      PeneranganModel dataBaru = PeneranganModel(
        kategori: 'Penerangan',
        gedungRuangan: _gedungCtrl.text.trim(),
        lokasiSpesifik: _lokasiSpesifikCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        merkLampu: _merkCtrl.text.trim(),
        jenisLampu: _jenisLampuTerpilih,
        watt: int.tryParse(_wattCtrl.text) ?? 0,
        kodeUnik: kodeUnik,
        status: 'Normal',
        petugasPasang: _petugasCtrl.text.trim(),
        tanggalPasang: DateTime.now().toIso8601String(),
        catatan: _catatanCtrl.text.trim(),
        riwayatPergantian: [], // Kosong saat baru dipasang
      );

      // Konversi model ke Map (JSON)
      Map<String, dynamic> dataMap = dataBaru.toFirestore();

      // Menyimpan ke database menggunakan fungsi dari firestore_service.dart
      await FirestoreService().tambahBarang('Penerangan', dataMap);

      if (mounted) {
        setState(() => _isLoading = false);
        _tampilkanDialogSukses(kodeUnik);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  // Menampilkan peringatan WAJIB TULIS SPIDOL
  void _tampilkanDialogSukses(String kodeUnik) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Berhasil & Wajib Dilakukan!',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data titik lampu berhasil disimpan.'),
            const SizedBox(height: 12),
            const Text(
              'SEBELUM MEMASANG LAMPU, TULIS KODE INI PADA BODY LAMPU MENGGUNAKAN SPIDOL PERMANEN:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: Text(
                  kodeUnik,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.0,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text(
              'SAYA SUDAH MENULISNYA',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Titik Penerangan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Lokasi Pemasangan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gedungCtrl,
                decoration: const InputDecoration(
                  labelText: 'Gedung / Ruangan (Misal: Gedung A Lt. 1)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lokasiSpesifikCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Spesifik (Misal: Plafon Lorong Toilet)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.my_location),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Bagian Koordinat GPS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Titik Koordinat (GPS):',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _latitude != null
                                ? 'Lat: $_latitude\nLon: $_longitude'
                                : 'Koordinat belum diambil',
                            style: TextStyle(
                              color: _latitude != null
                                  ? Colors.green.shade700
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.gps_fixed),
                      label: const Text('Ambil GPS'),
                      onPressed: _isGettingLocation
                          ? null
                          : _getCurrentLocation,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                '2. Spesifikasi Lampu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _merkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Merk Lampu (Misal: Philips)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lightbulb_outline),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _jenisLampuTerpilih,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Lampu',
                        border: OutlineInputBorder(),
                      ),
                      items: _listJenisLampu
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _jenisLampuTerpilih = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _wattCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Watt',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Isi' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                '3. Informasi Pemasangan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _petugasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Petugas Pemasang',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _catatanCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan Tambahan (Opsional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan & Generate Kode',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
