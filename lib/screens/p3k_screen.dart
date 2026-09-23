import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import 'form_pemeriksaan_screen.dart';
import 'catatan_penggunaan_screen.dart';

class P3kScreen extends StatefulWidget {
  final bool isAdmin;
  const P3kScreen({super.key, this.isAdmin = true});

  @override
  State<P3kScreen> createState() => _P3kScreenState();
}

class _P3kScreenState extends State<P3kScreen> {
  String _searchQuery = '';

  // ✔️ 1. Deklarasikan variabel stream
  late Stream<QuerySnapshot> _p3kStream;

  // ✔️ 2. Inisialisasi stream di dalam initState agar hanya dipanggil 1 kali
  @override
  void initState() {
    super.initState();
    _p3kStream = FirestoreService().getBarangByKategori('Kotak P3K');
  }

  // --- DIALOG TAMBAH KOTAK P3K ---
  void _showAddP3kDialog(BuildContext context) {
    TextEditingController namaController = TextEditingController();
    TextEditingController nomorP3kController = TextEditingController();
    TextEditingController lokasiController = TextEditingController();
    TextEditingController koordinatController = TextEditingController();

    // Controller Tanggal Kadaluarsa 3 Cairan P3K
    TextEditingController expAquadesController = TextEditingController();
    TextEditingController expPovidoneController = TextEditingController();
    TextEditingController expAlkoholController = TextEditingController();

    String selectedTipeP3K = 'Tipe A (25 Orang)';
    int quantity = 1;
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    final ImagePicker picker = ImagePicker();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> _pilihDanCropFoto(ImageSource source) async {
              try {
                final img = await picker.pickImage(
                  source: source,
                  imageQuality: 80,
                );
                if (img == null) return;
                final bytes = await img.readAsBytes();

                if (kIsWeb) {
                  setDialogState(() {
                    selectedImageBytes = bytes;
                    selectedImageName = img.name;
                  });
                  return;
                }

                try {
                  CroppedFile? croppedFile = await ImageCropper().cropImage(
                    sourcePath: img.path,
                    uiSettings: [
                      AndroidUiSettings(
                        toolbarTitle: 'Crop Foto P3K',
                        toolbarColor: const Color(0xFF0F3460),
                        toolbarWidgetColor: Colors.white,
                        initAspectRatio: CropAspectRatioPreset.ratio4x3,
                        lockAspectRatio: false,
                      ),
                      IOSUiSettings(title: 'Crop Foto P3K'),
                    ],
                  );

                  if (croppedFile != null) {
                    final croppedBytes = await croppedFile.readAsBytes();
                    setDialogState(() {
                      selectedImageBytes = croppedBytes;
                      selectedImageName = 'cropped_image.jpg';
                    });
                  } else {
                    setDialogState(() {
                      selectedImageBytes = bytes;
                      selectedImageName = img.name;
                    });
                  }
                } catch (_) {
                  setDialogState(() {
                    selectedImageBytes = bytes;
                    selectedImageName = img.name;
                  });
                }
              } catch (_) {}
            }

            void _bukaPilihanSumberFoto() {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (bc) => SafeArea(
                  child: Wrap(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Pilih Sumber Foto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                        ),
                        title: const Text('Ambil dari Kamera'),
                        onTap: () {
                          Navigator.pop(bc);
                          _pilihDanCropFoto(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.photo_library,
                          color: Colors.green,
                        ),
                        title: const Text('Pilih dari Galeri'),
                        onTap: () {
                          Navigator.pop(bc);
                          _pilihDanCropFoto(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            Future<void> _fetchCurrentLocation() async {
              setDialogState(
                () => koordinatController.text = "Mengambil GPS...",
              );
              try {
                bool serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  setDialogState(() => koordinatController.text = "GPS Mati");
                  return;
                }
                LocationPermission permission =
                    await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                }
                Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.best,
                );
                setDialogState(
                  () => koordinatController.text =
                      "${position.latitude}, ${position.longitude}",
                );
              } catch (e) {
                setDialogState(() => koordinatController.text = "Gagal GPS");
              }
            }

            Future<void> _pickDate(TextEditingController controller) async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setDialogState(() {
                  controller.text = DateFormat('dd/MM/yyyy').format(picked);
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tambah Kotak P3K',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F3460),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Foto Kotak P3K',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: isSaving ? null : _bukaPilihanSumberFoto,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  selectedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.grey),
                                  SizedBox(height: 5),
                                  Text(
                                    'Tap untuk Pilih Foto',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nomorP3kController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Kotak P3K (Contoh: 1)',
                      ),
                    ),
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kotak / Ruangan (Contoh: P3K Lobby)',
                      ),
                    ),
                    TextField(
                      controller: lokasiController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Gedung',
                      ),
                    ),
                    TextField(
                      controller: koordinatController,
                      decoration: InputDecoration(
                        labelText: 'Koordinat GPS',
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                          ),
                          onPressed: _fetchCurrentLocation,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tipe Standar Permenaker',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedTipeP3K,
                      items:
                          [
                                'Tipe A (25 Orang)',
                                'Tipe B (50 Orang)',
                                'Tipe C (100 Orang)',
                              ]
                              .map(
                                (val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(val),
                                ),
                              )
                              .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedTipeP3K = val!),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Masa Kadaluarsa Cairan P3K',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: expAquadesController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Exp. Aquades (25ml)',
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () => _pickDate(expAquadesController),
                    ),
                    TextFormField(
                      controller: expPovidoneController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Exp. Povidone Iodine',
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () => _pickDate(expPovidoneController),
                    ),
                    TextFormField(
                      controller: expAlkoholController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Exp. Alkohol 70%',
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () => _pickDate(expAlkoholController),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                // Hapus validasi selectedImageBytes == null
                                if (namaController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nama Kotak wajib diisi!'),
                                    ),
                                  );
                                  return;
                                }
                                setDialogState(() => isSaving = true);
                                try {
                                  // Pengecekan jika foto diisi baru jalankan Cloudinary
                                  String? url;
                                  if (selectedImageBytes != null) {
                                    url = await CloudinaryService()
                                        .uploadImageBytes(selectedImageBytes!);
                                  }

                                  String tipeHuruf =
                                      selectedTipeP3K.contains('A')
                                      ? 'A'
                                      : (selectedTipeP3K.contains('B')
                                            ? 'B'
                                            : 'C');
                                  await FirestoreService().tambahBarang(
                                    'Kotak P3K',
                                    {
                                      'nama_barang': namaController.text,
                                      'lokasi': lokasiController.text,
                                      'kategori': 'Kotak P3K',
                                      'koordinat': koordinatController.text,
                                      'stok': quantity,
                                      'image_url': url ?? '',
                                      'spesifikasi': {
                                        'No P3K': nomorP3kController.text,
                                        'Tipe': tipeHuruf,
                                        'Kapasitas Ruangan':
                                            selectedTipeP3K.contains('25')
                                            ? '25'
                                            : (selectedTipeP3K.contains('50')
                                                  ? '50'
                                                  : '100'),
                                      },
                                      'kadaluarsa_cairan': {
                                        'Aquades': expAquadesController.text,
                                        'Povidone Iodine':
                                            expPovidoneController.text,
                                        'Alkohol 70%':
                                            expAlkoholController.text,
                                      },
                                    },
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Kotak P3K berhasil ditambahkan!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  setDialogState(() => isSaving = false);
                                }
                              },
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Simpan Kotak P3K',
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
            );
          },
        );
      },
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
          'Manajemen Kotak P3K',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            ),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama kotak atau ruangan...',
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
              stream: _p3kStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada data Kotak P3K',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                List<QueryDocumentSnapshot> items = snapshot.data!.docs.where((
                  doc,
                ) {
                  var data = doc.data() as Map<String, dynamic>;
                  var spec = data['spesifikasi'] ?? {}; // Ambil spesifikasi
                  String noP3k = spec['No P3K'] ?? ''; // Ambil nomor P3K
                  String str = '${data['nama_barang']} ${data['lokasi']} $noP3k'
                      .toLowerCase();
                  return str.contains(_searchQuery);
                }).toList();

                // --- MENGURUTKAN KOTAK P3K BERDASARKAN NOMOR ---
                items.sort((a, b) {
                  var specA =
                      (a.data() as Map<String, dynamic>)['spesifikasi'] ?? {};
                  var specB =
                      (b.data() as Map<String, dynamic>)['spesifikasi'] ?? {};

                  // Ambil nomor P3K, hilangkan huruf/spasi agar bisa diurutkan sebagai angka murni
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
                // -----------------------------------------------

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var data = items[index].data() as Map<String, dynamic>;
                    String docId = items[index].id;

                    // --- CEK APAKAH ADA DEFISIT / BUTUH ISI ULANG ---
                    Map<String, dynamic> defisitMap = Map<String, dynamic>.from(
                      data['defisit_p3k'] ?? {},
                    );
                    bool butuhIsiUlang = false;
                    defisitMap.forEach((k, v) {
                      if (v is int && v > 0) butuhIsiUlang = true;
                    });
                    bool sudahInspeksiBulanIni = false;
                    if (data['tanggal_inspeksi'] != null) {
                      DateTime? tglTerakhir;
                      if (data['tanggal_inspeksi'] is Timestamp) {
                        tglTerakhir = (data['tanggal_inspeksi'] as Timestamp)
                            .toDate();
                      } else {
                        tglTerakhir = DateTime.tryParse(
                          data['tanggal_inspeksi'].toString(),
                        );
                      }

                      if (tglTerakhir != null) {
                        DateTime now = DateTime.now();
                        if (tglTerakhir.month == now.month &&
                            tglTerakhir.year == now.year) {
                          sudahInspeksiBulanIni = true;
                        }
                      }
                    }
                    // --------------------------
                    var spec = data['spesifikasi'] ?? {};
                    String tipe = spec['Tipe'] ?? 'A';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                        border: Border(
                          left: BorderSide(
                            color: Colors.blue.shade700,
                            width: 5,
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailP3kScreen(
                                  docId: docId,
                                  dataP3k: data,
                                  isAdmin: widget.isAdmin,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child:
                                        data['image_url'] != null &&
                                            data['image_url'] != ''
                                        ? Image.network(
                                            data['image_url'],
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.medical_services,
                                            color: Colors.blue.shade700,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kotak P3K No. ${spec['No P3K'] ?? '-'} (${data['nama_barang'] ?? 'Tanpa Nama'})', // <-- UBAH BAGIAN INI
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tipe: $tipe • Lokasi: ${data['lokasi'] ?? '-'}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // --- UBAH DARI BAGIAN INI (Sebelumnya hanya ada ikon panah) ---
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // 1. Badge Status Inspeksi
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sudahInspeksiBulanIni
                                            ? Colors.blue.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        sudahInspeksiBulanIni
                                            ? 'Sudah Inspeksi'
                                            : 'Belum Inspeksi',
                                        style: TextStyle(
                                          color: sudahInspeksiBulanIni
                                              ? Colors.blue.shade700
                                              : Colors.orange.shade900,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // 2. Badge Status Barang (Butuh Isi Ulang / Aman) <-- TAMBAHAN BARU
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: butuhIsiUlang
                                            ? Colors.red.shade50
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        butuhIsiUlang
                                            ? 'Butuh Isi Ulang'
                                            : 'Aman',
                                        style: TextStyle(
                                          color: butuhIsiUlang
                                              ? Colors.red.shade700
                                              : Colors.green.shade700,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.blue.shade800,
              onPressed: () => _showAddP3kDialog(context),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// --- HALAMAN DETAIL KOTAK P3K & EDIT/HAPUS ---
class DetailP3kScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> dataP3k;
  final bool isAdmin;

  const DetailP3kScreen({
    super.key,
    required this.docId,
    required this.dataP3k,
    required this.isAdmin,
  });

  @override
  State<DetailP3kScreen> createState() => _DetailP3kScreenState();
}

class _DetailP3kScreenState extends State<DetailP3kScreen> {
  late Map<String, dynamic> currentData;

  @override
  void initState() {
    super.initState();
    currentData = Map.from(widget.dataP3k);
  }

  Future<void> _openGoogleMaps(String koordinat) async {
    if (koordinat.isEmpty || !koordinat.contains(',')) return;
    final Uri uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${koordinat.replaceAll(' ', '')}",
    );
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyCoordinates(BuildContext context, String koordinat) async {
    await Clipboard.setData(ClipboardData(text: koordinat));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat berhasil disalin!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditP3kDialog() {
    var spec = currentData['spesifikasi'] ?? {};
    var expCairan = currentData['kadaluarsa_cairan'] ?? {};

    TextEditingController nomorP3kController = TextEditingController(
      text: spec['No P3K'] ?? '',
    );
    TextEditingController namaController = TextEditingController(
      text: currentData['nama_barang'],
    );
    TextEditingController lokasiController = TextEditingController(
      text: currentData['lokasi'],
    );
    TextEditingController koordinatController = TextEditingController(
      text: currentData['koordinat'],
    );

    TextEditingController expAquadesController = TextEditingController(
      text: expCairan['Aquades'] ?? '',
    );
    TextEditingController expPovidoneController = TextEditingController(
      text: expCairan['Povidone Iodine'] ?? '',
    );
    TextEditingController expAlkoholController = TextEditingController(
      text: expCairan['Alkohol 70%'] ?? '',
    );

    String tipeAwal = spec['Tipe'] ?? 'A';
    String selectedTipeP3K = tipeAwal == 'B'
        ? 'Tipe B (50 Orang)'
        : (tipeAwal == 'C' ? 'Tipe C (100 Orang)' : 'Tipe A (25 Orang)');

    Uint8List? selectedImageBytes;
    final ImagePicker picker = ImagePicker();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> _pilihDanCropFotoEdit(ImageSource source) async {
              try {
                final img = await picker.pickImage(
                  source: source,
                  imageQuality: 80,
                );
                if (img == null) return;
                final bytes = await img.readAsBytes();

                if (kIsWeb) {
                  setDialogState(() {
                    selectedImageBytes = bytes;
                  });
                  return;
                }

                try {
                  CroppedFile? croppedFile = await ImageCropper().cropImage(
                    sourcePath: img.path,
                    uiSettings: [
                      AndroidUiSettings(
                        toolbarTitle: 'Crop Foto P3K',
                        toolbarColor: const Color(0xFF0F3460),
                        toolbarWidgetColor: Colors.white,
                      ),
                      IOSUiSettings(title: 'Crop Foto P3K'),
                    ],
                  );
                  if (croppedFile != null) {
                    final croppedBytes = await croppedFile.readAsBytes();
                    setDialogState(() {
                      selectedImageBytes = croppedBytes;
                    });
                  } else {
                    setDialogState(() {
                      selectedImageBytes = bytes;
                    });
                  }
                } catch (_) {
                  setDialogState(() {
                    selectedImageBytes = bytes;
                  });
                }
              } catch (_) {}
            }

            void _bukaPilihanSumberFoto() {
              showModalBottomSheet(
                context: dialogContext,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (bc) => SafeArea(
                  child: Wrap(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Ubah Sumber Foto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                        ),
                        title: const Text('Ambil dari Kamera'),
                        onTap: () {
                          Navigator.pop(bc);
                          _pilihDanCropFotoEdit(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.photo_library,
                          color: Colors.green,
                        ),
                        title: const Text('Pilih dari Galeri'),
                        onTap: () {
                          Navigator.pop(bc);
                          _pilihDanCropFotoEdit(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            Future<void> _pickDate(TextEditingController controller) async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setDialogState(() {
                  controller.text = DateFormat('dd/MM/yyyy').format(picked);
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Data Kotak P3K',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F3460),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: isSaving ? null : _bukaPilihanSumberFoto,
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  selectedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (currentData['image_url'] != null &&
                                  currentData['image_url']
                                      .toString()
                                      .isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  currentData['image_url'],
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                  Text(
                                    'Ubah Foto',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    TextField(
                      controller: nomorP3kController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Kotak P3K',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kotak / Ruangan',
                      ),
                    ),

                    TextField(
                      controller: lokasiController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Gedung',
                      ),
                    ),
                    TextField(
                      controller: koordinatController,
                      decoration: const InputDecoration(
                        labelText: 'Koordinat GPS',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedTipeP3K,
                      items:
                          [
                                'Tipe A (25 Orang)',
                                'Tipe B (50 Orang)',
                                'Tipe C (100 Orang)',
                              ]
                              .map(
                                (val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(val),
                                ),
                              )
                              .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedTipeP3K = val!),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Masa Kadaluarsa Cairan P3K',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: expAquadesController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Exp. Aquades (25ml)',
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () => _pickDate(expAquadesController),
                    ),
                    TextFormField(
                      controller: expPovidoneController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Exp. Povidone Iodine',
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () => _pickDate(expPovidoneController),
                    ),
                    TextFormField(
                      controller: expAlkoholController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Exp. Alkohol 70%',
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () => _pickDate(expAlkoholController),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setDialogState(() => isSaving = true);
                                try {
                                  String finalImageUrl =
                                      currentData['image_url'] ?? '';
                                  if (selectedImageBytes != null) {
                                    String? newUrl = await CloudinaryService()
                                        .uploadImageBytes(selectedImageBytes!);
                                    if (newUrl != null) finalImageUrl = newUrl;
                                  }

                                  String tipeHuruf =
                                      selectedTipeP3K.contains('A')
                                      ? 'A'
                                      : (selectedTipeP3K.contains('B')
                                            ? 'B'
                                            : 'C');

                                  Map<String, dynamic> updatedData = {
                                    'nama_barang': namaController.text,
                                    'lokasi': lokasiController.text,
                                    'koordinat': koordinatController.text,
                                    'image_url': finalImageUrl,
                                    'spesifikasi': {
                                      'No P3K': nomorP3kController.text,
                                      'Tipe': tipeHuruf,
                                      'Kapasitas Ruangan':
                                          selectedTipeP3K.contains('25')
                                          ? '25'
                                          : (selectedTipeP3K.contains('50')
                                                ? '50'
                                                : '100'),
                                    },
                                    'kadaluarsa_cairan': {
                                      'Aquades': expAquadesController.text,
                                      'Povidone Iodine':
                                          expPovidoneController.text,
                                      'Alkohol 70%': expAlkoholController.text,
                                    },
                                  };

                                  await FirestoreService().updateBarang(
                                    'Kotak P3K',
                                    widget.docId,
                                    updatedData,
                                  );
                                  setState(() {
                                    currentData.addAll(updatedData);
                                  });

                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Perubahan berhasil disimpan!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (mounted)
                                    setDialogState(() => isSaving = false);
                                }
                              },
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Simpan Perubahan',
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
            );
          },
        );
      },
    );
  }

  void _hapusP3k() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kotak P3K?'),
        content: const Text(
          'Data ini akan dihapus secara permanen. Apakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().hapusBarang('Kotak P3K', widget.docId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kotak P3K berhasil dihapus')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var spec = currentData['spesifikasi'] ?? {};
    var expCairan = currentData['kadaluarsa_cairan'] ?? {};
    String namaBarang = currentData['nama_barang'] ?? '-';
    String lokasi = currentData['lokasi'] ?? '-';
    String koordinat = currentData['koordinat'] ?? '-';
    String imageUrl = currentData['image_url'] ?? '';
    String tipe = spec['Tipe'] ?? 'A';

    int typeIndex = 0;
    if (tipe.contains('B')) typeIndex = 1;
    if (tipe.contains('C')) typeIndex = 2;

    final Map<String, List<int>> standarP3K = {
      'Kasa Steril': [20, 40, 40],
      'Perban (Lebar 5 cm)': [2, 4, 6],
      'Perban (Lebar 10 cm)': [2, 4, 6],
      'Plester Lebar 1,25 cm': [2, 4, 6],
      'Plester Cepat': [10, 15, 20],
      'Kapas 25 gr': [1, 2, 3],
      'Kain Segi Tiga (Mitela)': [2, 4, 6],
      'Gunting': [1, 1, 1],
      'Peniti': [12, 12, 12],
      'Sarung Tangan Sekali Pakai': [2, 3, 4],
      'Sarung Tangan (Pasangan)': [2, 4, 6],
      'Masker': [1, 1, 1],
      'Pinset': [1, 1, 1],
      'Lampu Senter': [1, 1, 1],
      'Gelas Cuci Mata': [1, 2, 3],
      'Kantong Plastik Bersih': [1, 1, 1],
      'Aquades': [1, 1, 1],
      'Povidone Iodine': [1, 1, 1],
      'Alkohol 70%': [1, 1, 1],
      'Buku Panduan P3K': [1, 1, 1],
      'Buku Catatan & Daftar Isi': [1, 1, 1],
    };

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: const Text(
          'Detail Kotak P3K',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5), // Bayangan ke atas
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Agar menyesuaikan isi
            children: [
              // 1. Tombol Buku Catatan (Selalu Tampil)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book, color: Colors.white),
                  label: const Text(
                    'Buku Catatan Penggunaan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CatatanPenggunaanScreen(
                          docIdBarang: widget.docId,
                          namaKotak: namaBarang,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. Tombol Aksi Admin (Inspeksi, Edit, Hapus)
              if (widget.isAdmin) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF149C94),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.fact_check, color: Colors.white),
                    label: const Text(
                      'Lakukan Inspeksi Rutin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      // <-- UBAH MENJADI ASYNC & AMBIL DATA TERBARU
                      var snapshot = await FirebaseFirestore.instance
                          .collection('Kotak P3K')
                          .doc(widget.docId)
                          .get();
                      var latestData = snapshot.data() ?? {};

                      Map<String, dynamic> currentDefisit =
                          Map<String, dynamic>.from(
                            latestData['defisit_p3k'] ?? {},
                          );
                      Map<String, dynamic> currentExpCairan =
                          Map<String, dynamic>.from(
                            latestData['kadaluarsa_cairan'] ?? {},
                          );

                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormPemeriksaanScreen(
                            docIdBarang: widget.docId,
                            namaBarang: namaBarang,
                            lokasi: lokasi,
                            checklistItems: const [
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
                            ],
                            initialDefisit: currentDefisit,
                            initialKadaluarsa: currentExpCairan,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showEditP3kDialog,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _hapusP3k,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.9),
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.zero,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          InteractiveViewer(
                            panEnabled: true,
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 40,
                            right: 20,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'p3k_image_${widget.docId}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
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
                    'Kotak P3K No. ${spec['No P3K'] ?? '-'}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nama: $namaBarang • Lokasi: $lokasi • Tipe: $tipe', // <-- UBAH BAGIAN INI
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // INFORMASI KADALUARSA CAIRAN P3K
            Text(
              'Masa Kadaluarsa Cairan Obat:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
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
              ),
              child: Column(
                children: [
                  _rowInfo('Aquades (25ml)', expCairan['Aquades'] ?? '-'),
                  _rowInfo(
                    'Povidone Iodine',
                    expCairan['Povidone Iodine'] ?? '-',
                  ),
                  _rowInfo('Alkohol 70%', expCairan['Alkohol 70%'] ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Kelengkapan Isi P3K (Real-time Permenaker):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Kotak P3K')
                  .doc(widget.docId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                var docData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                Map<String, dynamic> defisit = Map<String, dynamic>.from(
                  docData['defisit_p3k'] ?? {},
                );

                return Container(
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
                    children: standarP3K.entries.map((entry) {
                      int maxStock = entry.value[typeIndex];
                      int currentDefisit = defisit[entry.key] ?? 0;
                      int currentStock = maxStock - currentDefisit;
                      if (currentStock < 0) currentStock = 0;
                      bool isDefisit = currentStock < maxStock;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDefisit
                                      ? Colors.red
                                      : Colors.black87,
                                  fontWeight: isDefisit
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Text(
                              '$currentStock / $maxStock',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDefisit ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            if (koordinat.isNotEmpty && koordinat != '-') ...[
              const SizedBox(height: 15),
              Container(
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
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Titik Koordinat GPS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            koordinat,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.grey,
                        size: 20,
                      ),
                      tooltip: 'Salin Koordinat',
                      onPressed: () => _copyCoordinates(context, koordinat),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.map,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      tooltip: 'Buka di Google Maps',
                      onPressed: () => _openGoogleMaps(koordinat),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            val,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}
