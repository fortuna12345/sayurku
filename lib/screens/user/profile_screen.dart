import 'package:flutter/material.dart';
import 'package:sayurku/models/user_model.dart';
import 'package:sayurku/services/auth_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // DIALOG UNTUK EDIT PROFIL
  void _showEditProfileDialog(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    final nameController = TextEditingController(text: currentUser.nama);
    final phoneController = TextEditingController(text: currentUser.no_telepon);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profil'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Nama tidak boleh kosong'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  keyboardType: TextInputType.phone,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Nomor telepon tidak boleh kosong'
                              : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await authService.updateUserProfile({
                      'nama': nameController.text,
                      'no_telepon': phoneController.text,
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil berhasil diperbarui!'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui profil: $e')),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // DIALOG UNTUK HAPUS AKUN
  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Akun?'),
            content: const Text(
              'Tindakan ini tidak dapat diurungkan. Semua data Anda, termasuk riwayat pesanan, akan dihapus secara permanen. Apakah Anda yakin?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Hapus',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AuthService>().deleteCurrentUserAccount();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun Anda telah berhasil dihapus.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus akun: $e')));
      }
    }
  }

  // DIALOG UNTUK LOGOUT
  Future<void> _logout(BuildContext context) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Keluar',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthService>().logout();
      // Navigasi dengan aman setelah logout
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan context.watch agar UI otomatis update jika ada perubahan user
    final authService = context.watch<AuthService>();
    final UserModel? user = authService.currentUser;
    final textTheme = Theme.of(context).textTheme;

    if (user == null) {
      // Tampilan jika user tiba-tiba null (misal session berakhir)
      return const Center(child: Text('Tidak ada sesi pengguna.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(user.nama, style: textTheme.headlineSmall),
          Text(
            user.email ?? 'Tidak ada email',
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profil'),
            onTap: () => _showEditProfileDialog(context), // Panggil dialog edit
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Hapus Akun',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap:
                () => _showDeleteAccountDialog(context), // Panggil dialog hapus
          ),
          const Divider(),
          const SizedBox(height: 50),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
