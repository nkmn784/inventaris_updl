import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicCatatanScreen extends StatefulWidget {
  final String? initialKotakId; // Opsional: Untuk QR Code spesifik

  const PublicCatatanScreen({super.key, this.initialKotakId});

  @override
  State<PublicCatatanScreen> createState() => _PublicCatatanScreenState();
}

class _PublicCatatanScreenState extends State<PublicCatatanScreen> {
  String? selectedKotakId;
  String? selectedNamaKotak;

  final List<String> _daftarItemP3K = [
    'Kasa Steril',
    'Perban (Lebar 5 cm)',
    'Perban (Lebar 10 cm)',
    'Plester Lebar 1,25 cm',
    'Plester Cepat',
    'Kapas 25 gr',
    'Kain Segi Tiga (Mitela)',
    'Gunting',
    'Peniti',
    'Sarung Tangan Sekali Pakai',
    'Sarung Tangan (Pasangan)',
    'Masker',
    'Pinset',
    'Lampu Senter',
    'Gelas Cuci Mata',
    'Kantong Plastik Bersih',
    'Aquades',
    'Povidone Iodine',
    'Alkohol 70%',
    'Buku Panduan P3K',
    'Buku Catatan & Daftar Isi',
  ];

  List<Map<String, dynamic>> listPemakaian = [];
  TextEditingController pemakaiController = TextEditingController();
  TextEditingController keperluanController = TextEditingController();
  TextEditingController _displayKotakController =
      TextEditingController(); // Controller untuk tampilan input cari kotak

  bool isSaving = false;
  bool isSuccess = false;

  @override
  void initState() {
    super.initState();
    selectedKotakId = widget.initialKotakId;
    listPemakaian.add({
      'item': _daftarItemP3K[4],
      'qty': TextEditingController(text: '1'),
    });
  }

  @override
  void dispose() {
    pemakaiController.dispose();
    keperluanController.dispose();
    _displayKotakController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (selectedKotakId == null ||
        pemakaiController.text.trim().isEmpty ||
        keperluanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kotak dan isi semua kolom wajib!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // 1. Simpan ke Buku Catatan P3K
      for (var item in listPemakaian) {
        await FirebaseFirestore.instance.collection('buku_catatan_p3k').add({
          'id_kotak': selectedKotakId,
          'nama_kotak': selectedNamaKotak,
          'nama_pemakai': pemakaiController.text.trim(),
          'item_dipakai': item['item'],
          'jumlah': int.tryParse(item['qty'].text) ?? 1,
          'keperluan': keperluanController.text.trim(),
          'tanggal_penggunaan': FieldValue.serverTimestamp(),
        });
      }

      // 2. Potong Stok Real-Time ke Master Inventaris (Collection 'Kotak P3K')
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('Kotak P3K')
          .doc(selectedKotakId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          Map<String, dynamic> defisit = data['defisit_p3k'] != null
              ? Map<String, dynamic>.from(data['defisit_p3k'])
              : {};

          for (var item in listPemakaian) {
            String namaBarang = item['item'];
            int qtyDipakai = int.tryParse(item['qty'].text) ?? 1;
            defisit[namaBarang] = (defisit[namaBarang] ?? 0) + qtyDipakai;
          }

          transaction.update(docRef, {
            'defisit_p3k': defisit,
            'keterangan': 'Butuh Restock',
          });
        }
      });

      setState(() {
        isSaving = false;
        isSuccess = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => isSaving = false);
    }
  }

  // === FITUR BARU: DIALOG PENCARIAN KOTAK P3K ===
  void _showSearchKotakDialog(List<QueryDocumentSnapshot> docs) {
    String localSearchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar bisa full screen dikurangi jarak atas
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Logika Filter Data
            var filteredDocs = docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              var spec = data['spesifikasi'] ?? {};
              String noP3k = (spec['No P3K'] ?? '').toString().toLowerCase();
              String nama = (data['nama_barang'] ?? '')
                  .toString()
                  .toLowerCase();
              String lokasi = (data['lokasi'] ?? '').toString().toLowerCase();
              String query = localSearchQuery.toLowerCase();

              return noP3k.contains(query) ||
                  nama.contains(query) ||
                  lokasi.contains(query);
            }).toList();

            // Mengurutkan berdasarkan Nomor Kotak (jika memungkinkan)
            filteredDocs.sort((a, b) {
              var specA =
                  (a.data() as Map<String, dynamic>)['spesifikasi'] ?? {};
              var specB =
                  (b.data() as Map<String, dynamic>)['spesifikasi'] ?? {};
              int noA =
                  int.tryParse(
                    (specA['No P3K'] ?? '0').toString().replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    ),
                  ) ??
                  0;
              int noB =
                  int.tryParse(
                    (specB['No P3K'] ?? '0').toString().replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    ),
                  ) ??
                  0;
              return noA.compareTo(noB);
            });

            return FractionallySizedBox(
              heightFactor: 0.85, // Mengambil 85% tinggi layar
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: 16,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  children: [
                    // Handle Bar Atas
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Pilih Kotak P3K',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF0F3460),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Input Cari Kotak
                    TextField(
                      autofocus: true, // Otomatis memunculkan keyboard
                      decoration: InputDecoration(
                        hintText: 'Cari nomor, nama kotak, atau lokasi...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF149C94),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF149C94),
                            width: 2,
                          ),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          localSearchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Daftar Hasil Kotak
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? const Center(
                              child: Text(
                                'Kotak P3K tidak ditemukan.\nPastikan nomor atau nama sudah benar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                var doc = filteredDocs[index];
                                var data = doc.data() as Map<String, dynamic>;
                                var spec = data['spesifikasi'] ?? {};
                                String noP3k = spec['No P3K'] ?? '-';
                                String nama =
                                    data['nama_barang'] ?? 'Kotak P3K';
                                String lokasi = data['lokasi'] ?? '-';

                                return Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(
                                        0xFF149C94,
                                      ).withOpacity(0.1),
                                      child: Text(
                                        noP3k,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF149C94),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      nama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF0F3460),
                                      ),
                                    ),
                                    subtitle: Text(
                                      lokasi,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedKotakId = doc.id;
                                        selectedNamaKotak =
                                            'Kotak No.$noP3k ($nama - $lokasi)';
                                        _displayKotakController.text =
                                            selectedNamaKotak!;
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSuccess) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F8FF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 100),
                const SizedBox(height: 20),
                const Text(
                  'Laporan Tersimpan!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F3460),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Penggunaan untuk kotak "$selectedNamaKotak" berhasil dicatat dan stok telah diperbarui.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3460),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isSuccess = false;
                        pemakaiController.clear();
                        keperluanController.clear();
                        _displayKotakController.clear();
                        selectedKotakId = null;
                        selectedNamaKotak = null;
                        listPemakaian = [
                          {
                            'item': _daftarItemP3K[4],
                            'qty': TextEditingController(text: '1'),
                          },
                        ];
                      });
                    },
                    child: const Text(
                      'Buat Catatan Lain',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali ke Menu Utama'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF149C94),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Catat Pemakaian P3K',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF149C94),
              padding: const EdgeInsets.only(bottom: 25, left: 20, right: 20),
              child: const Column(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Pusat Pelaporan P3K PLN UPDL Pandaan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Silakan pilih atau cari lokasi kotak P3K yang Anda gunakan di bawah ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Lokasi / Nama Kotak P3K',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // STREAM BUILDER UNTUK MENGAMBIL LIST KOTAK
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Kotak P3K')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator(
                          color: Color(0xFF149C94),
                        );

                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text(
                          'Belum ada Kotak P3K terdaftar.',
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      // Jika initialKotakId via QR diberikan, isi data otomatis di background
                      if (selectedKotakId != null &&
                          selectedNamaKotak == null) {
                        try {
                          var doc = docs.firstWhere(
                            (d) => d.id == selectedKotakId,
                          );
                          var dataMap = doc.data() as Map<String, dynamic>;
                          var spec = dataMap['spesifikasi'] ?? {};
                          String noP3k = spec['No P3K'] ?? '-';
                          selectedNamaKotak =
                              'Kotak No.$noP3k (${dataMap['nama_barang']} - ${dataMap['lokasi']})';

                          // Hindari update UI selagi proses build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _displayKotakController.text = selectedNamaKotak!;
                          });
                        } catch (_) {
                          selectedKotakId = null;
                        }
                      }

                      // MENGGUNAKAN TEXT FIELD READONLY SEBAGAI TRIGGER BOTTOM SHEET
                      return TextFormField(
                        controller: _displayKotakController,
                        readOnly: true, // Tidak bisa diketik langsung
                        onTap: () => _showSearchKotakDialog(
                          docs,
                        ), // Munculkan dialog pencarian
                        decoration: InputDecoration(
                          hintText: '-- Cari & Pilih Kotak P3K --',
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Nama Lengkap (Pemakai)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pemakaiController,
                    decoration: InputDecoration(
                      hintText: 'Misal: Budi (Teknisi)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Barang yang Diambil',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ...listPemakaian.map((pemakaian) {
                    int index = listPemakaian.indexOf(pemakaian);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: pemakaian['item'],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              items: _daftarItemP3K
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => pemakaian['item'] = val!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: pemakaian['qty'],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Qty',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ),
                          if (listPemakaian.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  setState(() => listPemakaian.removeAt(index)),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        listPemakaian.add({
                          'item': _daftarItemP3K[4],
                          'qty': TextEditingController(text: '1'),
                        });
                      });
                    },
                    icon: const Icon(Icons.add, color: Color(0xFF149C94)),
                    label: const Text(
                      'Tambah Alat Lain',
                      style: TextStyle(color: Color(0xFF149C94)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'Keperluan / Keluhan / Kejadian',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: keperluanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Misal: Mengobati luka gores di tangan.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F3460),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isSaving ? null : _submitData,
                      icon: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        isSaving ? 'Menyimpan...' : 'Simpan Laporan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
