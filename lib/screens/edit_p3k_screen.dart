import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

class EditP3kScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> dataBarang;

  const EditP3kScreen({
    super.key,
    required this.documentId,
    required this.dataBarang,
  });

  @override
  State<EditP3kScreen> createState() => _EditP3kScreenState();
}

class _EditP3kScreenState extends State<EditP3kScreen> {
  late TextEditingController _gedungRuangCtrl;
  late TextEditingController _kapasitasCtrl;
  late TextEditingController _keteranganP3kCtrl;
  late String _existingP3k;
  late String _rekomendasiP3k;
  DateTime? _expAquades;
  DateTime? _expPovidon;
  DateTime? _expAlcohol;
  Map<String, bool> _checklistP3k = {};

  bool _isLoading = false;
  XFile? _fotoBaru;
  String? _fotoUrlLama;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fotoUrlLama = widget.dataBarang['foto_url'];

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
  }

  @override
  void dispose() {
    _gedungRuangCtrl.dispose();
    _kapasitasCtrl.dispose();
    _keteranganP3kCtrl.dispose();
    super.dispose();
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

      if (_fotoBaru != null) {
        final bytes = await _fotoBaru!.readAsBytes();
        String? url = await CloudinaryService().uploadImageBytes(bytes);
        if (url != null) dataUpdate['foto_url'] = url;
      }

      dataUpdate.addAll({
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
      });

      Map<String, dynamic> riwayatBaru = {
        'tanggal_edit': DateTime.now().toIso8601String(),
        'aksi': 'Edit Data P3K',
      };
      dataUpdate['riwayat_edit'] = FieldValue.arrayUnion([riwayatBaru]);

      await FirestoreService().updateBarang(
        'P3K',
        widget.documentId,
        dataUpdate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data P3K berhasil diperbarui!')),
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
      appBar: AppBar(title: const Text('Edit Data P3K')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFotoWidget(),
            const SizedBox(height: 16),
            const Divider(thickness: 2),
            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateData,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Perubahan P3K',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
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
