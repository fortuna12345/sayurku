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
import 'package:url_launcher/url_launcher.dart';

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

  // Lokasi Toko (Hardcoded)
  final LatLng _storeLocation = const LatLng(-6.201375979080287, 106.57321597183606);

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  // Fungsi helper untuk membuka URL Peta
  Future<void> _launchMapsUrl(LatLng location) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka peta.')),
        );
      }
    }
  }

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

  Future<void> _uploadProof() async {
    if (_proofImage == null) return;

    setState(() => _isLoading = true);
    final orderService = context.read<OrderService>();

    try {
      final imageUrl = await orderService.uploadPaymentProof(_proofImage!);
      await orderService.updateOrderPayment(
        orderId: _currentOrder.id,
        newStatus: 'processing',
        paymentImageUrl: imageUrl,
      );

      final updatedOrder = await orderService.getOrderById(_currentOrder.id);
      setState(() {
        _currentOrder = updatedOrder;
        _proofImage = null;
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
        title: Text('Detail Pesanan #${_currentOrder.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Ringkasan Umum ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Tanggal Pesan', DateFormat('d MMM y, HH:mm', 'id_ID').format(_currentOrder.createdAt)),
                    _buildDetailRow('Status', statusHelper.getStatusText(_currentOrder.status), valueColor: statusHelper.getStatusColor(_currentOrder.status)),
                    if (_currentOrder.ongkir != null && _currentOrder.ongkir! > 0)
                      _buildDetailRow('Ongkos Kirim', currencyFormatter.format(_currentOrder.ongkir)),
                    _buildDetailRow('Total Pembayaran', currencyFormatter.format(_currentOrder.harga), isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // --- Bagian Detail Item ---
            _buildOrderItemsSection(currencyFormatter),
            const SizedBox(height: 16),

            // --- Bagian Detail Pengiriman / Pengambilan ---
            _buildFulfillmentSection(currencyFormatter),
            const SizedBox(height: 16),

            // --- Bagian Pembayaran & Upload ---
            _buildPaymentSection(isOwner),
          ],
        ),
      ),
    );
  }

  // WIDGET UNTUK DETAIL PENGIRIMAN / PENGAMBILAN
  Widget _buildFulfillmentSection(NumberFormat currencyFormatter) {
    bool isDelivery = _currentOrder.metodePengiriman == 'delivery';
    LatLng? location = isDelivery
        ? (_currentOrder.latitude != null ? LatLng(_currentOrder.latitude!, _currentOrder.longitude!) : null)
        : _storeLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isDelivery ? 'Info Pengiriman' : 'Info Pengambilan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // TOMBOL BUKA PETA BARU
            if (location != null)
              IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.blue),
                tooltip: 'Buka di Google Maps',
                onPressed: () => _launchMapsUrl(location),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Metode', isDelivery ? 'Pesan Antar (Delivery)' : 'Ambil di Tempat (Pickup)'),
                const Divider(height: 24),
                if (isDelivery) ...[
                  // --- TAMPILAN UNTUK DELIVERY ---
                  _buildDetailRow('Nama Penerima', _currentOrder.user?.nama ?? '-'),
                  _buildDetailRow('No. Telepon', _currentOrder.user?.no_telepon ?? '-'),
                  if (_currentOrder.alamatCatatan != null && _currentOrder.alamatCatatan!.isNotEmpty)
                    _buildDetailRow('Catatan Alamat', _currentOrder.alamatCatatan!),
                  if (_currentOrder.latitude != null && _currentOrder.longitude != null) ...[
                    const SizedBox(height: 16),
                    const Text('Lokasi Pengiriman:', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(initialCenter: LatLng(_currentOrder.latitude!, _currentOrder.longitude!), initialZoom: 16.0),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                          MarkerLayer(markers: [Marker(point: LatLng(_currentOrder.latitude!, _currentOrder.longitude!), child: const Icon(Icons.location_on, size: 50, color: Colors.red))]),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // --- TAMPILAN UNTUK PICKUP ---
                  if (_currentOrder.waktuPickup != null)
                    _buildDetailRow('Waktu Pengambilan', DateFormat('d MMM y, HH:mm', 'id_ID').format(_currentOrder.waktuPickup!)),
                  _buildDetailRow('Alamat Toko', 'Ps. Jatake, Jatake, Tangerang'),
                  const SizedBox(height: 16),
                  const Text('Lokasi Toko:', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(initialCenter: _storeLocation, initialZoom: 16.0),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                        MarkerLayer(markers: [Marker(point: _storeLocation, child: Icon(Icons.store, size: 50, color: Theme.of(context).primaryColor))]),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET UNTUK DAFTAR BARANG
  Widget _buildOrderItemsSection(NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Barang Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentOrder.orderDetails?.length ?? 0,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = _currentOrder.orderDetails![index];
              return ListTile(
                title: Text(item.barang?.namaBarang ?? 'Nama Barang Tidak Tersedia'),
                subtitle: Text('${item.jumlah} x ${currencyFormatter.format(item.subtotal / item.jumlah)}'),
                trailing: Text(currencyFormatter.format(item.subtotal)),
              );
            },
          ),
        ),
        if (_currentOrder.catatanPesanan != null && _currentOrder.catatanPesanan!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Card(
              child: ListTile(
                title: const Text('Catatan Pesanan', style: TextStyle(color: Colors.grey)),
                subtitle: Text(_currentOrder.catatanPesanan!),
              ),
            ),
          ),
      ],
    );
  }

  // WIDGET UNTUK BAGIAN PEMBAYARAN & UPLOAD
  Widget _buildPaymentSection(bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Info Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDetailRow('Metode Pembayaran', _currentOrder.metodePembayaran),
                const SizedBox(height: 16),
                if (_currentOrder.fotoPembayaran != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bukti Pembayaran Terunggah:', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Center(child: Image.network(_currentOrder.fotoPembayaran!, height: 250, fit: BoxFit.contain)),
                      const Divider(height: 24),
                    ],
                  ),
                if (_currentOrder.status == 'pending' && isOwner && _currentOrder.metodePengiriman != 'COD')
                  _buildUploadSection(),
              ],
            ),
          ),
        ),
      ],
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
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
          child: _proofImage != null
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_proofImage!, fit: BoxFit.contain))
              : const Center(child: Text('Pilih gambar...', style: TextStyle(color: Colors.grey))),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo_library), label: const Text('Pilih Gambar')),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: (_proofImage == null || _isLoading) ? null : _uploadProof,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('Konfirmasi & Upload'),
        ),
      ],
    );
  }

  // Helper untuk membuat baris detail
  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: isTotal ? 16 : 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: isTotal ? 18 : 14),
            ),
          ),
        ],
      ),
    );
  }
}