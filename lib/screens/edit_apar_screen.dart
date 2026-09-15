import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

class EditAparScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> dataBarang;

  const EditAparScreen({
    super.key,
    required this.documentId,
    required this.dataBarang,
  });

  @override
  State<EditAparScreen> createState() => _EditAparScreenState();
}

class _EditAparScreenState extends State<EditAparScreen> {
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

  bool _isLoading = false;
  XFile? _fotoBaru;
  String? _fotoUrlLama;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fotoUrlLama = widget.dataBarang['foto_url'];

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
      text: widget.dataBarang['berat']?.toString() ?? '',
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
      var tglVal = widget.dataBarang['tanggal_kadaluarsa'];
      if (tglVal is Timestamp) {
        _tanggalKadaluarsaApar = tglVal.toDate();
      } else if (tglVal is String) {
        _tanggalKadaluarsaApar = DateTime.tryParse(tglVal);
      }
    }
  }

  @override
  void dispose() {
    _namaAlatCtrl.dispose();
    _lokasiAparCtrl.dispose();
    _noAparCtrl.dispose();
    _beratCtrl.dispose();
    _keteranganAparCtrl.dispose();
    super.dispose();
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

      if (_fotoBaru != null) {
        final bytes = await _fotoBaru!.readAsBytes();
        String? url = await CloudinaryService().uploadImageBytes(bytes);
        if (url != null) dataUpdate['foto_url'] = url;
      }

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

      Map<String, dynamic> riwayatBaru = {
        'tanggal_edit': DateTime.now().toIso8601String(),
        'aksi': 'Edit Data APAR',
      };
      dataUpdate['riwayat_edit'] = FieldValue.arrayUnion([riwayatBaru]);

      await FirestoreService().updateBarang(
        'APAR',
        widget.documentId,
        dataUpdate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data APAR berhasil diperbarui!')),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Data APAR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Foto
            const Text(
              'Foto Dokumentasi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
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
                          : Image.file(
                              File(_fotoBaru!.path),
                              fit: BoxFit.cover,
                            ),
                    )
                  : (_fotoUrlLama != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _fotoUrlLama!,
                              fit: BoxFit.cover,
                            ),
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
            const SizedBox(height: 16),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            // Bagian Form Input
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
                DateTime? d = await showDatePicker(
                  context: context,
                  initialDate: _tanggalKadaluarsaApar ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
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
}
