import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tambah_barang_dinamis_screen.dart';
import 'edit_barang_dinamis_screen.dart';
import 'package:flutter/services.dart'; // Untuk fitur Salin (Clipboard)
import 'package:url_launcher/url_launcher.dart'; // Untuk membuka Google Maps

class DaftarBarangDinamisScreen extends StatefulWidget {
  final String namaKategori;
  final List<dynamic> skemaForm;

  const DaftarBarangDinamisScreen({
    super.key,
    required this.namaKategori,
    required this.skemaForm,
  });

  @override
  State<DaftarBarangDinamisScreen> createState() =>
      _DaftarBarangDinamisScreenState();
}

class _DaftarBarangDinamisScreenState extends State<DaftarBarangDinamisScreen> {
  String _searchQuery = '';
  late Stream<QuerySnapshot> _streamBarang;

  @override
  void initState() {
    super.initState();
    _streamBarang = FirebaseFirestore.instance
        .collection(widget.namaKategori)
        .snapshots();
  }

  // --- POPUP DETAIL BARANG (DIPERBAIKI AGAR LEBIH KEMAS & PROFESIONAL) ---
  void _tampilkanDetail(Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. JUDUL POPUP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail ${widget.namaKategori}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3460),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 10),

              // 2. KONTEN DETAIL (BISA DI-SCROLL)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.skemaForm.map((field) {
                      String label = field['label'];
                      String tipe = field['tipe_input'];
                      dynamic nilai = data[label];
                      // TAMPILAN KHUSUS UNTUK TITIK KOORDINAT (GPS) DENGAN TOMBOL SALIN & MAPS
                      if (tipe == 'Titik Koordinat (GPS)') {
                        String koordinatStr = nilai?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        koordinatStr.isEmpty
                                            ? 'Koordinat belum diisi'
                                            : koordinatStr,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (koordinatStr.isNotEmpty &&
                                        !koordinatStr.startsWith('Gagal') &&
                                        !koordinatStr.startsWith(
                                          'Mengambil',
                                        )) ...[
                                      // Tombol Salin (Copy)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.copy,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Salin Koordinat',
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: koordinatStr),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Koordinat berhasil disalin ke clipboard!',
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                      // Tombol Buka Google Maps
                                      IconButton(
                                        icon: const Icon(
                                          Icons.map_outlined,
                                          size: 20,
                                          color: Colors.green,
                                        ),
                                        tooltip: 'Buka di Google Maps',
                                        onPressed: () async {
                                          final Uri url = Uri.parse(
                                            'https://www.google.com/maps/search/?api=1&query=$koordinatStr',
                                          );
                                          try {
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(
                                                url,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } else {
                                              throw 'Tidak dapat membuka peta';
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Gagal membuka Maps: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Tampilan Foto
                      if (tipe == 'Foto / Kamera' &&
                          nilai != null &&
                          nilai.toString().isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  nilai.toString(),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Tampilan Grup Berulang (Kartu List Penuh & Kemas)
                      if (tipe == 'Grup Berulang (List Aset)' &&
                          nilai is List) {
                        List<dynamic> subFields = field['sub_form'] ?? [];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (nilai.isEmpty) const Text('-'),
                              ...List.generate(nilai.length, (index) {
                                var item = nilai[index];
                                if (item is Map) {
                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header Nombor Item
                                        Text(
                                          'Item #${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                        const Divider(
                                          height: 12,
                                          color: Colors.orange,
                                        ),
                                        // Susunan Sub-field (Label di kiri, Nilai di kanan)
                                        ...subFields.map<Widget>((subKey) {
                                          String keyStr = subKey.toString();
                                          String valueStr =
                                              item[keyStr]?.toString() ?? '-';
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 110,
                                                  child: Text(
                                                    '$keyStr:',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    valueStr,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black87,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox();
                              }).toList(),
                            ],
                          ),
                        );
                      }

                      // Tampilan Normal (Teks, Angka, Dropdown, dll)
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nilai?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(height: 10),

              // 3. TOMBOL AKSI DI BAWAH (HAPUS & EDIT)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Hapus Data?'),
                            content: const Text(
                              'Tindakan ini tidak dapat dibatalkan.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection(widget.namaKategori)
                              .doc(docId)
                              .delete();
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data Berjaya Dihapus!'),
                              ),
                            );
                        }
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 18,
                      ),
                      label: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditBarangDinamisScreen(
                              namaKategori: widget.namaKategori,
                              documentId: docId,
                              dataLama: data,
                              skemaForm: widget.skemaForm,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? fieldJudul;
    String? fieldSubjudul;

    if (widget.skemaForm.isNotEmpty) {
      fieldJudul = widget.skemaForm[0]['label'];
      if (widget.skemaForm.length > 1) {
        fieldSubjudul = widget.skemaForm[1]['label'];
      }
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(widget.namaKategori),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        // Tombol Download Dihapus dari Sini
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 30.0,
              top: 16.0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade600],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(76),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari di ${widget.namaKategori}...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamBarang,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(
                    child: Text('Belum ada data di ${widget.namaKategori}'),
                  );

                var dokumen = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String semuaTeks = data.values.toString().toLowerCase();
                  return semuaTeks.contains(_searchQuery);
                }).toList();

                if (dokumen.isEmpty)
                  return const Center(child: Text('Barang tidak ditemukan'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dokumen.length,
                  itemBuilder: (context, index) {
                    var data = dokumen[index].data() as Map<String, dynamic>;
                    String judul = fieldJudul != null
                        ? (data[fieldJudul]?.toString() ?? 'Data Kosong')
                        : 'Item ${index + 1}';
                    String subjudul = fieldSubjudul != null
                        ? '$fieldSubjudul: ${data[fieldSubjudul]?.toString() ?? '-'}'
                        : 'Detail...';

                    // Kalau Subjudulnya adalah List (Grup Berulang), potong kalimatnya biar rapi
                    if (data[fieldSubjudul] is List) {
                      subjudul =
                          '$fieldSubjudul: ${(data[fieldSubjudul] as List).length} Item Tersimpan';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            Icons.inventory,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        title: Text(
                          judul,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F3460),
                          ),
                        ),
                        subtitle: Text(
                          subjudul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _tampilkanDetail(data, dokumen[index].id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahBarangDinamisScreen(
                namaKategori: widget.namaKategori,
                skemaForm: widget.skemaForm,
              ),
            ),
          );
        },
      ),
    );
  }
}
