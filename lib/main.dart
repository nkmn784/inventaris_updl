import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // <-- Tambahan untuk menghilangkan '#' pada URL web
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/public_catatan_screen.dart'; // <-- Tambahan import form publik

void main() async {
  // Wajib ditambahkan jika main() menggunakan async
  WidgetsFlutterBinding.ensureInitialized();

  // Menghilangkan tanda '#' pada URL Flutter Web (harus dipanggil sebelum runApp)
  usePathUrlStrategy();

  // Inisialisasi Firebase sesuai platform (Android/iOS/Web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventaris UPDL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      // home: const LoginPage(), <-- Dihapus karena kita menggunakan onGenerateRoute

      // Menentukan rute awal saat aplikasi/web pertama kali dibuka
      initialRoute: '/',

      // Mengatur sistem routing agar bisa menangkap link spesifik dari QR Code
      onGenerateRoute: (settings) {
        // 1. Rute untuk form P3K publik (Bisa diakses via QR Code / Link langsung)
        if (settings.name != null && settings.name!.startsWith('/form-p3k')) {
          // Fitur ekstrak ID: Mengambil ID dari URL (misal: /form-p3k?id=123)
          final Uri uri = Uri.parse(settings.name!);
          final String? kotakId = uri.queryParameters['id'];

          return MaterialPageRoute(
            builder: (context) => PublicCatatanScreen(initialKotakId: kotakId),
          );
        }

        // 2. Rute Default (Halaman Login / Halaman Utama Aplikasi)
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (context) => const LoginPage());
        }

        // 3. Fallback jika URL yang diketik salah / tidak ditemukan (Kembali ke Login)
        return MaterialPageRoute(builder: (context) => const LoginPage());
      },
    );
  }
}
