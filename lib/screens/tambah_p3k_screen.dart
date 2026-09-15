import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

class TambahP3kScreen extends StatefulWidget {
  const TambahP3kScreen({super.key});

  @override
  State<TambahP3kScreen> createState() => _TambahP3kScreenState();
}

class _TambahP3kScreenState extends State<TambahP3kScreen> {
  bool _isLoading = false;

  final _gedungRuangCtrl = TextEditingController();
  final _kapasitasCtrl = TextEditingController();
  final _keteranganP3kCtrl = TextEditingController();
  String _existingP3k = 'A';
  String _rekomendasiP3k = '1A';

  DateTime? _expAquades;
  DateTime? _expPovidon;
  DateTime? _expAlcohol;

  final Map<String, bool> _checklistP3k = {
    'Kasa Steril': true,
    'Perban (5cm)': true,
    'Perban (10cm)': true,
    'Plaster (1,25cm)': true,
    'Plaster Cepat': true,
    'Kapas': true,
    'Kain Segitiga': true,
    'Gunting': true,
    'Peniti': true,
    'Sarung Tangan Sekali Pakai': true,
    'Sarung Tangan Pasangan': true,
    'Masker': true,
    'Pinset': true,
    'Lampu Senter': true,
    'Gelas Cuci Mata': true,
    'Kantung Plastik Bersih': true,
    'Aquades (25ml)': true,
    'Povidon Iodine': true,
    'Alcohol 70%': true,
    'Buku Panduan P3K': true,
    'Buku Catatan': true,
    'Daftar Isi Kotak P3K': true,
  };

  String _latitude = '';
  String _longitude = '';
  bool _isGettingLocation = false;
  XFile? _foto;
  final ImagePicker _picker = ImagePicker();

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin lokasi ditolak';
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pilihFoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _foto = pickedFile);
    }
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime? initial) async {
    return await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  @override
  void dispose() {
    _gedungRuangCtrl.dispose();
    _kapasitasCtrl.dispose();
    _keteranganP3kCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Data Kotak P3K')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IDENTIFIKASI KOTAK P3K',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gedungRuangCtrl,
              decoration: const InputDecoration(
                labelText: 'Gedung / Ruang',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kapasitasCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kapasitas (Orang)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _existingP3k,
                    decoration: const InputDecoration(
                      labelText: 'Existing',
                      border: OutlineInputBorder(),
                    ),
                    items: ['A', 'B', 'C']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text('Tipe $e'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _existingP3k = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _rekomendasiP3k,
                    decoration: const InputDecoration(
                      labelText: 'Rekomendasi',
                      border: OutlineInputBorder(),
                    ),
                    items: ['1A', '1B', '1C']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _rekomendasiP3k = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'CHECKLIST KELENGKAPAN BARANG P3K',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._checklistP3k.keys.map((key) {
              return CheckboxListTile(
                dense: true,
                title: Text(key),
                value: _checklistP3k[key],
                onChanged: (val) => setState(() => _checklistP3k[key] = val!),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'TANGGAL KADALUARSA CAIRAN / OBAT P3K',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDateField(
              'Exp. Aquades (25ml)',
              _expAquades,
              (d) => setState(() => _expAquades = d),
            ),
            const SizedBox(height: 8),
            _buildDateField(
              'Exp. Povidon Iodine',
              _expPovidon,
              (d) => setState(() => _expPovidon = d),
            ),
            const SizedBox(height: 8),
            _buildDateField(
              'Exp. Alcohol 70%',
              _expAlcohol,
              (d) => setState(() => _expAlcohol = d),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keteranganP3kCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Keterangan Temuan / Kekurangan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildFotoWidget(),
            const SizedBox(height: 16),
            _buildLocationButton(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanData,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Data Kotak P3K',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime) onSelect,
  ) {
    return InkWell(
      onTap: () async {
        DateTime? res = await _selectDate(context, value);
        if (res != null) onSelect(res);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value == null
                  ? 'Pilih Tanggal'
                  : '${value.day}-${value.month}-${value.year}',
            ),
            const Icon(Icons.calendar_month, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.pin_drop),
      label: Text(
        _latitude.isEmpty
            ? 'Ambil Titik Koordinat GPS'
            : 'Lat: $_latitude, Lng: $_longitude',
      ),
      onPressed: _isGettingLocation ? null : _getCurrentLocation,
    );
  }

  Widget _buildFotoWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Dokumentasi:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _foto == null
              ? const Center(
                  child: Text(
                    'Belum ada foto',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(_foto!.path, fit: BoxFit.cover)
                      : Image.file(File(_foto!.path), fit: BoxFit.cover),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kamera'),
              onPressed: () => _pilihFoto(ImageSource.camera),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Galeri'),
              onPressed: () => _pilihFoto(ImageSource.gallery),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _simpanData() async {
    setState(() => _isLoading = true);
    try {
      String? fotoUrl;
      if (_foto != null) {
        final bytes = await _foto!.readAsBytes();
        fotoUrl = await CloudinaryService().uploadImageBytes(bytes);
      }

      Map<String, dynamic> dataSimpan = {
        'kategori': 'P3K',
        'gedung_ruang': _gedungRuangCtrl.text,
        'lokasi': _gedungRuangCtrl.text,
        'kapasitas': int.tryParse(_kapasitasCtrl.text) ?? 0,
        'existing': _existingP3k,
        'rekomendasi': _rekomendasiP3k,
        'checklist_items': _checklistP3k,
        'exp_aquades': _expAquades?.toIso8601String(),
        'exp_povidon': _expPovidon?.toIso8601String(),
        'exp_alcohol': _expAlcohol?.toIso8601String(),
        'keterangan': _keteranganP3kCtrl.text,
        'latitude': _latitude,
        'longitude': _longitude,
      };

      if (fotoUrl != null) dataSimpan['foto_url'] = fotoUrl;

      await FirestoreService().tambahBarang('P3K', dataSimpan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data P3K berhasil disimpan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
