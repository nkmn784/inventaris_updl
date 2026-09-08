import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart'; // Pastikan nama file ini sesuai dengan file login Anda

void main() async {
  // Wajib ditambahkan jika main() menggunakan async
  WidgetsFlutterBinding.ensureInitialized();

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
      debugShowCheckedModeBanner:
          false, // Menghilangkan banner debug di pojok kanan atas
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Mengatur Halaman Login sebagai halaman pertama yang terbuka
      home: const LoginPage(),
    );
  }
}
