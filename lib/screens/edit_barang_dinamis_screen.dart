import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/cloudinary_service.dart';

class EditBarangDinamisScreen extends StatefulWidget {
  final String namaKategori;
  final String documentId;
  final Map<String, dynamic> dataLama;
  final List<dynamic> skemaForm;

  const EditBarangDinamisScreen({
    super.key,
    required this.namaKategori,
    required this.documentId,
    required this.dataLama,
    required this.skemaForm,
  });

  @override
  State<EditBarangDinamisScreen> createState() =>
      _EditBarangDinamisScreenState();
}

class _EditBarangDinamisScreenState extends State<EditBarangDinamisScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _dropdownValues = {};
  final Map<String, String> _gpsValues = {};
  final Map<String, String> _dateValues = {};

  final Map<String, String?> _oldImageUrls = {};
  final Map<String, Uint8List?> _newImageValues = {};

  // WADAH UNTUK GRUP BERULANG DI HALAMAN EDIT
  final Map<String, List<Map<String, TextEditingController>>>
  _repeatableControllers = {};

  @override
  void initState() {
    super.initState();
    // 1. Mengisi (Pre-fill) form dinamis dengan data lama dari Firestore
    for (var field in widget.skemaForm) {
      String label = field['label'];
      String tipe = field['tipe_input'];
      dynamic nilaiLama = widget.dataLama[label];

      if (tipe == 'Teks Pendek' || tipe == 'Teks Panjang (Catatan)') {
        _textControllers[label] = TextEditingController(
          text: nilaiLama?.toString() ?? '',
        );
      } else if (tipe == 'Angka') {
        _textControllers[label] = TextEditingController(
          text: nilaiLama?.toString() ?? '0',
        );
      } else if (tipe == 'Dropdown (Pilihan)') {
        List<dynamic> opsi = field['pilihan_opsi'] ?? [];
        String val = nilaiLama?.toString() ?? '';
        _dropdownValues[label] = opsi.contains(val)
            ? val
            : (opsi.isNotEmpty ? opsi[0].toString() : null);
      } else if (tipe == 'Titik Koordinat (GPS)') {
        _gpsValues[label] = nilaiLama?.toString() ?? '';
      } else if (tipe == 'Tanggal (Kalender)') {
        _dateValues[label] = nilaiLama?.toString() ?? '';
      } else if (tipe == 'Foto / Kamera') {
        _oldImageUrls[label] =
            (nilaiLama != null && nilaiLama.toString().isNotEmpty)
            ? nilaiLama.toString()
            : null;
        _newImageValues[label] = null;
      }
      // LOGIKA PRE-FILL KHUSUS GRUP BERULANG
      else if (tipe == 'Grup Berulang (List Aset)') {
        _repeatableControllers[label] = [];
        List<dynamic> subFields = field['sub_form'] ?? [];

        // Jika data lama berbentuk List (Array), kita buatkan controller untuk tiap itemnya
        if (nilaiLama is List) {
          for (var itemLama in nilaiLama) {
            if (itemLama is Map) {
              Map<String, TextEditingController> itemCtrl = {};
              for (var sub in subFields) {
                String subKey = sub.toString();
                // Tarik value lama, jika kosong biarkan string kosong
                itemCtrl[subKey] = TextEditingController(
                  text: itemLama[subKey]?.toString() ?? '',
                );
              }
              _repeatableControllers[label]!.add(itemCtrl);
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    // Hapus memory controller dari grup berulang
    _repeatableControllers.forEach((key, listData) {
      for (var itemMap in listData) {
        for (var ctrl in itemMap.values) {
          ctrl.dispose();
        }
      }
    });
    super.dispose();
  }

  // --- FUNGSI KHUSUS GRUP BERULANG --- //
  void _tambahItemGrup(String label, List<dynamic> subFields) {
    Map<String, TextEditingController> newItem = {};
    for (var sub in subFields) {
      newItem[sub.toString()] = TextEditingController();
    }
    setState(() {
      _repeatableControllers[label]!.add(newItem);
    });
  }

  void _hapusItemGrup(String label, int index) {
    setState(() {
      _repeatableControllers[label]![index].values.forEach(
        (ctrl) => ctrl.dispose(),
      );
      _repeatableControllers[label]!.removeAt(index);
    });
  }

  // --- FUNGSI HELPER LAINNYA --- //
  Future<void> _pilihTanggal(String label) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(
        () => _dateValues[label] = DateFormat('dd/MM/yyyy').format(pickedDate),
      );
    }
  }

  Future<void> _ambilGPS(String label) async {
    setState(() => _gpsValues[label] = 'Mengambil GPS...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS Mati');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(
        () => _gpsValues[label] = "${position.latitude}, ${position.longitude}",
      );
    } catch (e) {
      setState(() => _gpsValues[label] = "Gagal: $e");
    }
  }

  Future<void> _ambilFoto(String label) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _newImageValues[label] = bytes);
    }
  }

  // --- FUNGSI SIMPAN PERUBAHAN --- //
  Future<void> _updateData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> dataUpdate = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      for (var field in widget.skemaForm) {
        String label = field['label'];
        String tipe = field['tipe_input'];

        if (tipe == 'Teks Pendek' || tipe == 'Teks Panjang (Catatan)') {
          dataUpdate[label] = _textControllers[label]?.text.trim() ?? '';
        } else if (tipe == 'Angka') {
          dataUpdate[label] =
              int.tryParse(_textControllers[label]?.text.trim() ?? '0') ?? 0;
        } else if (tipe == 'Dropdown (Pilihan)') {
          dataUpdate[label] = _dropdownValues[label] ?? '';
        } else if (tipe == 'Tanggal (Kalender)') {
          dataUpdate[label] = _dateValues[label] ?? '';
        } else if (tipe == 'Titik Koordinat (GPS)') {
          dataUpdate[label] = _gpsValues[label] ?? '';
        } else if (tipe == 'Foto / Kamera') {
          if (_newImageValues[label] != null) {
            String? url = await CloudinaryService().uploadImageBytes(
              _newImageValues[label]!,
            );
            dataUpdate[label] = url ?? '';
          } else {
            dataUpdate[label] = _oldImageUrls[label] ?? '';
          }
        }
        // LOGIKA PENYIMPANAN GRUP BERULANG YANG DI-EDIT
        else if (tipe == 'Grup Berulang (List Aset)') {
          List<Map<String, dynamic>> dataListAset = [];
          for (var mapCtrl in _repeatableControllers[label]!) {
            Map<String, dynamic> itemAset = {};
            mapCtrl.forEach((subKey, ctrl) {
              itemAset[subKey] = ctrl.text.trim();
            });
            dataListAset.add(itemAset);
          }
          dataUpdate[label] = dataListAset;
        }
      }

      await FirebaseFirestore.instance
          .collection(widget.namaKategori)
          .doc(widget.documentId)
          .update(dataUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perubahan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // True = memicu refresh halaman
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFieldUI(Map<String, dynamic> field) {
    String label = field['label'];
    String tipe = field['tipe_input'];

    if (tipe == 'Teks Pendek') {
      return TextFormField(
        controller: _textControllers[label],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
      );
    } else if (tipe == 'Teks Panjang (Catatan)') {
      return TextFormField(
        controller: _textControllers[label],
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
    } else if (tipe == 'Angka') {
      return TextFormField(
        controller: _textControllers[label],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (val) =>
            val == null || val.isEmpty ? 'Isi dengan angka' : null,
      );
    } else if (tipe == 'Dropdown (Pilihan)') {
      List<dynamic> opsi = field['pilihan_opsi'] ?? [];
      return DropdownButtonFormField<String>(
        value: _dropdownValues[label],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: opsi
            .map(
              (e) => DropdownMenuItem(
                value: e.toString(),
                child: Text(e.toString()),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => _dropdownValues[label] = val),
      );
    } else if (tipe == 'Tanggal (Kalender)') {
      return TextFormField(
        readOnly: true,
        controller: TextEditingController(text: _dateValues[label]),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        onTap: () => _pilihTanggal(label),
      );
    } else if (tipe == 'Titik Koordinat (GPS)') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _gpsValues[label]!.isEmpty
                        ? 'GPS Belum Diambil'
                        : _gpsValues[label]!,
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _ambilGPS(label),
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Update Titik'),
            ),
          ],
        ),
      );
    } else if (tipe == 'Foto / Kamera') {
      return InkWell(
        onTap: () => _ambilFoto(label),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _newImageValues[label] != null
              ? Image.memory(_newImageValues[label]!, fit: BoxFit.cover)
              : (_oldImageUrls[label] != null
                    ? Image.network(_oldImageUrls[label]!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40),
                          Text('Tap untuk ubah foto'),
                        ],
                      )),
        ),
      );
    }
    // TAMPILAN KHUSUS UNTUK GRUP BERULANG DI HALAMAN EDIT
    else if (tipe == 'Grup Berulang (List Aset)') {
      List<dynamic> subFields = field['sub_form'] ?? [];

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 12),

            // Render setiap blok item
            ...List.generate(_repeatableControllers[label]!.length, (index) {
              var controllers = _repeatableControllers[label]![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Item #${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _hapusItemGrup(label, index),
                          ),
                        ],
                      ),
                      const Divider(),
                      // Render input sub-field yang sudah terisi data lama
                      ...subFields.map((subLabel) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: controllers[subLabel.toString()],
                            decoration: InputDecoration(
                              labelText: subLabel.toString(),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }),

            // Tombol Pemicu Tambah Item Baru
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _tambahItemGrup(label, subFields),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit ${widget.namaKategori}'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: widget.skemaForm.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _buildFieldUI(widget.skemaForm[index]),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SIMPAN PERUBAHAN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
