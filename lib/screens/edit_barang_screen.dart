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
  late String _kategori;

  @override
  void initState() {
    super.initState();
    _kategori = widget.dataBarang['kategori'] ?? 'APD';
    _keteranganUpdateApdCtrl = TextEditingController();

    if (_kategori == 'APD') {
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
    if (_kategori == 'APD') {
      _peralatanApdCtrl.dispose();
      _jumlahApdCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Data $_kategori')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_kategori == 'APD') _buildFormEditApd(),
            if (_kategori == 'ATK') _buildFormEditAtk(),
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

  Widget _buildFormEditAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EDIT DATA AMENITIES',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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

  Widget _buildFormEditAtk() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EDIT DATA ALAT TULIS KANTOR (ATK)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
}
