import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FormPemeriksaanScreen extends StatefulWidget {
  final String docIdBarang;
  final String namaBarang;
  final String lokasi;
  final String? noApar;
  final List<String> checklistItems;
  final Map<String, dynamic>? initialDefisit; // <-- TAMBAHAN
  final Map<String, dynamic>? initialKadaluarsa; // <-- TAMBAHAN

  const FormPemeriksaanScreen({
    super.key,
    required this.docIdBarang,
    required this.namaBarang,
    required this.lokasi,
    this.noApar,
    required this.checklistItems,
    this.initialDefisit,
    this.initialKadaluarsa,
  });

  @override
  State<FormPemeriksaanScreen> createState() => _FormPemeriksaanScreenState();
}

class _FormPemeriksaanScreenState extends State<FormPemeriksaanScreen> {
  final Map<String, Map<String, dynamic>> _checklistResults = {};

  final TextEditingController _petugasController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};
  bool _isLoading = false;
  bool _isP3K = false;

  @override
  void dispose() {
    _petugasController.dispose();
    _catatanController.dispose();
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isP3K = widget.checklistItems.any(
      (item) => item.toLowerCase().contains('kasa steril'),
    );

    for (var item in widget.checklistItems) {
      if (_isP3K) {
        bool isLiquid =
            item.toLowerCase().contains('aquades') ||
            item.toLowerCase().contains('povidone') ||
            item.toLowerCase().contains('alkohol');

        if (isLiquid) {
          // Otomatis isi tanggal kadaluarsa sesuai data master saat ini
          String savedExp = widget.initialKadaluarsa?[item] ?? '-';
          if (savedExp.isEmpty) savedExp = '-';
          _checklistResults[item] = {'status': 'Ada', 'nilai': savedExp};
        } else {
          int savedDefisit = widget.initialDefisit?[item] ?? 0;
          int initialVal = savedDefisit == 999 ? 0 : savedDefisit;
          _checklistResults[item] = {
            'status': savedDefisit == 999 ? 'Hilang' : 'Ada',
            'nilai': initialVal,
          };
          // --- INISIALISASI CONTROLLER ---
          _qtyControllers[item] = TextEditingController(
            text: initialVal.toString(),
          );
        }
      } else {
        _checklistResults[item] = {'status': 'Ada', 'nilai': true};
      }
    }
  }

  Future<void> _pickDate(String item) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _checklistResults[item]!['nilai'] = DateFormat(
          'dd/MM/yyyy',
        ).format(picked);
      });
    }
  }

  Future<void> _submitInspeksi() async {
    if (_petugasController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama Petugas wajib diisi!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Format Hasil Checklist
      Map<String, dynamic> formattedResults = {};
      _checklistResults.forEach((key, data) {
        if (data['status'] == 'Hilang') {
          formattedResults[key] = 'Hilang';
        } else {
          formattedResults[key] = data['nilai'];
        }
      });

      String catatanText = _catatanController.text.trim().isEmpty
          ? '-'
          : _catatanController.text.trim();

      // =========================================================
      // 2. SIMPAN KE RIWAYAT SECARA MANUAL (BYPASS SERVICE YANG ERROR)
      // =========================================================
      await FirebaseFirestore.instance.collection('riwayat_inspeksi').add({
        'docIdBarang': widget.docIdBarang,
        'id_barang': widget.docIdBarang,
        'nama_barang': widget.namaBarang,
        'kategori': _isP3K ? 'Kotak P3K' : 'APAR',
        'nama_pemeriksa': _petugasController.text.trim(),
        'tanggal': FieldValue.serverTimestamp(), // Catat waktu akurat
        'hasil_checklist': formattedResults,
        'catatan': catatanText,
        'lokasi': widget.lokasi,
      });

      // =========================================================
      // 3. UPDATE DATA MASTER (UNTUCH EXCEL) MENGGUNAKAN SET-MERGE
      // =========================================================
      Map<String, dynamic> masterUpdateData = {
        'tanggal_inspeksi': DateTime.now().toIso8601String(),
      };

      // --- OTOMATIS UBAH STATUS APAR BERDASARKAN HASIL CHECKLIST ---
      if (!_isP3K) {
        bool adaYangMerah = false;
        formattedResults.forEach((key, value) {
          // Jika ada checklist APAR yang bernilai false (merah) atau tidak normal
          if (value == false || value == 'Rusak' || value == 'Hilang') {
            adaYangMerah = true;
          }
        });

        // Jika ada yang merah otomatis jadi 'Butuh Perbaikan', jika aman jadi 'Tersedia'
        masterUpdateData['keterangan'] = adaYangMerah
            ? 'Butuh Perbaikan'
            : 'Tersedia';
      } else {
        // Untuk Kotak P3K, keterangan bebas diisi catatan temuan
        masterUpdateData['keterangan'] = catatanText;
      }

      if (_isP3K) {
        Map<String, int> defisitMap = {};
        Map<String, dynamic> kadaluarsaMap =
            {}; // Tambahkan penampung untuk kadaluarsa

        formattedResults.forEach((key, value) {
          // Deteksi apakah item ini adalah obat cairan (Aquades, Povidone, Alkohol)
          bool isLiquid =
              key.toLowerCase().contains('aquades') ||
              key.toLowerCase().contains('povidone') ||
              key.toLowerCase().contains('alkohol');

          if (isLiquid) {
            // Jika cairan statusnya Hilang, maka kadaluarsanya jadi kosong (-)
            if (value == 'Hilang') {
              kadaluarsaMap[key] = '-';
            } else {
              kadaluarsaMap[key] = value.toString();
            }
          } else {
            // Untuk barang fisik (Kasa, Perban, dll)
            if (value is int && value > 0) {
              defisitMap[key] = value;
            } else if (value == 'Hilang') {
              defisitMap[key] =
                  999; // Set ke 999 agar stok otomatis jadi 0 / 20
            }
          }
        });

        masterUpdateData['defisit_p3k'] = defisitMap;
        masterUpdateData['kadaluarsa_cairan'] =
            kadaluarsaMap; // Update masa kadaluarsa ke database
      }

      // Menggunakan SetOptions(merge: true) agar tidak pernah memicu error "not-found"
      String primaryCollection = _isP3K ? 'Kotak P3K' : 'APAR';
      await FirebaseFirestore.instance
          .collection(primaryCollection)
          .doc(widget.docIdBarang)
          .set(masterUpdateData, SetOptions(merge: true));

      // Jika kategori P3K, simpan juga ke koleksi "P3K" (Sesuai path error di screenshot)
      if (_isP3K) {
        await FirebaseFirestore.instance
            .collection('P3K')
            .doc(widget.docIdBarang)
            .set(masterUpdateData, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.pop(context); // Tutup Form
        Navigator.pop(context); // Kembali ke halaman list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspeksi Berhasil Disimpan & Excel Diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGET CHECKLIST P3K DENGAN STATUS ADA/HILANG & TRANSPARANSI ---
  Widget _buildP3kItemCard(String item) {
    bool isLiquid =
        item.toLowerCase().contains('aquades') ||
        item.toLowerCase().contains('povidone') ||
        item.toLowerCase().contains('alkohol');

    String status = _checklistResults[item]?['status'] ?? 'Ada';
    bool isHilang = status == 'Hilang';
    dynamic nilai = _checklistResults[item]?['nilai'] ?? (isLiquid ? '-' : 0);

    return Opacity(
      opacity: isHilang ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
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
          border: Border.all(
            color: isHilang ? Colors.red.shade300 : Colors.blue.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                // DROPDOWN STATUS ADA / HILANG
                Container(
                  height: 32, // <-- BATASI TINGGI AGAR TIDAK KEBESARAN
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isHilang ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(
                      8,
                    ), // Sudut membulat modern
                    border: Border.all(
                      color: isHilang ? Colors.red : Colors.green,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: status,
                    isDense:
                        true, // <-- PENTING: Membuat dropdown lebih ramping
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isHilang ? Colors.red : Colors.green,
                      size: 20, // Icon diperkecil
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHilang ? Colors.red : Colors.green,
                    ),
                    items: ['Ada', 'Hilang'].map((val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _checklistResults[item]!['status'] = val!;
                        if (val == 'Hilang' && !isLiquid) {
                          _checklistResults[item]!['nilai'] = 0;
                          _qtyControllers[item]!.text = '0';
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AbsorbPointer(
              absorbing: isHilang, // Nonaktifkan interaksi jika status Hilang
              child: isLiquid
                  ? Row(
                      children: [
                        const Text(
                          'Tanggal Kadaluarsa:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () => _pickDate(item),
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(nilai == '-' ? 'Atur Expired' : nilai),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: nilai == '-'
                                ? Colors.orange
                                : Colors.blue,
                            side: BorderSide(
                              color: nilai == '-' ? Colors.orange : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Text(
                          'Jumlah Kurang (Defisit):',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              // TOMBOL MINUS
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                color: Colors.red,
                                onPressed: nilai > 0
                                    ? () {
                                        int newVal = nilai - 1;
                                        setState(() {
                                          _checklistResults[item]!['nilai'] =
                                              newVal;
                                          _qtyControllers[item]!.text = newVal
                                              .toString();
                                        });
                                      }
                                    : null,
                              ),
                              // TEXTFIELD MANUAL INPUT
                              SizedBox(
                                width: 35,
                                child: TextField(
                                  controller: _qtyControllers[item],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: nilai > 0
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    int parsed = int.tryParse(val) ?? 0;
                                    setState(() {
                                      _checklistResults[item]!['nilai'] =
                                          parsed;
                                    });
                                  },
                                ),
                              ),
                              // TOMBOL PLUS
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                color: Colors.blue,
                                onPressed: () {
                                  int newVal = nilai + 1;
                                  setState(() {
                                    _checklistResults[item]!['nilai'] = newVal;
                                    _qtyControllers[item]!.text = newVal
                                        .toString();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET APAR (SWITCH) ---
  Widget _buildSwitchItem(String item) {
    bool val = _checklistResults[item]?['nilai'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Switch(
            value: val,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            inactiveTrackColor: Colors.red.shade200,
            onChanged: (v) {
              setState(() => _checklistResults[item]!['nilai'] = v);
            },
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
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: const Text(
          'Form Inspeksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text(
                    widget.namaBarang,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.lokasi,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              'Petugas Inspeksi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _petugasController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama Anda...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              'Checklist Pemeriksaan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 10),

            if (_isP3K)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pilih status "Hilang" untuk menandakan barang tidak ada di tempat (form akan terkunci otomatis). Atur jumlah kurang atau tanggal kadaluarsa untuk barang yang ada.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

            ...widget.checklistItems.map((item) {
              if (_isP3K) {
                return _buildP3kItemCard(item);
              } else {
                return _buildSwitchItem(item);
              }
            }).toList(),

            const SizedBox(height: 20),
            const Text(
              'Catatan Temuan (Opsional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Beberapa plester sudah menguning...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitInspeksi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF149C94),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
                label: Text(
                  _isLoading ? 'Menyimpan...' : 'Submit Hasil Inspeksi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
