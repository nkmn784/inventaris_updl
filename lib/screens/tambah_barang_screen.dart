import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

class TambahBarangScreen extends StatefulWidget {
  const TambahBarangScreen({super.key});

  @override
  State<TambahBarangScreen> createState() => _TambahBarangScreenState();
}

class _TambahBarangScreenState extends State<TambahBarangScreen> {
  String _kategoriTerpilih = 'APAR';
  // PERBAIKAN: Mengubah 'AMENITIES' menjadi 'Amenities'
  final List<String> _listKategori = ['APAR', 'P3K', 'APD', 'ATK', 'Amenities'];
  bool _isLoading = false;

  // ==========================================
  // FORM FIELD APAR
  // ==========================================
  final _namaAlatCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _noAparCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _keteranganAparCtrl = TextEditingController();
  DateTime? _tanggalKadaluarsaApar;

  bool _kondisiLabel = true;
  bool _kondisiTekanan = true;
  bool _kondisiSafetyPin = true;
  bool _kondisiHandle = true;
  bool _kondisiSelang = true;

  // ==========================================
  // FORM FIELD P3K
  // ==========================================
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

  // ==========================================
  // FORM FIELD APD (PERALATAN K3)
  // ==========================================
  final _peralatanApdCtrl = TextEditingController();
  final _jumlahApdCtrl = TextEditingController();
  final _masaPakaiApdCtrl = TextEditingController();
  final _tglKadaluarsaApdCtrl = TextEditingController();
  final _kondisiApdCtrl = TextEditingController(text: 'Baik');
  final _pembelianApdCtrl = TextEditingController();

  // ==========================================
  // FORM FIELD ATK
  // ==========================================
  final _namaAtkCtrl = TextEditingController();
  final _jumlahAtkCtrl = TextEditingController();
  final _catatanAtkCtrl = TextEditingController();
  String _satuanAtkTerpilih = 'Pcs';
  final List<String> _listSatuanAtk = [
    'Pcs',
    'Rim',
    'Pak',
    'Box',
    'Lusin',
    'Buah',
  ];

  // ==========================================
  // FORM FIELD AMENITIES
  // ==========================================
  final _namaAmenitiesCtrl = TextEditingController();
  final _jumlahAmenitiesCtrl = TextEditingController();
  final _catatanAmenitiesCtrl = TextEditingController();
  String _satuanAmenitiesTerpilih = 'Pcs';
  final List<String> _listSatuanAmenities = [
    'Pcs',
    'Rim',
    'Pak',
    'Box',
    'Lusin',
    'Buah',
    'Botol',
  ];

  // ==========================================
  // LOKASI GPS & FOTO
  // ==========================================
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
    _namaAlatCtrl.dispose();
    _lokasiCtrl.dispose();
    _noAparCtrl.dispose();
    _beratCtrl.dispose();
    _keteranganAparCtrl.dispose();
    _gedungRuangCtrl.dispose();
    _kapasitasCtrl.dispose();
    _keteranganP3kCtrl.dispose();
    _peralatanApdCtrl.dispose();
    _jumlahApdCtrl.dispose();
    _masaPakaiApdCtrl.dispose();
    _tglKadaluarsaApdCtrl.dispose();
    _kondisiApdCtrl.dispose();
    _pembelianApdCtrl.dispose();
    _namaAtkCtrl.dispose();
    _jumlahAtkCtrl.dispose();
    _catatanAtkCtrl.dispose();
    _namaAmenitiesCtrl.dispose();
    _jumlahAmenitiesCtrl.dispose();
    _catatanAmenitiesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Data Inspeksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _kategoriTerpilih,
                  items: _listKategori
                      .map(
                        (val) => DropdownMenuItem(value: val, child: Text(val)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _kategoriTerpilih = val!;
                      _foto = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            if (_kategoriTerpilih == 'APAR') _buildFormApar(),
            if (_kategoriTerpilih == 'P3K') _buildFormP3K(),
            if (_kategoriTerpilih == 'APD') _buildFormApd(),
            if (_kategoriTerpilih == 'ATK') _buildFormAtk(),
            if (_kategoriTerpilih == 'Amenities')
              _buildFormAmenities(), // PERBAIKAN

            const SizedBox(height: 24),

            if (_kategoriTerpilih != 'APD' &&
                _kategoriTerpilih != 'ATK' &&
                _kategoriTerpilih != 'Amenities') ...[
              // PERBAIKAN
              _buildFotoWidget(),
              const SizedBox(height: 16),
              _buildLocationButton(),
              const SizedBox(height: 32),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanData,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Data Inspeksi',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET FORM AMENITIES
  // ==========================================
  Widget _buildFormAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DATA AMENITIES',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _namaAmenitiesCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Barang (Contoh: Sabun, Sampo)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: _jumlahAmenitiesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _satuanAmenitiesTerpilih,
                decoration: const InputDecoration(
                  labelText: 'Satuan',
                  border: OutlineInputBorder(),
                ),
                items: _listSatuanAmenities
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _satuanAmenitiesTerpilih = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _catatanAmenitiesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Catatan',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET FORM ATK
  // ==========================================
  Widget _buildFormAtk() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DATA ALAT TULIS KANTOR (ATK)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _namaAtkCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Barang (Contoh: Kertas HVS, Bolpoin)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: _jumlahAtkCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _satuanAtkTerpilih,
                decoration: const InputDecoration(
                  labelText: 'Satuan',
                  border: OutlineInputBorder(),
                ),
                items: _listSatuanAtk
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _satuanAtkTerpilih = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _catatanAtkCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Catatan',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET FORM APD
  // ==========================================
  Widget _buildFormApd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DATA INVENTARIS PERALATAN K3 (APD)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _peralatanApdCtrl,
          decoration: const InputDecoration(
            labelText: 'Peralatan (Contoh: Helm Putih, Masker)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _jumlahApdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Contoh: 6, 2 Buah)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _masaPakaiApdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Masa Pakai (Contoh: 4 th, Baru)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tglKadaluarsaApdCtrl,
          decoration: const InputDecoration(
            labelText: 'Tanggal Kadaluarsa (Contoh: Juli 2027, -)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _kondisiApdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kondisi',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _pembelianApdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pembelian (Contoh: April 2024)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET FORM APAR
  // ==========================================
  Widget _buildFormApar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _namaAlatCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Alat / Merk / Jenis Media',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _lokasiCtrl,
          decoration: const InputDecoration(
            labelText: 'Lokasi Penempatan',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _noAparCtrl,
                decoration: const InputDecoration(
                  labelText: 'No APAR',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _beratCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Berat (Kg)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Tanggal Kadaluarsa APAR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDateField(
          'Pilih Tanggal',
          _tanggalKadaluarsaApar,
          (d) => setState(() => _tanggalKadaluarsaApar = d),
        ),
        const SizedBox(height: 16),
        const Text(
          'Checklist Kondisi:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CheckboxListTile(
          title: const Text('Label Pengisian'),
          value: _kondisiLabel,
          onChanged: (val) => setState(() => _kondisiLabel = val!),
        ),
        CheckboxListTile(
          title: const Text('Tekanan (Jarum Hijau)'),
          value: _kondisiTekanan,
          onChanged: (val) => setState(() => _kondisiTekanan = val!),
        ),
        CheckboxListTile(
          title: const Text('Safety Pin'),
          value: _kondisiSafetyPin,
          onChanged: (val) => setState(() => _kondisiSafetyPin = val!),
        ),
        CheckboxListTile(
          title: const Text('Handle'),
          value: _kondisiHandle,
          onChanged: (val) => setState(() => _kondisiHandle = val!),
        ),
        CheckboxListTile(
          title: const Text('Selang & Nozzle'),
          value: _kondisiSelang,
          onChanged: (val) => setState(() => _kondisiSelang = val!),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _keteranganAparCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Keterangan',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET FORM P3K
  // ==========================================
  Widget _buildFormP3K() {
    return Column(
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
                      (e) => DropdownMenuItem(value: e, child: Text('Tipe $e')),
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
      ],
    );
  }

  // ==========================================
  // WIDGET HELPER
  // ==========================================
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

  // ==========================================
  // LOGIKA SIMPAN DATA
  // ==========================================
  Future<void> _simpanData() async {
    setState(() => _isLoading = true);
    try {
      String? fotoUrl;
      if (_foto != null &&
          _kategoriTerpilih != 'APD' &&
          _kategoriTerpilih != 'ATK' &&
          _kategoriTerpilih != 'Amenities') {
        // PERBAIKAN
        final bytes = await _foto!.readAsBytes();
        fotoUrl = await CloudinaryService().uploadImageBytes(bytes);
      }

      Map<String, dynamic> dataSimpan = {};

      if (_kategoriTerpilih == 'P3K') {
        dataSimpan = {
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
      } else if (_kategoriTerpilih == 'APAR') {
        dataSimpan = {
          'kategori': 'APAR',
          'nama_alat': _namaAlatCtrl.text,
          'lokasi': _lokasiCtrl.text,
          'no_apar': _noAparCtrl.text,
          'berat': _beratCtrl.text,
          'tanggal_kadaluarsa': _tanggalKadaluarsaApar?.toIso8601String(),
          'checklist_label': _kondisiLabel,
          'checklist_tekanan': _kondisiTekanan,
          'checklist_safety_pin': _kondisiSafetyPin,
          'checklist_handle': _kondisiHandle,
          'checklist_selang': _kondisiSelang,
          'keterangan': _keteranganAparCtrl.text,
          'latitude': _latitude,
          'longitude': _longitude,
        };
      } else if (_kategoriTerpilih == 'APD') {
        dataSimpan = {
          'kategori': 'APD',
          'peralatan': _peralatanApdCtrl.text,
          'lokasi': '-',
          'jumlah': _jumlahApdCtrl.text,
          'masa_pakai': _masaPakaiApdCtrl.text,
          'tanggal_kadaluarsa': _tglKadaluarsaApdCtrl.text,
          'kondisi': _kondisiApdCtrl.text,
          'pembelian': _pembelianApdCtrl.text,
        };
      } else if (_kategoriTerpilih == 'ATK') {
        int jmlInput = int.tryParse(_jumlahAtkCtrl.text) ?? 0;
        dataSimpan = {
          'kategori': 'ATK',
          'nama_barang': _namaAtkCtrl.text,
          'lokasi': '-',
          'jumlah': jmlInput,
          'sisa_jumlah': jmlInput,
          'satuan': _satuanAtkTerpilih,
          'keterangan': _catatanAtkCtrl.text,
          'tanggal_transaksi': DateTime.now().toIso8601String(),
        };
      } else if (_kategoriTerpilih == 'Amenities') {
        // PERBAIKAN
        int jmlInput = int.tryParse(_jumlahAmenitiesCtrl.text) ?? 0;
        dataSimpan = {
          'kategori': 'Amenities', // PERBAIKAN
          'nama_barang': _namaAmenitiesCtrl.text,
          'lokasi': '-',
          'jumlah': jmlInput,
          'sisa_jumlah': jmlInput,
          'satuan': _satuanAmenitiesTerpilih,
          'keterangan': _catatanAmenitiesCtrl.text,
          'tanggal_transaksi': DateTime.now().toIso8601String(),
        };
      }

      if (fotoUrl != null) dataSimpan['foto_url'] = fotoUrl;

      await FirestoreService().tambahBarang(_kategoriTerpilih, dataSimpan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan!')),
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
