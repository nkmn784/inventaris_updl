import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

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
  // === VARIABEL APD ===
  late TextEditingController _peralatanApdCtrl;
  late TextEditingController _masukApdCtrl;
  late TextEditingController _keluarApdCtrl;
  late TextEditingController _sisaJumlahApdCtrl;
  late TextEditingController _catatanApdCtrl;
  int _stokAwalApd = 0;
  DateTime? _tanggalTransaksiApd;

  late TextEditingController _masaPakaiApdCtrl;
  late TextEditingController _tglKadaluarsaApdCtrl;
  late TextEditingController _kondisiApdCtrl;
  late TextEditingController _pembelianApdCtrl;

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
  late String _kategori;

  @override
  void initState() {
    super.initState();
    _kategori = widget.dataBarang['kategori'] ?? 'APD';

    if (_kategori == 'APD') {
      _peralatanApdCtrl = TextEditingController(
        text: widget.dataBarang['peralatan'] ?? '',
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

      _masukApdCtrl = TextEditingController();
      _keluarApdCtrl = TextEditingController();

      _stokAwalApd =
          int.tryParse(widget.dataBarang['sisa_jumlah']?.toString() ?? '') ??
          int.tryParse(widget.dataBarang['jumlah']?.toString() ?? '') ??
          0;

      _sisaJumlahApdCtrl = TextEditingController(text: _stokAwalApd.toString());

      // FORM CATATAN DIKOSONGKAN UNTUK TRANSAKSI BARU
      _catatanApdCtrl = TextEditingController();
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

      // FORM CATATAN DIKOSONGKAN UNTUK TRANSAKSI BARU
      _catatanAtkCtrl = TextEditingController();

      if (widget.dataBarang['tanggal_transaksi'] != null) {
        _tanggalTransaksiAtk = DateTime.tryParse(
          widget.dataBarang['tanggal_transaksi'],
        );
      } else {
        _tanggalTransaksiAtk = DateTime.now();
      }
    } else if (_kategori == 'Amenities') {
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

      // FORM CATATAN DIKOSONGKAN UNTUK TRANSAKSI BARU
      _catatanAmenitiesCtrl = TextEditingController();

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
    if (_kategori == 'APD') {
      _peralatanApdCtrl.dispose();
      _masukApdCtrl.dispose();
      _keluarApdCtrl.dispose();
      _sisaJumlahApdCtrl.dispose();
      _catatanApdCtrl.dispose();
      _masaPakaiApdCtrl.dispose();
      _tglKadaluarsaApdCtrl.dispose();
      _kondisiApdCtrl.dispose();
      _pembelianApdCtrl.dispose();
    }
    if (_kategori == 'ATK') {
      _namaBarangAtkCtrl.dispose();
      _masukAtkCtrl.dispose();
      _keluarAtkCtrl.dispose();
      _sisaJumlahAtkCtrl.dispose();
      _catatanAtkCtrl.dispose();
    }
    if (_kategori == 'Amenities') {
      _namaBarangAmenitiesCtrl.dispose();
      _masukAmenitiesCtrl.dispose();
      _keluarAmenitiesCtrl.dispose();
      _sisaJumlahAmenitiesCtrl.dispose();
      _catatanAmenitiesCtrl.dispose();
    }
    super.dispose();
  }

  void _hitungTotalStokApd() {
    int masuk = int.tryParse(_masukApdCtrl.text) ?? 0;
    int keluar = int.tryParse(_keluarApdCtrl.text) ?? 0;
    setState(() {
      _sisaJumlahApdCtrl.text = (_stokAwalApd + masuk - keluar).toString();
    });
  }

  void _hitungTotalStokAtk() {
    int masuk = int.tryParse(_masukAtkCtrl.text) ?? 0;
    int keluar = int.tryParse(_keluarAtkCtrl.text) ?? 0;
    setState(() {
      _sisaJumlahAtkCtrl.text = (_stokAwalAtk + masuk - keluar).toString();
    });
  }

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

  Future<void> _updateData() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> dataUpdate = {};

      if (_kategori == 'APD') {
        int masuk = int.tryParse(_masukApdCtrl.text) ?? 0;
        int keluar = int.tryParse(_keluarApdCtrl.text) ?? 0;
        int sisaJumlahBaru =
            int.tryParse(_sisaJumlahApdCtrl.text) ?? _stokAwalApd;
        String waktuSekarang = DateTime.now().toIso8601String();

        dataUpdate.addAll({
          'peralatan': _peralatanApdCtrl.text,
          'masa_pakai': _masaPakaiApdCtrl.text,
          'tanggal_kadaluarsa': _tglKadaluarsaApdCtrl.text,
          'kondisi': _kondisiApdCtrl.text,
          'pembelian': _pembelianApdCtrl.text,
          'masuk': masuk,
          'keluar': keluar,
          'jumlah': sisaJumlahBaru,
          'sisa_jumlah': sisaJumlahBaru,
          'stok_sekarang': sisaJumlahBaru,
          'tanggal_transaksi': waktuSekarang,
          'keterangan': _catatanApdCtrl.text,
        });

        if (_stokAwalApd != sisaJumlahBaru ||
            masuk > 0 ||
            keluar > 0 ||
            _catatanApdCtrl.text.isNotEmpty) {
          Map<String, dynamic> riwayatApdBaru = {
            'tanggal': waktuSekarang,
            'masuk': masuk,
            'keluar': keluar,
            'jumlah_lama': _stokAwalApd,
            'jumlah_baru': sisaJumlahBaru,
            'catatan': _catatanApdCtrl.text.isEmpty
                ? 'Update data APD'
                : _catatanApdCtrl.text,
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

  // Desain Input Form universal bergaya Modern-Minimalis
  InputDecoration _inputDecor(
    String label, {
    String? hint,
    Widget? suffixIcon,
    bool isReadOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isReadOnly ? Colors.grey.shade200 : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
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
        title: Text(
          'Edit Data $_kategori',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Form Edit $_kategori',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3460),
                    ),
                  ),
                  Icon(
                    _kategori == 'APD'
                        ? Icons.health_and_safety
                        : _kategori == 'ATK'
                        ? Icons.edit_document
                        : Icons.category,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
              const Divider(height: 30),

              if (_kategori == 'APD') _buildFormEditApd(),
              if (_kategori == 'ATK') _buildFormEditAtk(),
              if (_kategori == 'Amenities') _buildFormEditAmenities(),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _updateData,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormEditAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _namaBarangAmenitiesCtrl,
          decoration: _inputDecor('Nama Barang'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _satuanAmenitiesTerpilih,
          decoration: _inputDecor('Satuan'),
          items: _listSatuanAmenities
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => _satuanAmenitiesTerpilih = val!),
        ),
        const SizedBox(height: 24),
        const Text(
          'Data Transaksi / Pergerakan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          decoration: _inputDecor(
            'Tanggal Transaksi',
            suffixIcon: const Icon(Icons.calendar_month, color: Colors.blue),
          ),
          onTap: () async {
            DateTime? d = await _selectDate(
              context,
              _tanggalTransaksiAmenities,
            );
            if (d != null) setState(() => _tanggalTransaksiAmenities = d);
          },
          controller: TextEditingController(
            text: _tanggalTransaksiAmenities == null
                ? 'Pilih Tanggal'
                : '${_tanggalTransaksiAmenities!.day}-${_tanggalTransaksiAmenities!.month}-${_tanggalTransaksiAmenities!.year}',
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
                decoration: _inputDecor('Masuk (+)', hint: '0'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _keluarAmenitiesCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _hitungTotalStokAmenities(),
                decoration: _inputDecor('Keluar (-)', hint: '0'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sisaJumlahAmenitiesCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Total Stok Saat Ini',
            helperText: 'Otomatis: (Lama + Masuk - Keluar)',
            helperStyle: TextStyle(color: Colors.blue.shade700, fontSize: 11),
            filled: true,
            fillColor: Colors.blue.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
          ),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blue.shade900,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _catatanAmenitiesCtrl,
          maxLines: 2,
          decoration: _inputDecor(
            'Catatan',
            hint: 'Cth: Pengadaan rutin bulanan',
          ),
        ),
      ],
    );
  }

  Widget _buildFormEditAtk() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _namaBarangAtkCtrl,
          decoration: _inputDecor('Nama Barang'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _satuanAtkTerpilih,
          decoration: _inputDecor('Satuan'),
          items: _listSatuanAtk
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => _satuanAtkTerpilih = val!),
        ),
        const SizedBox(height: 24),
        const Text(
          'Data Transaksi / Pergerakan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          decoration: _inputDecor(
            'Tanggal Transaksi',
            suffixIcon: const Icon(Icons.calendar_month, color: Colors.blue),
          ),
          onTap: () async {
            DateTime? d = await _selectDate(context, _tanggalTransaksiAtk);
            if (d != null) setState(() => _tanggalTransaksiAtk = d);
          },
          controller: TextEditingController(
            text: _tanggalTransaksiAtk == null
                ? 'Pilih Tanggal'
                : '${_tanggalTransaksiAtk!.day}-${_tanggalTransaksiAtk!.month}-${_tanggalTransaksiAtk!.year}',
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
                decoration: _inputDecor('Masuk (+)', hint: '0'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _keluarAtkCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _hitungTotalStokAtk(),
                decoration: _inputDecor('Keluar (-)', hint: '0'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sisaJumlahAtkCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Total Stok Saat Ini',
            helperText: 'Otomatis: (Lama + Masuk - Keluar)',
            helperStyle: TextStyle(color: Colors.blue.shade700, fontSize: 11),
            filled: true,
            fillColor: Colors.blue.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
          ),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blue.shade900,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _catatanAtkCtrl,
          maxLines: 2,
          decoration: _inputDecor(
            'Catatan',
            hint: 'Cth: Pengadaan rutin bulanan',
          ),
        ),
      ],
    );
  }

  Widget _buildFormEditApd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _peralatanApdCtrl,
          decoration: _inputDecor('Nama Peralatan'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Data Transaksi / Pergerakan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _masukApdCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _hitungTotalStokApd(),
                decoration: _inputDecor('Masuk (+)', hint: '0'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _keluarApdCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => _hitungTotalStokApd(),
                decoration: _inputDecor('Keluar (-)', hint: '0'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sisaJumlahApdCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Total Stok Saat Ini',
            helperText: 'Otomatis: (Lama + Masuk - Keluar)',
            helperStyle: TextStyle(color: Colors.blue.shade700, fontSize: 11),
            filled: true,
            fillColor: Colors.blue.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
          ),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blue.shade900,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _catatanApdCtrl,
          maxLines: 2,
          decoration: _inputDecor(
            'Catatan Transaksi',
            hint: 'Cth: Pengadaan baru / Rusak',
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'Informasi Tambahan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F3460),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _masaPakaiApdCtrl,
                decoration: _inputDecor('Masa Pakai'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _tglKadaluarsaApdCtrl,
                decoration: _inputDecor('Tgl Kadaluarsa'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _kondisiApdCtrl,
                decoration: _inputDecor('Kondisi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _pembelianApdCtrl,
                decoration: _inputDecor('Thn Pembelian'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
