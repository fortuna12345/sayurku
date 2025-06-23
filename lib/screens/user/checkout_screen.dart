import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sayurku/models/cart_model.dart';
import 'package:sayurku/screens/user/map_picker_screen.dart';
import 'package:sayurku/screens/user/payment_screen.dart';
import 'package:sayurku/services/auth_service.dart';
import 'package:sayurku/services/order_service.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressNotesController = TextEditingController();
  final _orderNotesController = TextEditingController();
  LatLng? _deliveryLocation;
  String _paymentMethod = 'Transfer';
  bool _isLoading = false;

  // Lokasi Toko (Hardcoded)
  final LatLng _storeLocation = const LatLng(-6.175110, 106.661995);

  double _calculateDistance() {
    if (_deliveryLocation == null) return 0.0;
    const distance = Distance();
    return distance.as(
        LengthUnit.Kilometer, _storeLocation, _deliveryLocation!);
  }

  @override
  void initState() {
    super.initState();
    // Secara otomatis mengisi data pengguna setelah screen dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mengambil data dari AuthService menggunakan Provider
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        _nameController.text = currentUser.nama;
        _phoneController.text = currentUser.no_telepon!;
      }
    });
  }

  @override
  void dispose() {
    // Membersihkan controller saat widget tidak lagi digunakan
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Fungsi untuk memproses pesanan
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    final cart = context.read<Cart>();
    final authService = context.read<AuthService>();
    final orderService = context.read<OrderService>(); // Ambil instance service

    final userId = authService.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal: Pengguna tidak ditemukan.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Siapkan data untuk dikirim ke Supabase
      final orderData = {
        'id_user': userId,
        'harga': cart.totalPrice,
        'metode_pembayaran': _paymentMethod,
        'status': 'pending',
        'latitude': _deliveryLocation?.latitude,
        'longitude': _deliveryLocation?.longitude,
        'alamatCatatan': _addressNotesController.text,
        'catatanPesanan': _orderNotesController.text,
      };

      final orderDetails =
          cart.items.map((item) {
            return {
              'id_barang': item.barang.id,
              'jumlah': item.quantity,
              'subtotal': item.subtotal,
            };
          }).toList();

      // 2. Panggil service untuk membuat pesanan dan dapatkan hasilnya
      final newOrder = await orderService.createOrder(orderData, orderDetails);

      // 3. Kosongkan keranjang
      cart.clear();

      // 4. Navigasi ke halaman pembayaran dengan data pesanan yang valid dari DB
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(order: newOrder),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat pesanan: ${e.toString()}')),
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
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Pengiriman',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Masukkan nama Anda'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Masukkan nomor telepon Anda'
                            : null,
              ),
              const SizedBox(height: 24),
            const Text('Alamat Pengiriman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Bagian Peta
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.of(context).push<LatLng>(
                    MaterialPageRoute(
                      builder: (context) => MapPickerScreen(initialLocation: _deliveryLocation),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _deliveryLocation = result;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.map, color: Theme.of(context).primaryColor, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _deliveryLocation == null
                              ? 'Ketuk untuk memilih lokasi di peta'
                              : 'Lokasi telah dipilih!\nJarak: ${_calculateDistance().toStringAsFixed(2)} km',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Catatan Alamat
            TextFormField(
              controller: _addressNotesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Alamat (Opsional)',
                hintText: 'Contoh: Rumah warna hijau, depan taman',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
              Text(
                'Metode Pembayaran',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              RadioListTile<String>(
                title: const Text('Transfer Bank (BCA)'),
                value: 'Transfer',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              RadioListTile<String>(
                title: const Text('DANA'),
                value: 'DANA',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              RadioListTile<String>(
                title: const Text('Bayar di Tempat (COD)'),
                value: 'COD',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              const SizedBox(height: 24),
              Text(
                'Ringkasan Pesanan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ...cart.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.barang.namaBarang} x ${item.quantity}'),
                      Text('Rp ${item.subtotal}'),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Rp ${cart.totalPrice}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
             // Catatan Pesanan
            TextFormField(
              controller: _orderNotesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Pesanan (Opsional)',
                hintText: 'Contoh: Tolong pilihkan sayur yang segar',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _deliveryLocation == null ? null : _placeOrder,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Buat Pesanan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
