import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TambahKategoriScreen extends StatefulWidget {
  const TambahKategoriScreen({super.key});

  @override
  State<TambahKategoriScreen> createState() => _TambahKategoriScreenState();
}

class _TambahKategoriScreenState extends State<TambahKategoriScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaKategoriCtrl = TextEditingController();
  bool _isLoading = false;

  // Daftar pilihan ikon untuk kategori baru
  final Map<String, IconData> _pilihanIconMap = {
    'Kotak Barang': Icons.inventory_2,
    'Ruangan / Gedung': Icons.apartment,
    'Kendaraan / Mobil': Icons.directions_car,
    'Komputer / Elektronik': Icons.computer,
    'Mesin / Listrik': Icons.electrical_services,
    'Peralatan / Kunci': Icons.build,
    'Dokumen / Arsip': Icons.folder_special,
    'Kesehatan / Medis': Icons.medical_services,
  };
  String _kategoriIcon = 'Kotak Barang'; // Ikon default

  // DI SINI KITA MENAMBAHKAN TIPE BARU: 'Grup Berulang (List Aset)'
  final List<String> _pilihanTipeInput = [
    'Teks Pendek',
    'Teks Panjang (Catatan)',
    'Angka',
    'Dropdown (Pilihan)',
    'Tanggal (Kalender)',
    'Titik Koordinat (GPS)',
    'Foto / Kamera',
    'Grup Berulang (List Aset)', // <--- TIPE BARU
  ];

  final List<Map<String, dynamic>> _skemaForm = [];

  void _tambahField() {
    setState(() {
      _skemaForm.add({
        'label': TextEditingController(),
        'tipe': 'Teks Pendek',
        'opsi':
            TextEditingController(), // Dipakai untuk Dropdown atau Grup Berulang
      });
    });
  }

  void _hapusField(int index) {
    setState(() {
      _skemaForm[index]['label'].dispose();
      _skemaForm[index]['opsi'].dispose();
      _skemaForm.removeAt(index);
    });
  }

  Future<void> _simpanKategori() async {
    if (!_formKey.currentState!.validate()) return;

    if (_skemaForm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 field!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> blueprintForm = [];

      for (var field in _skemaForm) {
        String tipe = field['tipe'];
        Map<String, dynamic> fieldData = {
          'label': field['label'].text.trim(),
          'tipe_input': tipe,
        };

        if (tipe == 'Dropdown (Pilihan)') {
          // Menggunakan perulangan FOR manual agar bebas dari error dynamic
          List<String> listOpsi = [];
          List<String> teksPecahan = field['opsi'].text.split(',');

          for (String item in teksPecahan) {
            if (item.trim().isNotEmpty) {
              listOpsi.add(item.trim());
            }
          }

          fieldData['pilihan_opsi'] = listOpsi.isEmpty ? ['-'] : listOpsi;
        }
        // LOGIKA BARU UNTUK MENYIMPAN SUB-FORM GRUP BERULANG
        else if (tipe == 'Grup Berulang (List Aset)') {
          List<String> listSubField = [];
          List<String> teksPecahan = field['opsi'].text.split(',');

          for (String item in teksPecahan) {
            if (item.trim().isNotEmpty) {
              listSubField.add(item.trim());
            }
          }

          fieldData['sub_form'] = listSubField.isEmpty
              ? ['Item Aset']
              : listSubField;
        }

        blueprintForm.add(fieldData);
      }

      Map<String, dynamic> dataKategori = {
        'nama_kategori': _namaKategoriCtrl.text.trim(),
        'icon': _kategoriIcon, // <--- UBAH BAGIAN INI
        'skema_form': blueprintForm,
        'created_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('Master_Kategori')
          .add(dataKategori);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori Baru Berhasil Dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaKategoriCtrl.dispose();
    for (var field in _skemaForm) {
      field['label'].dispose();
      field['opsi'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Buat Kategori Dinamis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withAlpha(128),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. TextFormField Nama Kategori yang lama
                  TextFormField(
                    controller: _namaKategoriCtrl,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Isi nama kategori' : null,
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori Baru (Cth: Aset Ruangan)',
                      prefixIcon: Icon(
                        Icons.category,
                        color: Colors.blue.shade700,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Dropdown Pilihan Ikon yang baru kita tambahkan
                  DropdownButtonFormField<String>(
                    value: _kategoriIcon,
                    decoration: InputDecoration(
                      labelText: 'Pilih Ikon Kategori',
                      prefixIcon: Icon(
                        _pilihanIconMap[_kategoriIcon],
                        color: Colors.blue.shade700,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _pilihanIconMap.keys.map((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Row(
                          children: [
                            Icon(
                              _pilihanIconMap[key],
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 12),
                            Text(key),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _kategoriIcon = val!);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _skemaForm.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Field #${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _hapusField(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _skemaForm[index]['label'],
                            validator: (val) => val == null || val.isEmpty
                                ? 'Wajib diisi'
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Judul Field (Cth: Nama Ruangan)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _skemaForm[index]['tipe'],
                            decoration: InputDecoration(
                              labelText: 'Tipe Input',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _pilihanTipeInput
                                .map(
                                  (tipe) => DropdownMenuItem(
                                    value: tipe,
                                    child: Text(tipe),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(
                              () => _skemaForm[index]['tipe'] = val!,
                            ),
                          ),

                          // UI KHUSUS UNTUK DROPDOWN
                          if (_skemaForm[index]['tipe'] ==
                              'Dropdown (Pilihan)') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _skemaForm[index]['opsi'],
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Isi opsi'
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Opsi (Pisahkan dengan Koma)',
                                hintText: 'Cth: Baik, Rusak',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],

                          // UI KHUSUS UNTUK GRUP BERULANG
                          if (_skemaForm[index]['tipe'] ==
                              'Grup Berulang (List Aset)') ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sub-Field di dalam Grup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _skemaForm[index]['opsi'],
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? 'Isi sub-field'
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Isi Sub-Field (Pisahkan dengan Koma)',
                                      hintText: 'Cth: Nama Aset, Merk, Jumlah',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _tambahField,
                  icon: const Icon(Icons.add_box),
                  label: const Text('Tambah Field Input'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanKategori,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Simpan Kategori Baru',
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
}
