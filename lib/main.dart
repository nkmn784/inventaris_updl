import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/public_catatan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Tangkap URL mentah dari browser secara langsung
  final Uri uri = Uri.base;

  // Cek apakah URL yang dibuka oleh pengguna mengandung kata 'form-p3k'
  bool isPublicForm =
      uri.path.contains('form-p3k') || uri.toString().contains('form-p3k');

  // Ekstrak parameter ID jika ada (contoh: ?id=KOTAK_MASJID_01)
  String? kotakId = uri.queryParameters['id'];
  if (kotakId == null && uri.hasFragment) {
    try {
      final fragmentUri = Uri.parse(uri.fragment);
      kotakId = fragmentUri.queryParameters['id'];
    } catch (_) {}
  }

  runApp(MyApp(isPublicForm: isPublicForm, initialKotakId: kotakId));
}

class MyApp extends StatelessWidget {
  final bool isPublicForm;
  final String? initialKotakId;

  const MyApp({super.key, required this.isPublicForm, this.initialKotakId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventaris UPDL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // 2. Tentukan halaman utama secara dinamis berdasarkan URL browser
      home: isPublicForm
          ? PublicCatatanScreen(initialKotakId: initialKotakId)
          : const LoginPage(),
    );
  }
}
