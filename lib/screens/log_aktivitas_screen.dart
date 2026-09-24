import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LogAktivitasScreen extends StatelessWidget {
  const LogAktivitasScreen({super.key});

  IconData _getIconForAction(String action) {
    String act = action.toUpperCase();
    if (act == 'TAMBAH') return Icons.add_circle_outline;
    if (act == 'EDIT' || act == 'UPDATE') return Icons.edit_outlined;
    if (act == 'HAPUS' || act == 'DELETE') return Icons.delete_outline;
    if (act == 'INSPEKSI') return Icons.fact_check_outlined;
    return Icons.info_outline;
  }

  Color _getColorForAction(String action) {
    String act = action.toUpperCase();
    if (act == 'TAMBAH') return Colors.green;
    if (act == 'EDIT' || act == 'UPDATE') return Colors.blue;
    if (act == 'HAPUS' || act == 'DELETE') return Colors.red;
    if (act == 'INSPEKSI') return Colors.teal;
    return Colors.grey;
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
          'Log Aktivitas Sistem',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil data dari collection 'Activity_Logs' diurutkan dari yang terbaru
        stream: FirebaseFirestore.instance
            .collection('Activity_Logs')
            .orderBy('waktu', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada log aktivitas yang terekam.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          var logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var data = logs[index].data() as Map<String, dynamic>;

              String namaUser = data['nama_user'] ?? 'Sistem / Unknown';
              String tipeAksi = data['tipe_aksi'] ?? 'INFO';
              String kategori = data['kategori'] ?? '-';
              String detail = data['detail'] ?? '-';

              // Format Waktu
              String waktuStr = '';
              if (data['waktu'] != null && data['waktu'] is Timestamp) {
                DateTime dt = (data['waktu'] as Timestamp).toDate();
                waktuStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
              } else {
                waktuStr = 'Waktu tidak diketahui';
              }

              Color iconColor = _getColorForAction(tipeAksi);
              IconData iconData = _getIconForAction(tipeAksi);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border(left: BorderSide(color: iconColor, width: 4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  namaUser,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  waktuStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$tipeAksi - $kategori',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              detail,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
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
    );
  }
}
