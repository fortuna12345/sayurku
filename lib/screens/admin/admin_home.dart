import 'package:flutter/material.dart';
import 'package:sayurku/screens/admin/barang_management.dart';
import 'package:sayurku/screens/admin/order_management.dart';
import 'package:sayurku/screens/admin/reports_screen.dart';
import 'package:sayurku/services/auth_service.dart';
import 'package:provider/provider.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Menampilkan dialog konfirmasi sebelum logout
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
                          child: const Text(
                            'Keluar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );

              // Jika pengguna menekan "Keluar"
              if (confirmed == true && context.mounted) {
                await authService.logout();
                // Menggunakan pushReplacementNamed agar pengguna tidak bisa kembali
                // ke halaman admin setelah logout.
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDashboardItem(
              context,
              icon: Icons.restaurant_menu,
              label: 'Barang Management',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BarangManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardItem(
              context,
              icon: Icons.shopping_cart,
              label: 'Order Management',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardItem(
              context,
              icon: Icons.bar_chart,
              label: 'Reports',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
