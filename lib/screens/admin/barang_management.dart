import 'package:flutter/material.dart';
import 'package:sayurku/models/barang_model.dart';
import 'package:sayurku/screens/admin/barang_form_dialog.dart';
import 'package:sayurku/services/barang_service.dart';
import 'package:intl/intl.dart';

class BarangManagementScreen extends StatefulWidget {
  const BarangManagementScreen({super.key});

  @override
  State<BarangManagementScreen> createState() => _BarangManagementScreenState();
}

class _BarangManagementScreenState extends State<BarangManagementScreen> {
  final BarangService _barangService = BarangService();
  late Future<List<Barang>> _barangsFuture;
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadBarangs();
  }

  void _loadBarangs() {
    setState(() {
      _barangsFuture = _barangService.getAllBarangs();
    });
  }

  Future<void> _showBarangDialog({Barang? barang}) async {
    final bool? success = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BarangFormDialog(barang: barang, barangService: _barangService),
    );

    if (success == true) {
      _loadBarangs();
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteBarang(Barang barang) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Anda yakin ingin menghapus barang "${barang.namaBarang}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _barangService.deleteBarang(barang.id, imageUrl: barang.gambar);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barang "${barang.namaBarang}" berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBarangs();
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showBarangDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<Barang>>(
        future: _barangsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada barang.'));
          }

          final barangs = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadBarangs(),
            child: ListView.builder(
              itemCount: barangs.length,
              itemBuilder: (context, index) {
                final barang = barangs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child:
                          barang.gambar != null && barang.gambar!.isNotEmpty
                              ? Image.network(
                                barang.gambar!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                loadingBuilder:
                                    (_, child, progress) =>
                                        progress == null
                                            ? child
                                            : const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                              )
                              : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.restaurant_menu,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                    ),
                    title: Text(
                      barang.namaBarang,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${currencyFormatter.format(barang.harga)}\nKategori: ${barang.kategori?.namaKategori ?? 'N/A'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showBarangDialog(barang: barang),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBarang(barang),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
