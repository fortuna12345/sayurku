import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:sayurku/models/order_model.dart';
import 'package:sayurku/services/auth_service.dart';
import 'package:sayurku/services/order_service.dart';
import 'package:sayurku/widgets/order_card.dart';
import 'package:provider/provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
late Order _currentOrder;
  File? _proofImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  // Fungsi untuk memilih gambar dari galeri
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

  // Fungsi untuk mengunggah bukti dan memperbarui pesanan
  Future<void> _uploadProof() async {
    if (_proofImage == null) return;

    setState(() => _isLoading = true);
    final orderService = context.read<OrderService>();

    try {
      // 1. Unggah gambar
      final imageUrl = await orderService.uploadPaymentProof(_proofImage!);

      // 2. Perbarui status pesanan menjadi 'processing' beserta URL gambar
      await orderService.updateOrderPayment(
        orderId: _currentOrder.id,
        newStatus: 'processing',
        paymentImageUrl: imageUrl,
      );

      // 3. Refresh data pesanan di layar ini
      final updatedOrder = await orderService.getOrderById(_currentOrder.id);
      setState(() {
        _currentOrder = updatedOrder;
        _proofImage = null; // Kosongkan pilihan gambar setelah berhasil
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti pembayaran berhasil diunggah!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah bukti: ${e.toString()}')),
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
    final authService = context.watch<AuthService>();
    final isOwner = authService.currentUser?.id == _currentOrder.idUser;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final statusHelper = OrderCard(order: _currentOrder);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan #${widget.order.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Ringkasan ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Tanggal Pesan', DateFormat('dd MMM yyyy, HH:mm').format(widget.order.createdAt)),
                    _buildDetailRow('Status', statusHelper.getStatusText(widget.order.status), valueColor: statusHelper.getStatusColor(widget.order.status)),
                    _buildDetailRow('Total Pembayaran', currencyFormatter.format(widget.order.harga)),
                    _buildDetailRow('Metode Pembayaran', widget.order.metodePembayaran),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Bagian Detail Item ---
            const Text('Barang Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.order.orderDetails?.length ?? 0,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = widget.order.orderDetails![index];
                  return ListTile(
                    title: Text(item.barang?.namaBarang ?? 'Nama Barang Tidak Tersedia'),
                    subtitle: Text('${item.jumlah} x ${currencyFormatter.format(item.subtotal / item.jumlah)}'),
                    trailing: Text(currencyFormatter.format(item.subtotal)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // --- Bagian Pengiriman ---
            const Text('Info Pengiriman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Nama Penerima', widget.order.user?.nama ?? '-'),
                    _buildDetailRow('No. Telepon', widget.order.user?.no_telepon ?? '-'),
                    if(widget.order.alamatCatatan != null && widget.order.alamatCatatan!.isNotEmpty)
                      _buildDetailRow('Catatan Alamat', widget.order.alamatCatatan!),
                    if(widget.order.catatanPesanan != null && widget.order.catatanPesanan!.isNotEmpty)
                      _buildDetailRow('Catatan Pesanan', widget.order.catatanPesanan!),
                    
                    if (widget.order.latitude != null && widget.order.longitude != null) ...[
                      const SizedBox(height: 16),
                      const Text('Lokasi di Peta:', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(widget.order.latitude!, widget.order.longitude!),
                            initialZoom: 16.0,
                          ),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(widget.order.latitude!, widget.order.longitude!),
                                  width: 80,
                                  height: 80,
                                  child: const Icon(Icons.location_on, size: 50, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            // --- Bagian Pembayaran & Upload ---
            const SizedBox(height: 16),
            const Text('Info Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow('Metode Pembayaran', _currentOrder.metodePembayaran),
                    const SizedBox(height: 16),
                    // Tampilkan bukti pembayaran jika ada
                    if (_currentOrder.fotoPembayaran != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bukti Pembayaran Terunggah:', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Center(child: Image.network(_currentOrder.fotoPembayaran!, height: 250)),
                          const Divider(height: 24),
                        ],
                      ),
                    
                    // Tampilkan form upload HANYA jika status pending & user adalah pemilik
                    if (_currentOrder.status == 'pending' && isOwner)
                      _buildUploadSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk bagian upload
  Widget _buildUploadSection() {
    return Column(
      children: [
        Text(
          _currentOrder.fotoPembayaran == null ? 'Unggah Bukti Pembayaran' : 'Edit Bukti Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 12),
        // Preview gambar yang dipilih
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _proofImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_proofImage!, fit: BoxFit.contain),
                )
              : const Center(
                  child: Text('Pilih gambar...', style: TextStyle(color: Colors.grey)),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pilih Gambar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: (_proofImage == null || _isLoading) ? null : _uploadProof,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
              : const Text('Konfirmasi & Upload'),
        ),
      ],
    );
  }

  // Helper yang sudah ada, diganti untuk menggunakan _currentOrder
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}