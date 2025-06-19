import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sayurku/models/order_model.dart';
import 'package:sayurku/services/order_service.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  final Order order;

  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _proofImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _confirmPayment() async {
    final orderService = context.read<OrderService>();
    final isUploadRequired =
        widget.order.metodePembayaran == 'Transfer' ||
        widget.order.metodePembayaran == 'DANA';

    if (isUploadRequired && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan unggah bukti pembayaran Anda.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      // 1. Unggah gambar jika ada
      if (_proofImage != null) {
        imageUrl = await orderService.uploadPaymentProof(_proofImage!);
      }

      // 2. Perbarui status pesanan (dan URL gambar jika ada)
      await orderService.updateOrderPayment(
        orderId: widget.order.id,
        newStatus: 'processing', // Status diubah menjadi 'processing'
        paymentImageUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfirmasi berhasil! Pesanan Anda sedang diproses.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konfirmasi gagal: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        // Mencegah pengguna kembali ke halaman checkout
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(widget.order.harga),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Menampilkan detail pembayaran sesuai metode yang dipilih
            _buildPaymentDetails(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : widget.order.metodePembayaran == 'COD'
                      ? const Text('Selesai')
                      : const Text('Konfirmasi Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan detail pembayaran & form unggah
  Widget _buildPaymentDetails() {
    switch (widget.order.metodePembayaran) {
      case 'Transfer':
        return _buildUploadSection(
          'Transfer Bank BCA',
          'Silakan transfer ke rekening berikut:\n\nNomor Rekening: 1234567890\nAtas Nama: Sell dSayur',
        );
      case 'DANA':
        return _buildUploadSection(
          'DANA',
          'Silakan transfer ke nomor DANA berikut:\n\nNomor: 081234567890\nAtas Nama: Sell dSayur',
        );
      case 'COD':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 50,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                Text(
                  'Bayar di Tempat (COD)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mohon siapkan uang pas saat kurir tiba. Terima kasih!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Widget reusable untuk bagian unggah bukti
  Widget _buildUploadSection(String title, String instruction) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(instruction, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              _proofImage != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_proofImage!, fit: BoxFit.contain),
                  )
                  : const Center(
                    child: Text(
                      'Pratinjau Bukti Pembayaran',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Unggah Bukti Pembayaran'),
        ),
      ],
    );
  }
}
