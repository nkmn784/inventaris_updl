import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import 'form_pemeriksaan_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AparScreen extends StatefulWidget {
  final bool isAdmin;
  const AparScreen({super.key, this.isAdmin = true});

  @override
  State<AparScreen> createState() => _AparScreenState();
}

late Stream<QuerySnapshot> _aparStream;

class _AparScreenState extends State<AparScreen> {
  String _searchQuery = '';
  late Stream<QuerySnapshot> _aparStream;

  // ✔️ TAMBAHKAN INI: Inisialisasi stream saat halaman pertama kali dibuka
  @override
  void initState() {
    super.initState();
    _aparStream = FirestoreService().getBarangByKategori('APAR');
  }

  Color _getStatusColor(String status) {
    if (status == 'Tersedia') return Colors.green;
    if (status == 'Rusak') return Colors.red;
    return Colors.orange;
  }

  // --- DIALOG TAMBAH APAR ---
  void _showAddAparDialog(BuildContext context) {
    TextEditingController merkController = TextEditingController();
    TextEditingController lokasiController = TextEditingController();
    TextEditingController koordinatController = TextEditingController();
    TextEditingController aparBerat = TextEditingController();
    TextEditingController aparNomor = TextEditingController();
    TextEditingController expiredController = TextEditingController();

    String selectedStatus = 'Tersedia';
    List<String> listStatus = [
      'Tersedia',
      'Tidak ada di tempat',
      'Rusak',
      'Dalam Perbaikan',
    ];

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
                        toolbarTitle: 'Crop Foto APAR',
                        toolbarColor: const Color(0xFF0F3460),
                        toolbarWidgetColor: Colors.white,
                        initAspectRatio: CropAspectRatioPreset.ratio4x3,
                        lockAspectRatio: false,
                        aspectRatioPresets: [
                          CropAspectRatioPreset.square,
                          CropAspectRatioPreset.ratio4x3,
                          CropAspectRatioPreset.ratio16x9,
                        ],
                      ),
                      IOSUiSettings(
                        title: 'Crop Foto APAR',
                        aspectRatioPresets: [
                          CropAspectRatioPreset.square,
                          CropAspectRatioPreset.ratio4x3,
                          CropAspectRatioPreset.ratio16x9,
                        ],
                      ),
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
                } catch (cropError) {
                  debugPrint("Crop Error: $cropError");
                  setDialogState(() {
                    selectedImageBytes = bytes;
                    selectedImageName = img.name;
                  });
                }
              } catch (e) {
                debugPrint("Picker Error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal mengambil foto')),
                );
              }
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
                          'Tambah APAR Baru',
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
                      'Foto APAR',
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
                      controller: merkController,
                      decoration: const InputDecoration(
                        labelText: 'Merk APAR (Contoh: Powder / Gunnebo)',
                      ),
                    ),
                    TextField(
                      controller: lokasiController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Ruangan',
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
                    TextField(
                      controller: aparNomor,
                      decoration: const InputDecoration(
                        labelText: 'Nomor APAR (Contoh: 43)',
                      ),
                    ),
                    TextField(
                      controller: aparBerat,
                      decoration: const InputDecoration(
                        labelText: 'Berat Media (Contoh: 3kg)',
                      ),
                    ),
                    TextFormField(
                      controller: expiredController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Kadaluarsa',
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            expiredController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(pickedDate);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Status Barang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: listStatus
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedStatus = val!),
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
                                if (merkController.text.isEmpty ||
                                    selectedImageBytes == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Foto dan Merk wajib diisi!',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setDialogState(() => isSaving = true);
                                try {
                                  String? url = await CloudinaryService()
                                      .uploadImageBytes(selectedImageBytes!);
                                  await FirestoreService().tambahBarang(
                                    'APAR',
                                    {
                                      'nama_barang': merkController.text,
                                      'lokasi': lokasiController.text,
                                      'kategori': 'APAR',
                                      'koordinat': koordinatController.text,
                                      'stok': quantity,
                                      'tanggal_kadaluarsa':
                                          expiredController.text,
                                      'keterangan': selectedStatus,
                                      'image_url': url ?? '',
                                      'spesifikasi': {
                                        'No APAR': aparNomor.text,
                                        'Berat': aparBerat.text,
                                      },
                                      'tanggal_inspeksi': null,
                                    },
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'APAR berhasil ditambahkan!',
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
                                'Simpan APAR',
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
          'Manajemen APAR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Header Gradient & Search Bar Dinamis ala Dashboard
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
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nomor APAR atau lokasi...',
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
              stream: _aparStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(
                    child: Text(
                      'Belum ada data APAR',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );

                List<QueryDocumentSnapshot> items = snapshot.data!.docs.where((
                  doc,
                ) {
                  var data = doc.data() as Map<String, dynamic>;
                  var spec = data['spesifikasi'] ?? {};
                  String str =
                      '${data['nama_barang']} ${data['lokasi']} ${spec['No APAR'] ?? ''}'
                          .toLowerCase();
                  return str.contains(_searchQuery);
                }).toList();

                items.sort((a, b) {
                  var specA =
                      (a.data() as Map<String, dynamic>)['spesifikasi'] ?? {};
                  var specB =
                      (b.data() as Map<String, dynamic>)['spesifikasi'] ?? {};
                  int noA =
                      int.tryParse(
                        (specA['No APAR'] ?? '0').replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        ),
                      ) ??
                      0;
                  int noB =
                      int.tryParse(
                        (specB['No APAR'] ?? '0').replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        ),
                      ) ??
                      0;
                  return noA.compareTo(noB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var data = items[index].data() as Map<String, dynamic>;
                    String docId = items[index].id;
                    var spec = data['spesifikasi'] ?? {};
                    String noApar = spec['No APAR'] ?? '-';
                    String status = data['keterangan'] ?? 'Tersedia';
                    Color statusColor = _getStatusColor(status);

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
                                builder: (context) => DetailAparScreen(
                                  docId: docId,
                                  dataApar: data,
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
                                            Icons.fire_extinguisher,
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
                                        'APAR No. $noApar (${data['nama_barang'] ?? ''})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lokasi: ${data['lokasi'] ?? '-'}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Tambahan agar sejajar di tengah secara vertikal (seperti P3K)
                                  children: [
                                    Container(
                                      alignment:
                                          Alignment.center, // Pusatkan Teks
                                      width:
                                          95, // Tambahkan lebar fix agar sejajar atas & bawah
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status, // Hapus .toUpperCase() agar gaya teksnya mirip badge P3K
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize:
                                              9, // Samakan ukuran font dengan badge bawah
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      alignment:
                                          Alignment.center, // Pusatkan Teks
                                      width:
                                          95, // Tambahkan lebar fix agar sejajar atas & bawah
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
              onPressed: () => _showAddAparDialog(context),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ==========================================================
// --- HALAMAN DETAIL APAR ---
// ==========================================================
class DetailAparScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> dataApar;
  final bool isAdmin;

  const DetailAparScreen({
    super.key,
    required this.docId,
    required this.dataApar,
    required this.isAdmin,
  });

  @override
  State<DetailAparScreen> createState() => _DetailAparScreenState();
}

class _DetailAparScreenState extends State<DetailAparScreen> {
  late Map<String, dynamic> currentData;

  late Stream<QuerySnapshot> _aparStream;

  // 2. MASUKKAN PEMANGGILAN FIREBASE KE DALAM INIT STATE
  @override
  void initState() {
    super.initState();
    _aparStream = FirestoreService().getBarangByKategori('APAR');
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
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat berhasil disalin!'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _showZoomableImage(String imageUrl) {
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
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAparDialog() {
    var spec = currentData['spesifikasi'] ?? {};
    TextEditingController merkController = TextEditingController(
      text: currentData['nama_barang'],
    );
    TextEditingController lokasiController = TextEditingController(
      text: currentData['lokasi'],
    );
    TextEditingController koordinatController = TextEditingController(
      text: currentData['koordinat'],
    );
    TextEditingController aparBerat = TextEditingController(
      text: spec['Berat'],
    );
    TextEditingController aparNomor = TextEditingController(
      text: spec['No APAR'],
    );
    TextEditingController expiredController = TextEditingController(
      text: currentData['tanggal_kadaluarsa'],
    );

    List<String> listStatus = [
      'Tersedia',
      'Tidak ada di tempat',
      'Rusak',
      'Dalam Perbaikan',
    ];
    String selectedStatus = listStatus.contains(currentData['keterangan'])
        ? currentData['keterangan']
        : 'Tersedia';

    Uint8List? selectedImageBytes;
    String? selectedImageName;
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
                    selectedImageName = img.name;
                  });
                  return;
                }

                try {
                  CroppedFile? croppedFile = await ImageCropper().cropImage(
                    sourcePath: img.path,
                    uiSettings: [
                      AndroidUiSettings(
                        toolbarTitle: 'Crop Foto APAR',
                        toolbarColor: const Color(0xFF0F3460),
                        toolbarWidgetColor: Colors.white,
                        initAspectRatio: CropAspectRatioPreset.ratio4x3,
                        lockAspectRatio: false,
                        aspectRatioPresets: [
                          CropAspectRatioPreset.square,
                          CropAspectRatioPreset.ratio4x3,
                          CropAspectRatioPreset.ratio16x9,
                        ],
                      ),
                      IOSUiSettings(
                        title: 'Crop Foto APAR',
                        aspectRatioPresets: [
                          CropAspectRatioPreset.square,
                          CropAspectRatioPreset.ratio4x3,
                          CropAspectRatioPreset.ratio16x9,
                        ],
                      ),
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
                } catch (cropError) {
                  debugPrint("Crop Error: $cropError");
                  setDialogState(() {
                    selectedImageBytes = bytes;
                    selectedImageName = img.name;
                  });
                }
              } catch (e) {
                debugPrint("Picker Error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal membuka kamera/galeri')),
                );
              }
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
                if (permission == LocationPermission.denied)
                  permission = await Geolocator.requestPermission();
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
                          'Edit Data APAR',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: merkController,
                      decoration: const InputDecoration(labelText: 'Merk APAR'),
                    ),
                    TextField(
                      controller: lokasiController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi Ruangan',
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
                    TextField(
                      controller: aparNomor,
                      decoration: const InputDecoration(
                        labelText: 'Nomor APAR',
                      ),
                    ),
                    TextField(
                      controller: aparBerat,
                      decoration: const InputDecoration(
                        labelText: 'Berat Media (Kg)',
                      ),
                    ),
                    TextFormField(
                      controller: expiredController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Kadaluarsa',
                        suffixIcon: Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      onTap: () async {
                        DateTime initial = DateTime.now();
                        try {
                          List<String> parts = expiredController.text.split(
                            '/',
                          );
                          if (parts.length == 3)
                            initial = DateTime(
                              int.parse(parts[2]),
                              int.parse(parts[1]),
                              int.parse(parts[0]),
                            );
                        } catch (e) {}

                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            expiredController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(pickedDate);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Status Barang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: listStatus
                          .map(
                            (val) =>
                                DropdownMenuItem(value: val, child: Text(val)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedStatus = val!),
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

                                  Map<String, dynamic> updatedData = {
                                    'nama_barang': merkController.text,
                                    'lokasi': lokasiController.text,
                                    'koordinat': koordinatController.text,
                                    'tanggal_kadaluarsa':
                                        expiredController.text,
                                    'keterangan': selectedStatus,
                                    'image_url': finalImageUrl,
                                    'spesifikasi': {
                                      'No APAR': aparNomor.text,
                                      'Berat': aparBerat.text,
                                    },
                                  };

                                  await FirestoreService().updateBarang(
                                    'APAR',
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

  void _hapusApar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus APAR?'),
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
                await FirestoreService().hapusBarang('APAR', widget.docId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('APAR berhasil dihapus')),
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
    var spec = currentData['spesifikasi'] is Map
        ? currentData['spesifikasi'] as Map<String, dynamic>
        : {};
    String noApar = spec['No APAR'] ?? '-';
    String berat = spec['Berat'] ?? '-';
    String merk = currentData['nama_barang'] ?? '-';
    String lokasi = currentData['lokasi'] ?? '-';
    String koordinat = currentData['koordinat'] ?? '-';
    String expired = currentData['tanggal_kadaluarsa'] ?? '-';
    String status = currentData['keterangan'] ?? 'Tersedia';
    String imageUrl = currentData['image_url'] ?? '';

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: const Text(
          'Detail APAR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: widget.isAdmin
          ? Container(
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
                  mainAxisSize:
                      MainAxisSize.min, // Agar tingginya menyesuaikan isi
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormPemeriksaanScreen(
                                docIdBarang: widget.docId,
                                namaBarang: 'APAR $noApar',
                                lokasi: lokasi,
                                noApar: noApar,
                                checklistItems: const [
                                  'Label Pengisian Terbaca?',
                                  'Tekanan Normal (Indikator Hijau)?',
                                  'Safety Pin Terpasang & Segel Utuh?',
                                  'Handle / Tuas Normal?',
                                  'Selang & Nozzle Tidak Retak/Mampet?',
                                ],
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
                            onPressed: _showEditAparDialog,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Data'),
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
                            onPressed: _hapusApar,
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
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _showZoomableImage(imageUrl),
                child: Hero(
                  tag: 'apar_image_${widget.docId}',
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
                    'APAR No. $noApar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lokasi: $lokasi',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  _rowInfo('Merk / Jenis', merk),
                  _rowInfo('Berat Media', berat),
                  _rowInfo('Tanggal Kadaluarsa', expired),
                  _rowInfo('Status', status),
                ],
              ),
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
            const SizedBox(height: 30),
            if (widget.isAdmin) ...[SizedBox(width: double.infinity)],
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
