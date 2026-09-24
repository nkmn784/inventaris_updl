import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class TambahBarangScreen extends StatefulWidget {
  const TambahBarangScreen({super.key});

  @override
  State<TambahBarangScreen> createState() => _TambahBarangScreenState();
}

class _TambahBarangScreenState extends State<TambahBarangScreen> {
  String _kategoriTerpilih = 'APD';
  final List<String> _listKategori = ['APD', 'ATK', 'Amenities'];
  bool _isLoading = false;

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

  @override
  void dispose() {
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
      appBar: AppBar(title: const Text('Tambah Data Inventaris')),
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
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            if (_kategoriTerpilih == 'APD') _buildFormApd(),
            if (_kategoriTerpilih == 'ATK') _buildFormAtk(),
            if (_kategoriTerpilih == 'Amenities') _buildFormAmenities(),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanData,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan Data', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _simpanData() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> dataSimpan = {};

      if (_kategoriTerpilih == 'APD') {
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
        int jmlInput = int.tryParse(_jumlahAmenitiesCtrl.text) ?? 0;
        dataSimpan = {
          'kategori': 'Amenities',
          'nama_barang': _namaAmenitiesCtrl.text,
          'lokasi': '-',
          'jumlah': jmlInput,
          'sisa_jumlah': jmlInput,
          'satuan': _satuanAmenitiesTerpilih,
          'keterangan': _catatanAmenitiesCtrl.text,
          'tanggal_transaksi': DateTime.now().toIso8601String(),
        };
      }

      await FirestoreService().tambahBarang(_kategoriTerpilih, dataSimpan);

      // --- SISIPKAN PENCATAT LOG DI SINI ---
      String namaBarang =
          dataSimpan['peralatan'] ?? dataSimpan['nama_barang'] ?? 'Barang';
      await FirestoreService().catatLogAktivitas(
        tipeAksi: 'TAMBAH',
        kategori: _kategoriTerpilih,
        detail: 'Menambahkan data $_kategoriTerpilih: $namaBarang',
      );
      // ----------------------------------------

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
