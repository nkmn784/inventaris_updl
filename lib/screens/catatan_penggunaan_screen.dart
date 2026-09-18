import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatatanPenggunaanScreen extends StatefulWidget {
  final String docIdBarang;
  final String namaKotak;

  const CatatanPenggunaanScreen({
    super.key,
    required this.docIdBarang,
    required this.namaKotak,
  });

  @override
  State<CatatanPenggunaanScreen> createState() =>
      _CatatanPenggunaanScreenState();
}

class _CatatanPenggunaanScreenState extends State<CatatanPenggunaanScreen> {
  // Daftar 21 item P3K untuk dipilih user
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

  void _showAddCatatanDialog(BuildContext context) {
    // List dinamis untuk menampung banyak barang sekaligus
    List<Map<String, dynamic>> listPemakaian = [
      {'item': _daftarItemP3K[4], 'qty': TextEditingController(text: '1')},
    ];

    TextEditingController pemakaiController = TextEditingController();
    TextEditingController keperluanController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Catat Penggunaan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Pemakai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: pemakaiController,
                      decoration: const InputDecoration(
                        hintText: 'Misal: Budi (Teknisi)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      'Barang yang Dipakai & Jumlah',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // RENDER MULTI INPUT BARANG
                    Column(
                      children: listPemakaian.map((pemakaian) {
                        int index = listPemakaian.indexOf(pemakaian);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: pemakaian['item'],
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _daftarItemP3K
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(
                                            item,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setDialogState(
                                    () => pemakaian['item'] = val!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: pemakaian['qty'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    hintText: 'Qty',
                                  ),
                                ),
                              ),
                              if (listPemakaian.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setDialogState(
                                    () => listPemakaian.removeAt(index),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    // TOMBOL TAMBAH BARANG LAIN
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          listPemakaian.add({
                            'item': _daftarItemP3K[4],
                            'qty': TextEditingController(text: '1'),
                          });
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Barang Lain'),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Keperluan / Keluhan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: keperluanController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Misal: Mengobati luka tergores',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF149C94),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (pemakaiController.text.trim().isEmpty ||
                              keperluanController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama & Keperluan wajib diisi!'),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            // 1. Simpan setiap barang ke Log Penggunaan (Buku Catatan)
                            for (var item in listPemakaian) {
                              await FirebaseFirestore.instance
                                  .collection('buku_catatan_p3k')
                                  .add({
                                    'id_kotak': widget.docIdBarang,
                                    'nama_kotak': widget.namaKotak,
                                    'nama_pemakai': pemakaiController.text
                                        .trim(),
                                    'item_dipakai': item['item'],
                                    'jumlah':
                                        int.tryParse(item['qty'].text) ?? 1,
                                    'keperluan': keperluanController.text
                                        .trim(),
                                    'tanggal_penggunaan':
                                        FieldValue.serverTimestamp(),
                                  });
                            }

                            // 2. Pemotongan Stok Gabungan ke Master Inventaris (Firebase Transaction)
                            DocumentReference docRef = FirebaseFirestore
                                .instance
                                .collection('Kotak P3K')
                                .doc(widget.docIdBarang);
                            await FirebaseFirestore.instance.runTransaction((
                              transaction,
                            ) async {
                              DocumentSnapshot snapshot = await transaction.get(
                                docRef,
                              );
                              if (snapshot.exists) {
                                Map<String, dynamic> data =
                                    snapshot.data() as Map<String, dynamic>;
                                Map<String, dynamic> defisit =
                                    data['defisit_p3k'] != null
                                    ? Map<String, dynamic>.from(
                                        data['defisit_p3k'],
                                      )
                                    : {};

                                // Tambahkan semua barang yang dipakai ke daftar defisit
                                for (var item in listPemakaian) {
                                  String namaBarang = item['item'];
                                  int qtyDipakai =
                                      int.tryParse(item['qty'].text) ?? 1;
                                  defisit[namaBarang] =
                                      (defisit[namaBarang] ?? 0) + qtyDipakai;
                                }

                                transaction.update(docRef, {
                                  'defisit_p3k': defisit,
                                  'keterangan': 'Butuh Restock',
                                });
                              }
                            });

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Catatan & Stok P3K berhasil diupdate!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50, // <-- UPDATE WARNA BACKGROUND
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade900, // <-- UPDATE WARNA APPBAR
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buku Catatan P3K',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.namaKotak,
              style: TextStyle(
                color: Colors.blue.shade200,
                fontSize: 12,
              ), // <-- WARNA SUBTITLE
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('buku_catatan_p3k')
            .where('id_kotak', isEqualTo: widget.docIdBarang)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada catatan penggunaan.'));
          }

          // --- TAMBAHKAN LOGIKA SORTING DISINI ---
          var docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? tglA = dataA['tanggal_penggunaan'] as Timestamp?;
            Timestamp? tglB = dataB['tanggal_penggunaan'] as Timestamp?;

            if (tglA == null && tglB == null) return 0;
            if (tglA == null) return 1;
            if (tglB == null) return -1;
            return tglB.compareTo(
              tglA,
            ); // Urutkan Descending (Terbaru ke Terlama)
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              DateTime? tgl = (data['tanggal_penggunaan'] as Timestamp?)
                  ?.toDate();
              String formatTgl = tgl != null
                  ? '${tgl.day}/${tgl.month}/${tgl.year} ${tgl.hour}:${tgl.minute.toString().padLeft(2, '0')}'
                  : '-';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${data['item_dipakai']} (${data['jumlah']})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F3460),
                              ),
                            ),
                          ),
                          Text(
                            formatTgl,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        'Pemakai: ${data['nama_pemakai']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Keperluan: ${data['keperluan']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade800, // <-- UPDATE WARNA TOMBOL
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Catat Pemakaian',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddCatatanDialog(context),
      ),
    );
  }
}
