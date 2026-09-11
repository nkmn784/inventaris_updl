import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

class EditBarangScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> dataBarang;

  const EditBarangScreen({
    super.key,
    required this.documentId,
    required this.dataBarang,
  });

  @override
  State<EditBarangScreen> createState() => _EditBarangScreenState();
}

class _EditBarangScreenState extends State<EditBarangScreen> {
  // === VARIABEL APAR ===
  late TextEditingController _namaAlatCtrl;
  late TextEditingController _lokasiAparCtrl;
  late TextEditingController _noAparCtrl;
  late TextEditingController _beratCtrl;
  late TextEditingController _keteranganAparCtrl;
  DateTime? _tanggalKadaluarsaApar;
  late bool _kondisiLabel;
  late bool _kondisiTekanan;
  late bool _kondisiSafetyPin;
  late bool _kondisiHandle;
  late bool _kondisiSelang;

  // === VARIABEL P3K ===
  late TextEditingController _gedungRuangCtrl;
  late TextEditingController _kapasitasCtrl;
  late TextEditingController _keteranganP3kCtrl;
  late String _existingP3k;
  late String _rekomendasiP3k;
  DateTime? _expAquades;
  DateTime? _expPovidon;
  DateTime? _expAlcohol;
  Map<String, bool> _checklistP3k = {};

  // === VARIABEL APD ===
  late TextEditingController _peralatanApdCtrl;
  late TextEditingController _jumlahApdCtrl;
  late TextEditingController _masaPakaiApdCtrl;
  late TextEditingController _tglKadaluarsaApdCtrl;
  late TextEditingController _kondisiApdCtrl;
  late TextEditingController _pembelianApdCtrl;
  late TextEditingController _keteranganUpdateApdCtrl;

  // === VARIABEL ATK ===
  late TextEditingController _namaBarangAtkCtrl;
  late TextEditingController _masukAtkCtrl;
  late TextEditingController _keluarAtkCtrl;
  late TextEditingController _sisaJumlahAtkCtrl;
  late TextEditingController _catatanAtkCtrl;
  String _satuanAtkTerpilih = 'Pcs';
  final List<String> _listSatuanAtk = [
    'Pcs',
    'Rim',
    'Pak',
    'Box',
    'Lusin',
    'Buah',
  ];
  DateTime? _tanggalTransaksiAtk;
  int _stokAwalAtk = 0;

  // === VARIABEL AMENITIES ===
  late TextEditingController _namaBarangAmenitiesCtrl;
  late TextEditingController _masukAmenitiesCtrl;
  late TextEditingController _keluarAmenitiesCtrl;
  late TextEditingController _sisaJumlahAmenitiesCtrl;
  late TextEditingController _catatanAmenitiesCtrl;
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
  DateTime? _tanggalTransaksiAmenities;
  int _stokAwalAmenities = 0;

  // === UMUM ===
  bool _isLoading = false;
  XFile? _fotoBaru;
  String? _fotoUrlLama;
  final ImagePicker _picker = ImagePicker();
  late String _kategori;

  @override
  void initState() {
    super.initState();
    _kategori = widget.dataBarang['kategori'] ?? 'APAR';
    _fotoUrlLama = widget.dataBarang['foto_url'];

    _keteranganUpdateApdCtrl = TextEditingController();

    if (_kategori == 'APAR') {
      _namaAlatCtrl = TextEditingController(
        text: widget.dataBarang['nama_alat'] ?? '',
      );
      _lokasiAparCtrl = TextEditingController(
        text: widget.dataBarang['lokasi'] ?? '',
      );
      _noAparCtrl = TextEditingController(
        text: widget.dataBarang['no_apar'] ?? '',
      );
      _beratCtrl = TextEditingController(
        text: widget.dataBarang['berat'] ?? '',
      );
      _keteranganAparCtrl = TextEditingController(
        text: widget.dataBarang['keterangan'] ?? '',
      );

      _kondisiLabel = widget.dataBarang['checklist_label'] ?? true;
      _kondisiTekanan = widget.dataBarang['checklist_tekanan'] ?? true;
      _kondisiSafetyPin = widget.dataBarang['checklist_safety_pin'] ?? true;
      _kondisiHandle = widget.dataBarang['checklist_handle'] ?? true;
      _kondisiSelang = widget.dataBarang['checklist_selang'] ?? true;

      if (widget.dataBarang['tanggal_kadaluarsa'] != null) {
        _tanggalKadaluarsaApar = DateTime.tryParse(
          widget.dataBarang['tanggal_kadaluarsa'],
        );
      }
    } else if (_kategori == 'P3K') {
      _gedungRuangCtrl = TextEditingController(
        text:
            widget.dataBarang['gedung_ruang'] ??
            widget.dataBarang['lokasi'] ??
            '',
      );
      _kapasitasCtrl = TextEditingController(
        text: widget.dataBarang['kapasitas']?.toString() ?? '0',
      );
      _keteranganP3kCtrl = TextEditingController(
        text: widget.dataBarang['keterangan'] ?? '',
      );

      _existingP3k = widget.dataBarang['existing'] ?? 'A';
      _rekomendasiP3k = widget.dataBarang['rekomendasi'] ?? '1A';

      if (widget.dataBarang['checklist_items'] != null) {
        _checklistP3k = Map<String, bool>.from(
          widget.dataBarang['checklist_items'],
        );
      }

      if (widget.dataBarang['exp_aquades'] != null) {
        _expAquades = DateTime.tryParse(widget.dataBarang['exp_aquades']);
      }
      if (widget.dataBarang['exp_povidon'] != null) {
        _expPovidon = DateTime.tryParse(widget.dataBarang['exp_povidon']);
      }
      if (widget.dataBarang['exp_alcohol'] != null) {
        _expAlcohol = DateTime.tryParse(widget.dataBarang['exp_alcohol']);
      }
    } else if (_kategori == 'APD') {
      _peralatanApdCtrl = TextEditingController(
        text: widget.dataBarang['peralatan'] ?? '',
      );
      _jumlahApdCtrl = TextEditingController(
        text: widget.dataBarang['jumlah']?.toString() ?? '',
      );
      _masaPakaiApdCtrl = TextEditingController(
        text: widget.dataBarang['masa_pakai'] ?? '',
      );
      _tglKadaluarsaApdCtrl = TextEditingController(
        text: widget.dataBarang['tanggal_kadaluarsa'] ?? '',
      );
      _kondisiApdCtrl = TextEditingController(
        text: widget.dataBarang['kondisi'] ?? 'Baik',
      );
      _pembelianApdCtrl = TextEditingController(
        text: widget.dataBarang['pembelian'] ?? '',
      );
    } else if (_kategori == 'ATK') {
      _namaBarangAtkCtrl = TextEditingController(
        text: widget.dataBarang['nama_barang'] ?? '',
      );

      String satuanDb = widget.dataBarang['satuan'] ?? 'Pcs';
      if (!_listSatuanAtk.contains(satuanDb)) {
        satuanDb = 'Pcs';
      }
      _satuanAtkTerpilih = satuanDb;

      _masukAtkCtrl = TextEditingController();
      _keluarAtkCtrl = TextEditingController();

      _stokAwalAtk =
          int.tryParse(widget.dataBarang['sisa_jumlah']?.toString() ?? '') ??
          int.tryParse(widget.dataBarang['jumlah']?.toString() ?? '') ??
          0;

      _sisaJumlahAtkCtrl = TextEditingController(text: _stokAwalAtk.toString());

      _catatanAtkCtrl = TextEditingController(
        text:
            widget.dataBarang['keterangan'] ??
            widget.dataBarang['catatan'] ??
            '',
      );

      if (widget.dataBarang['tanggal_transaksi'] != null) {
        _tanggalTransaksiAtk = DateTime.tryParse(
          widget.dataBarang['tanggal_transaksi'],
        );
      } else {
        _tanggalTransaksiAtk = DateTime.now();
      }
    } else if (_kategori == 'Amenities') {
      // PERBAIKAN: Mengubah 'AMENITIES' menjadi 'Amenities'
      // INISIALISASI FORM AMENITIES
      _namaBarangAmenitiesCtrl = TextEditingController(
        text: widget.dataBarang['nama_barang'] ?? '',
      );

      String satuanDb = widget.dataBarang['satuan'] ?? 'Pcs';
      if (!_listSatuanAmenities.contains(satuanDb)) {
        satuanDb = 'Pcs';
      }
      _satuanAmenitiesTerpilih = satuanDb;

      _masukAmenitiesCtrl = TextEditingController();
      _keluarAmenitiesCtrl = TextEditingController();

      _stokAwalAmenities =
          int.tryParse(widget.dataBarang['sisa_jumlah']?.toString() ?? '') ??
          int.tryParse(widget.dataBarang['jumlah']?.toString() ?? '') ??
          0;

      _sisaJumlahAmenitiesCtrl = TextEditingController(
        text: _stokAwalAmenities.toString(),
      );

      _catatanAmenitiesCtrl = TextEditingController(
        text:
            widget.dataBarang['keterangan'] ??
            widget.dataBarang['catatan'] ??
            '',
      );

      if (widget.dataBarang['tanggal_transaksi'] != null) {
        _tanggalTransaksiAmenities = DateTime.tryParse(
          widget.dataBarang['tanggal_transaksi'],
        );
      } else {
        _tanggalTransaksiAmenities = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _keteranganUpdateApdCtrl.dispose();
    if (_kategori == 'ATK') {
      _namaBarangAtkCtrl.dispose();
      _masukAtkCtrl.dispose();
      _keluarAtkCtrl.dispose();
      _sisaJumlahAtkCtrl.dispose();
      _catatanAtkCtrl.dispose();
    }
    if (_kategori == 'Amenities') {
      // PERBAIKAN: Mengubah 'AMENITIES' menjadi 'Amenities'
      _namaBarangAmenitiesCtrl.dispose();
      _masukAmenitiesCtrl.dispose();
      _keluarAmenitiesCtrl.dispose();
      _sisaJumlahAmenitiesCtrl.dispose();
      _catatanAmenitiesCtrl.dispose();
    }
    super.dispose();
  }

  // Hitung otomatis Total Stok ATK
  void _hitungTotalStokAtk() {
    int masuk = int.tryParse(_masukAtkCtrl.text) ?? 0;
    int keluar = int.tryParse(_keluarAtkCtrl.text) ?? 0;
    setState(() {
      _sisaJumlahAtkCtrl.text = (_stokAwalAtk + masuk - keluar).toString();
    });
  }

  // Hitung otomatis Total Stok AMENITIES
  void _hitungTotalStokAmenities() {
    int masuk = int.tryParse(_masukAmenitiesCtrl.text) ?? 0;
    int keluar = int.tryParse(_keluarAmenitiesCtrl.text) ?? 0;
    setState(() {
      _sisaJumlahAmenitiesCtrl.text = (_stokAwalAmenities + masuk - keluar)
          .toString();
    });
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime? initial) async {
    return await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _pilihFoto(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) setState(() => _fotoBaru = pickedFile);
  }

  Future<void> _updateData() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> dataUpdate = {};

      // PERBAIKAN: Mengubah 'AMENITIES' menjadi 'Amenities' untuk logic upload foto
      if (_fotoBaru != null &&
          _kategori != 'APD' &&
          _kategori != 'ATK' &&
          _kategori != 'Amenities') {
        final bytes = await _fotoBaru!.readAsBytes();
        String? url = await CloudinaryService().uploadImageBytes(bytes);
        if (url != null) dataUpdate['foto_url'] = url;
      }

      if (_kategori == 'APAR') {
        dataUpdate.addAll({
          'nama_alat': _namaAlatCtrl.text,
          'lokasi': _lokasiAparCtrl.text,
          'no_apar': _noAparCtrl.text,
          'berat': _beratCtrl.text,
          'tanggal_kadaluarsa': _tanggalKadaluarsaApar?.toIso8601String(),
          'checklist_label': _kondisiLabel,
          'checklist_tekanan': _kondisiTekanan,
          'checklist_safety_pin': _kondisiSafetyPin,
          'checklist_handle': _kondisiHandle,
          'checklist_selang': _kondisiSelang,
          'keterangan': _keteranganAparCtrl.text,
        });
      } else if (_kategori == 'P3K') {
        dataUpdate.addAll({
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
        });
      } else if (_kategori == 'APD') {
        dataUpdate.addAll({
          'peralatan': _peralatanApdCtrl.text,
          'jumlah': _jumlahApdCtrl.text,
          'masa_pakai': _masaPakaiApdCtrl.text,
          'tanggal_kadaluarsa': _tglKadaluarsaApdCtrl.text,
          'kondisi': _kondisiApdCtrl.text,
          'pembelian': _pembelianApdCtrl.text,
        });

        int jumlahLama =
            int.tryParse(widget.dataBarang['jumlah']?.toString() ?? '0') ?? 0;
        int jumlahBaru = int.tryParse(_jumlahApdCtrl.text) ?? 0;
        String keteranganApd = _keteranganUpdateApdCtrl.text.trim();

        if (jumlahLama != jumlahBaru || keteranganApd.isNotEmpty) {
          Map<String, dynamic> riwayatApdBaru = {
            'tanggal': DateTime.now().toIso8601String(),
            'jumlah_lama': jumlahLama,
            'jumlah_baru': jumlahBaru,
            'keterangan': keteranganApd.isEmpty
                ? 'Penyesuaian / Update stok'
                : keteranganApd,
          };

          dataUpdate['riwayat_jumlah_apd'] = FieldValue.arrayUnion([
            riwayatApdBaru,
          ]);
        }
      } else if (_kategori == 'ATK') {
        int masuk = int.tryParse(_masukAtkCtrl.text) ?? 0;
        int keluar = int.tryParse(_keluarAtkCtrl.text) ?? 0;
        int sisaJumlahBaru =
            int.tryParse(_sisaJumlahAtkCtrl.text) ?? _stokAwalAtk;

        dataUpdate.addAll({
          'nama_barang': _namaBarangAtkCtrl.text,
          'satuan': _satuanAtkTerpilih,
          'masuk': masuk,
          'keluar': keluar,
          'jumlah': sisaJumlahBaru,
          'sisa_jumlah': sisaJumlahBaru,
          'stok_sekarang': sisaJumlahBaru,
          'tanggal_transaksi':
              _tanggalTransaksiAtk?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'keterangan': _catatanAtkCtrl.text,
        });

        if (_stokAwalAtk != sisaJumlahBaru ||
            masuk > 0 ||
            keluar > 0 ||
            _catatanAtkCtrl.text.isNotEmpty) {
          Map<String, dynamic> riwayatAtkBaru = {
            'tanggal': DateTime.now().toIso8601String(),
            'masuk': masuk,
            'keluar': keluar,
            'jumlah_lama': _stokAwalAtk,
            'jumlah_baru': sisaJumlahBaru,
            'catatan': _catatanAtkCtrl.text.isEmpty
                ? 'Update data ATK'
                : _catatanAtkCtrl.text,
          };

          dataUpdate['riwayat_stok_atk'] = FieldValue.arrayUnion([
            riwayatAtkBaru,
          ]);
        }
      } else if (_kategori == 'Amenities') {
        // PERBAIKAN: Mengubah 'AMENITIES' menjadi 'Amenities'
        // ==============================================================
        // LOGIKA UPDATE DATA & RIWAYAT PERGERAKAN STOK AMENITIES
        // ==============================================================
        int masuk = int.tryParse(_masukAmenitiesCtrl.text) ?? 0;
        int keluar = int.tryParse(_keluarAmenitiesCtrl.text) ?? 0;
        int sisaJumlahBaru =
            int.tryParse(_sisaJumlahAmenitiesCtrl.text) ?? _stokAwalAmenities;

        dataUpdate.addAll({
          'nama_barang': _namaBarangAmenitiesCtrl.text,
          'satuan': _satuanAmenitiesTerpilih,
          'masuk': masuk,
          'keluar': keluar,
          'jumlah': sisaJumlahBaru,
          'sisa_jumlah': sisaJumlahBaru,
          'stok_sekarang': sisaJumlahBaru,
          'tanggal_transaksi':
              _tanggalTransaksiAmenities?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'keterangan': _catatanAmenitiesCtrl.text,
        });

        if (_stokAwalAmenities != sisaJumlahBaru ||
            masuk > 0 ||
            keluar > 0 ||
            _catatanAmenitiesCtrl.text.isNotEmpty) {
          Map<String, dynamic> riwayatAmenitiesBaru = {
            'tanggal': DateTime.now().toIso8601String(),
            'masuk': masuk,
            'keluar': keluar,
            'jumlah_lama': _stokAwalAmenities,
            'jumlah_baru': sisaJumlahBaru,
            'catatan': _catatanAmenitiesCtrl.text.isEmpty
                ? 'Update data AMENITIES'
                : _catatanAmenitiesCtrl.text,
          };

          dataUpdate['riwayat_stok_amenities'] = FieldValue.arrayUnion([
            riwayatAmenitiesBaru,
          ]);
        }
      }

      // Riwayat Edit Umum
      Map<String, dynamic> riwayatBaru = {
        'tanggal_edit': DateTime.now().toIso8601String(),
        'aksi': 'Edit Data $_kategori',
      };
      dataUpdate['riwayat_edit'] = FieldValue.arrayUnion([riwayatBaru]);

      await FirestoreService().updateBarang(
        _kategori,
        widget.documentId,
        dataUpdate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diperbarui!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Data $_kategori')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // PERBAIKAN: Mengubah 'AMENITIES' menjadi 'Amenities' untuk sembunyikan foto
            if (_kategori != 'APD' &&
                _kategori != 'ATK' &&
                _kategori != 'Amenities') ...[
              _buildFotoWidget(),
              const SizedBox(height: 16),
              const Divider(thickness: 2),
              const SizedBox(height: 16),
            ],

            if (_kategori == 'APAR') _buildFormEditApar(),
            if (_kategori == 'P3K') _buildFormEditP3K(),
            if (_kategori == 'APD') _buildFormEditApd(),
            if (_kategori == 'ATK') _buildFormEditAtk(),
            // PERBAIKAN: Mengubah 'AMENITIES' menjadi 'Amenities' agar form tampil
            if (_kategori == 'Amenities') _buildFormEditAmenities(),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateData,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Perubahan',
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
  // WIDGET FORM EDIT AMENITIES
  // ==========================================
  Widget _buildFormEditAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EDIT DATA AMENITIES',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 1. Informasi Barang & Satuan
        TextField(
          controller: _namaBarangAmenitiesCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Barang',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _satuanAmenitiesTerpilih,
          decoration: const InputDecoration(
            labelText: 'Satuan',
            border: OutlineInputBorder(),
          ),
          items: _listSatuanAmenities
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => _satuanAmenitiesTerpilih = val!),
        ),
        const SizedBox(height: 16),

        // 2. Transaksi & Penyesuaian Stok
        const Text(
          'Data Transaksi / Pergerakan Barang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            DateTime? d = await _selectDate(
              context,
              _tanggalTransaksiAmenities,
            );
            if (d != null) setState(() => _tanggalTransaksiAmenities = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Tanggal Transaksi',
              border: OutlineInputBorder(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tanggalTransaksiAmenities == null
                      ? 'Pilih Tanggal'
                      : '${_tanggalTransaksiAmenities!.day}-${_tanggalTransaksiAmenities!.month}-${_tanggalTransaksiAmenities!.year}',
                ),
                const Icon(Icons.calendar_month, color: Colors.blueAccent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _masukAmenitiesCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _hitungTotalStokAmenities(),
                decoration: const InputDecoration(
                  labelText: 'Barang Masuk (+)',
                  border: OutlineInputBorder(),
                  hintText: '0',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _keluarAmenitiesCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _hitungTotalStokAmenities(),
                decoration: const InputDecoration(
                  labelText: 'Barang Keluar (-)',
                  border: OutlineInputBorder(),
                  hintText: '0',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Info Stok (Otomatis)
        TextField(
          controller: _sisaJumlahAmenitiesCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Jumlah Stock Saat Ini',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey.shade200,
            helperText: 'Otomatis: (Stok Lama + Masuk - Keluar)',
            helperStyle: const TextStyle(color: Colors.blue),
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),

        // 4. Catatan / Keterangan
        TextField(
          controller: _catatanAmenitiesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Catatan',
            hintText: 'Cth: Pengadaan rutin bulanan / Diambil tim B',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET FORM EDIT ATK
  // ==========================================
  Widget _buildFormEditAtk() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EDIT DATA ALAT TULIS KANTOR (ATK)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 1. Informasi Barang & Satuan
        TextField(
          controller: _namaBarangAtkCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Barang',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
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
        const SizedBox(height: 16),

        // 2. Transaksi & Penyesuaian Stok
        const Text(
          'Data Transaksi / Pergerakan Barang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            DateTime? d = await _selectDate(context, _tanggalTransaksiAtk);
            if (d != null) setState(() => _tanggalTransaksiAtk = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Tanggal Transaksi',
              border: OutlineInputBorder(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tanggalTransaksiAtk == null
                      ? 'Pilih Tanggal'
                      : '${_tanggalTransaksiAtk!.day}-${_tanggalTransaksiAtk!.month}-${_tanggalTransaksiAtk!.year}',
                ),
                const Icon(Icons.calendar_month, color: Colors.blueAccent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _masukAtkCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _hitungTotalStokAtk(),
                decoration: const InputDecoration(
                  labelText: 'Barang Masuk (+)',
                  border: OutlineInputBorder(),
                  hintText: '0',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _keluarAtkCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _hitungTotalStokAtk(),
                decoration: const InputDecoration(
                  labelText: 'Barang Keluar (-)',
                  border: OutlineInputBorder(),
                  hintText: '0',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Info Stok (Otomatis)
        TextField(
          controller: _sisaJumlahAtkCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Jumlah Stock Saat Ini',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey.shade200,
            helperText: 'Otomatis: (Stok Lama + Masuk - Keluar)',
            helperStyle: const TextStyle(color: Colors.blue),
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),

        // 4. Catatan / Keterangan
        TextField(
          controller: _catatanAtkCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Catatan',
            hintText: 'Cth: Pengadaan rutin bulanan / Diambil tim A',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET FORM APD
  // ==========================================
  Widget _buildFormEditApd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EDIT DATA PERALATAN K3 (APD)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _peralatanApdCtrl,
          decoration: const InputDecoration(
            labelText: 'Peralatan',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _jumlahApdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _masaPakaiApdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Masa Pakai',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catatan Perubahan Stok (Wajib diisi jika jumlah diubah):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _keteranganUpdateApdCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Cth: Dipinjam 4 untuk pelatihan',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tglKadaluarsaApdCtrl,
          decoration: const InputDecoration(
            labelText: 'Tanggal Kadaluarsa',
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
                  labelText: 'Pembelian',
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
  // WIDGET FORM APAR & P3K
  // ==========================================
  Widget _buildFormEditApar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _namaAlatCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Alat / Merk',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _lokasiAparCtrl,
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
        InkWell(
          onTap: () async {
            DateTime? d = await _selectDate(context, _tanggalKadaluarsaApar);
            if (d != null) setState(() => _tanggalKadaluarsaApar = d);
          },
          child: InputDecorator(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tanggalKadaluarsaApar == null
                      ? 'Pilih Tanggal'
                      : '${_tanggalKadaluarsaApar!.day}-${_tanggalKadaluarsaApar!.month}-${_tanggalKadaluarsaApar!.year}',
                ),
                const Icon(Icons.calendar_month, color: Colors.redAccent),
              ],
            ),
          ),
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

  Widget _buildFormEditP3K() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _gedungRuangCtrl,
          decoration: const InputDecoration(
            labelText: 'Gedung/Ruang',
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
                  labelText: 'Kapasitas',
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
        const SizedBox(height: 16),
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
          'Tanggal Kadaluarsa Obat/Cairan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildEditDateField(
          'Exp. Aquades',
          _expAquades,
          (d) => setState(() => _expAquades = d),
        ),
        const SizedBox(height: 8),
        _buildEditDateField(
          'Exp. Povidon',
          _expPovidon,
          (d) => setState(() => _expPovidon = d),
        ),
        const SizedBox(height: 8),
        _buildEditDateField(
          'Exp. Alcohol',
          _expAlcohol,
          (d) => setState(() => _expAlcohol = d),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _keteranganP3kCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Keterangan Temuan',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditDateField(
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
          child: _fotoBaru != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(_fotoBaru!.path, fit: BoxFit.cover)
                      : Image.file(File(_fotoBaru!.path), fit: BoxFit.cover),
                )
              : (_fotoUrlLama != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(_fotoUrlLama!, fit: BoxFit.cover),
                      )
                    : const Center(child: Text('Belum ada foto'))),
        ),
        const SizedBox(height: 8),
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
}
