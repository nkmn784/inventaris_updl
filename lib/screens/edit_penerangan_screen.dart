import 'dart:math';
import 'package:flutter/material.dart';

import '../models/penerangan_model.dart';
import '../services/firestore_service.dart';

class EditPeneranganScreen extends StatefulWidget {
  final PeneranganModel item;

  const EditPeneranganScreen({super.key, required this.item});

  @override
  State<EditPeneranganScreen> createState() => _EditPeneranganScreenState();
}

class _EditPeneranganScreenState extends State<EditPeneranganScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merkCtrl;
  late TextEditingController _wattCtrl;
  late TextEditingController _petugasCtrl;
  late TextEditingController _catatanCtrl;

  late String _statusTerpilih;
  late String _jenisLampuTerpilih;
  bool _gantiBohlamBaru = true;
  bool _isLoading = false;

  final List<String> _listStatus = ['Normal', 'Mati', 'Rusak', 'Hilang'];
  final List<String> _listJenisLampu = [
    'LED Bulb',
    'Neon / TL',
    'Downlight',
    'Halogen',
    'Lampu Jalan (PJU)',
  ];

  @override
  void initState() {
    super.initState();
    _statusTerpilih = widget.item.status ?? 'Normal';
    _jenisLampuTerpilih = widget.item.jenisLampu ?? 'LED Bulb';
    _merkCtrl = TextEditingController(text: widget.item.merkLampu);
    _wattCtrl = TextEditingController(
      text: widget.item.watt?.toString() ?? '0',
    );
    _petugasCtrl = TextEditingController();
    _catatanCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _merkCtrl.dispose();
    _wattCtrl.dispose();
    _petugasCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  String _generateKodeUnik() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _simpanPerubahan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String kodeLampuBaru = widget.item.kodeUnik ?? '';
      List<dynamic> riwayatBaru = List.from(
        widget.item.riwayatPergantian ?? [],
      );

      if (_gantiBohlamBaru) {
        kodeLampuBaru = _generateKodeUnik();

        riwayatBaru.add({
          'kodeLama': widget.item.kodeUnik,
          'tanggalGanti': DateTime.now().toIso8601String(),
          'petugas': _petugasCtrl.text.trim(),
          'merkLama': widget.item.merkLampu,
          'wattLama': widget.item.watt,
        });
      }

      Map<String, dynamic> dataUpdate = {
        'status': _statusTerpilih,
        'jenisLampu': _jenisLampuTerpilih,
        'merkLampu': _merkCtrl.text.trim(),
        'watt': int.tryParse(_wattCtrl.text) ?? 0,
        'kodeUnik': kodeLampuBaru,
        'petugasPasang': _petugasCtrl.text.trim(),
        'catatan': _catatanCtrl.text.trim(),
        'riwayatPergantian': riwayatBaru,
      };

      await FirestoreService().editBarang(
        'Penerangan',
        widget.item.id!,
        dataUpdate,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (_gantiBohlamBaru) {
          _tampilkanDialogKodeBaru(kodeLampuBaru);
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil diperbarui')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui: $e')));
      }
    }
  }

  void _tampilkanDialogKodeBaru(String kodeBaru) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Pergantian Lampu Berhasil!',
          style: TextStyle(color: Colors.green),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TULIS KODE BARU INI DENGAN SPIDOL PERMANEN PADA BOHLAM BARU:',
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: Text(
                  kodeBaru,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.0,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text(
              'SAYA SUDAH MENULISNYA',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perawatan & Ganti Lampu'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: const Text(
                  'Ganti Bohlam Baru?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Aktifkan jika melakukan pergantian fisik bohlam/lampu.',
                ),
                value: _gantiBohlamBaru,
                onChanged: (val) => setState(() => _gantiBohlamBaru = val),
                activeColor: Colors.blue.shade800,
              ),
              const Divider(height: 24),

              DropdownButtonFormField<String>(
                value: _statusTerpilih,
                decoration: const InputDecoration(
                  labelText: 'Status Lampu Saat Ini',
                  border: OutlineInputBorder(),
                ),
                items: _listStatus
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _statusTerpilih = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _merkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Merk Lampu Baru / Saat Ini',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _jenisLampuTerpilih,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Lampu',
                        border: OutlineInputBorder(),
                      ),
                      items: _listJenisLampu
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _jenisLampuTerpilih = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _wattCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Watt',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Isi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _petugasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Petugas Perawatan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _catatanCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan Perawatan / Penyebab Rusak',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanPerubahan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
