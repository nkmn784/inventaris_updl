import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ManajemenAkunScreen extends StatefulWidget {
  const ManajemenAkunScreen({super.key});

  @override
  State<ManajemenAkunScreen> createState() => _ManajemenAkunScreenState();
}

class _ManajemenAkunScreenState extends State<ManajemenAkunScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddAccountDialog() {
    TextEditingController namaController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    String selectedRole = 'Petugas Lapangan';
    bool isSaving = false;

    // Default Permissions
    Map<String, bool> permissions = {
      'can_add_item': true,
      'can_edit_item': true,
      'can_delete_item': false, // Default petugas tidak bisa hapus
      'can_inspect': true,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Tambah Akun Petugas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password Sementara',
                          prefixIcon: Icon(Icons.lock),
                          helperText: 'Minimal 6 karakter',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Peran (Role)',
                          prefixIcon: Icon(Icons.admin_panel_settings),
                        ),
                        items: ['Admin', 'Petugas Lapangan']
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedRole = val!;
                            // Jika Admin, otomatis centang semua
                            if (val == 'Admin') {
                              permissions.updateAll((key, value) => true);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Hak Akses Khusus:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          'Tambah Barang Baru',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: permissions['can_add_item'],
                        dense: true,
                        onChanged: (val) => setDialogState(
                          () => permissions['can_add_item'] = val!,
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          'Edit Data Barang',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: permissions['can_edit_item'],
                        dense: true,
                        onChanged: (val) => setDialogState(
                          () => permissions['can_edit_item'] = val!,
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          'Hapus Data Barang',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: permissions['can_delete_item'],
                        dense: true,
                        onChanged: (val) => setDialogState(
                          () => permissions['can_delete_item'] = val!,
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text(
                          'Lakukan Inspeksi (Checklist)',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: permissions['can_inspect'],
                        dense: true,
                        onChanged: (val) => setDialogState(
                          () => permissions['can_inspect'] = val!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (namaController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Semua kolom wajib diisi!'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            // 1. Buat "Aplikasi Firebase Sementara" agar sesi admin tidak tertimpa
                            FirebaseApp tempApp = await Firebase.initializeApp(
                              name: 'TempAuthApp',
                              options: Firebase.app().options,
                            );

                            // 2. Buat akun menggunakan aplikasi sementara tersebut
                            UserCredential userCred =
                                await FirebaseAuth.instanceFor(
                                  app: tempApp,
                                ).createUserWithEmailAndPassword(
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                );

                            // 3. Simpan profil ke Firestore menggunakan sesi Admin (koneksi asli)
                            if (userCred.user != null) {
                              await _firestore
                                  .collection('Users')
                                  .doc(userCred.user!.uid)
                                  .set({
                                    'uid': userCred.user!.uid,
                                    'nama': namaController.text.trim(),
                                    'email': emailController.text.trim(),
                                    'role': selectedRole,
                                    'permissions': permissions,
                                    'created_at': FieldValue.serverTimestamp(),
                                  });
                            }

                            // 4. Hapus aplikasi sementara agar memori bersih
                            await tempApp.delete();

                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Akun petugas berhasil ditambahkan!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
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

  void _hapusAkun(String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data Akun?'),
        content: const Text(
          'Perhatian: Ini hanya menghapus data profil & izin di database. Akses login di Firebase Auth harus dihapus manual di konsol Firebase demi keamanan.',
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
              await _firestore.collection('Users').doc(uid).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil akun dihapus dari database'),
                  ),
                );
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
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        title: const Text(
          'Manajemen Akun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Akun Baru'),
        onPressed: _showAddAccountDialog,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Users').orderBy('role').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data akun yang tersimpan.\nSilakan buat akun baru.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              var data = users[index].data() as Map<String, dynamic>;
              String uid = users[index].id;
              String role = data['role'] ?? 'Tidak Diketahui';
              bool isAdmin = role.toLowerCase() == 'admin';

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
                  border: Border(
                    left: BorderSide(
                      color: isAdmin ? Colors.redAccent : Colors.blue.shade600,
                      width: 5,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isAdmin
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.engineering,
                      color: isAdmin ? Colors.red : Colors.blue,
                    ),
                  ),
                  title: Text(
                    data['nama'] ?? 'Tanpa Nama',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data['email'] ?? '-'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAdmin
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _hapusAkun(uid),
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
