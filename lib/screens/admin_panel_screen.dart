import 'package:flutter/material.dart';
import 'manajemen_kategori_screen.dart';
import 'manajemen_akun_screen.dart';
import 'log_aktivitas_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: const Text(
          'Pusat Kendali Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menu Administrator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F3460),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola sistem, hak akses pengguna, dan pantau aktivitas aplikasi.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 25),

            // KOTAK MENU 1: KELOLA KATEGORI (Fitur Lama yang dipindah)
            _buildAdminMenuCard(
              context: context,
              icon: Icons.category,
              color: Colors.blue,
              title: 'Kelola Kategori Barang',
              subtitle: 'Tambah, edit, atau hapus kategori dinamis.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManajemenKategoriScreen(),
                  ),
                );
              },
            ),

            // KOTAK MENU 2: MANAJEMEN AKUN (Fitur Baru)
            _buildAdminMenuCard(
              context: context,
              icon: Icons.manage_accounts,
              color: Colors.orange,
              title: 'Manajemen Akun & Izin',
              subtitle: 'Buat akun baru dan atur hak akses pengguna.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManajemenAkunScreen(),
                  ),
                );
              },
            ),

            // KOTAK MENU 3: LOG AKTIVITAS (Fitur Baru)
            _buildAdminMenuCard(
              context: context,
              icon: Icons.history_edu,
              color: Colors.green,
              title: 'Log Aktivitas Sistem',
              subtitle: 'Pantau riwayat perubahan dan aktivitas user.',
              onTap: () {
                // <-- Hapus SnackBar dan buka Navigator ini
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogAktivitasScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget bantuan untuk membuat kotak menu yang seragam
  Widget _buildAdminMenuCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
