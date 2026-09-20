import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<String> _generateKodeUnikUnik() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    bool isDuplicate = true;
    String kodeBaru = '';

    while (isDuplicate) {
      kodeBaru = String.fromCharCodes(
        Iterable.generate(
          4,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
        ),
      );

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Penerangan')
          .where('kode_unik', isEqualTo: kodeBaru)
          .get();

      if (querySnapshot.docs.isEmpty) {
        isDuplicate = false;
      }
    }

    return kodeBaru;
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
        kodeLampuBaru = await _generateKodeUnikUnik();
      }

      riwayatBaru.add({
        'tindakan': _gantiBohlamBaru
            ? 'Ganti Bohlam Baru'
            : 'Perawatan / Ubah Status',
        'tanggal': DateTime.now().toIso8601String(),
        'petugas': _petugasCtrl.text.trim(),
        'statusBaru': _statusTerpilih,
        'kodeLampu': kodeLampuBaru,
        'merkLampu': _merkCtrl.text.trim(),
        'watt': int.tryParse(_wattCtrl.text) ?? 0,
        'catatan': _catatanCtrl.text.trim(),
      });

      Map<String, dynamic> dataUpdate = {
        'status': _statusTerpilih,
        'jenis_lampu': _jenisLampuTerpilih,
        'merk_lampu': _merkCtrl.text.trim(),
        'watt': int.tryParse(_wattCtrl.text) ?? 0,
        'kode_unik': kodeLampuBaru,
        'petugas_pasang': _petugasCtrl.text.trim(),
        'catatan': _catatanCtrl.text.trim(),
        'riwayat_pergantian': riwayatBaru,
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
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _tampilkanDialogKodeBaru(String kodeBaru) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Pergantian Lampu Berhasil!',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TULIS KODE BARU INI DENGAN SPIDOL PERMANEN PADA BOHLAM BARU:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade700, width: 2),
                ),
                child: Text(
                  kodeBaru,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6.0,
                    color: Colors.blue.shade900,
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
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'SAYA SUDAH MENULISNYA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Perawatan & Ganti Lampu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Switcher Ganti Bohlam Baru
              Container(
                padding: const EdgeInsets.all(16),
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
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Ganti Bohlam Baru?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F3460),
                    ),
                  ),
                  subtitle: const Text(
                    'Aktifkan jika melakukan pergantian fisik bohlam/lampu.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _gantiBohlamBaru,
                  onChanged: (val) => setState(() => _gantiBohlamBaru = val),
                  activeColor: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 20),

              // Card Form Input Perawatan
              Container(
                padding: const EdgeInsets.all(16),
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
                    const Text(
                      'Detail Perawatan & Spesifikasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F3460),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _statusTerpilih,
                      decoration: InputDecoration(
                        labelText: 'Status Lampu Saat Ini',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      items: _listStatus
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _statusTerpilih = val!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _merkCtrl,
                      decoration: InputDecoration(
                        labelText: 'Merk Lampu Baru / Saat Ini',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lightbulb_outline),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
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
                            decoration: InputDecoration(
                              labelText: 'Jenis Lampu',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            items: _listJenisLampu
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
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
                            decoration: InputDecoration(
                              labelText: 'Watt',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
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
                      decoration: InputDecoration(
                        labelText: 'Nama Petugas Perawatan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _catatanCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catatan Perawatan / Penyebab Rusak',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanPerubahan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
