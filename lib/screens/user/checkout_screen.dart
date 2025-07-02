import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:sayurku/models/cart_model.dart';
import 'package:sayurku/screens/user/map_picker_screen.dart';
import 'package:sayurku/screens/user/payment_screen.dart';
import 'package:sayurku/services/auth_service.dart';
import 'package:sayurku/services/order_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum FulfillmentMethod { delivery, pickup }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  FulfillmentMethod _method = FulfillmentMethod.delivery;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressNotesController = TextEditingController();
  final _orderNotesController = TextEditingController();
  LatLng? _deliveryLocation;
  String _paymentMethod = 'Transfer';
  bool _isLoading = false;

  // Pickup state
  DateTime? _selectedPickupTime;

  // Lokasi Toko (Hardcoded)
  final LatLng _storeLocation = const LatLng(-6.201375979080287, 106.57321597183606);

  double _calculateDistance() {
    if (_deliveryLocation == null) return 0.0;
    const distance = Distance();
    return distance.as(
        LengthUnit.Kilometer, _storeLocation, _deliveryLocation!);
  }

  void _updateShippingCost() {
    final cart = context.read<Cart>();
    if (_method == FulfillmentMethod.delivery && _deliveryLocation != null) {
      // Contoh: Rp 2,500 per km
      final cost = _calculateDistance() * 2500;
      cart.setShippingCost(cost);
    } else {
      cart.setShippingCost(0);
    }
  }

  Future<void> _launchMapsUrl(LatLng location) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka peta untuk lokasi: ${location.latitude}, ${location.longitude}')),
      );
    }
  }

  Future<void> _selectPickupTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;

    setState(() {
      _selectedPickupTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
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

      if (mounted) {
        // Reset shipping cost after the first frame is built
        context.read<Cart>().setShippingCost(0);
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

  Future<void> _placeOrder() async {
    // Validasi input
    if (_method == FulfillmentMethod.delivery && _deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih lokasi pengiriman.'), backgroundColor: Colors.red));
      return;
    }
    if (_method == FulfillmentMethod.pickup && _selectedPickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih waktu pengambilan.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    final cart = context.read<Cart>();
    final authService = context.read<AuthService>();
    final orderService = context.read<OrderService>();
    final userId = authService.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal: Pengguna tidak ditemukan.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final orderData = {
        'id_user': userId,
        'harga': cart.totalPrice, // Total harga sudah termasuk ongkir dari Cart model
        'metode_pembayaran': _paymentMethod,
        'status': 'pending',
        'metode_pengiriman': _method.name, // 'delivery' atau 'pickup'
        'ongkir': _method == FulfillmentMethod.delivery ? cart.shippingCost : null,
        'latitude': _deliveryLocation?.latitude,
        'longitude': _deliveryLocation?.longitude,
        'alamat_catatan': _addressNotesController.text,
        'catatan_pesanan': _orderNotesController.text,
        'waktu_pickup': _method == FulfillmentMethod.pickup ? _selectedPickupTime?.toIso8601String() : null,
      };

      final orderDetails = cart.items.map((item) => {
        'id_barang': item.barang.id, 'jumlah': item.quantity, 'subtotal': item.subtotal,
      }).toList();

      final newOrder = await orderService.createOrder(orderData, orderDetails);
      cart.clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PaymentScreen(order: newOrder)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat pesanan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pilihan Metode: Pickup atau Delivery
              SegmentedButton<FulfillmentMethod>(
                segments: const [
                  ButtonSegment(value: FulfillmentMethod.delivery, label: Text('Delivery'), icon: Icon(Icons.local_shipping)),
                  ButtonSegment(value: FulfillmentMethod.pickup, label: Text('Pickup'), icon: Icon(Icons.store)),
                ],
                selected: {_method},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _method = newSelection.first;
                    // Jika beralih ke Delivery & sebelumnya COD, reset pembayaran
                    if (_method == FulfillmentMethod.delivery && _paymentMethod == 'COD') {
                      _paymentMethod = 'Transfer';
                    }
                    _updateShippingCost(); // Update ongkir saat metode berubah
                  });
                },
              ),
              const SizedBox(height: 24),
              // Tampilkan UI berdasarkan metode yang dipilih
              if (_method == FulfillmentMethod.delivery)
                _buildDeliveryForm()
              else
                _buildPickupForm(),
              
              const SizedBox(height: 24),
              _buildPaymentMethod(),
              const SizedBox(height: 24),
              _buildOrderSummary(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _placeOrder,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Buat Pesanan'),
        ),
      ),
    );
  }

  // Widget untuk form Delivery
  Widget _buildDeliveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alamat Pengiriman', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.of(context).push<LatLng>(
                MaterialPageRoute(builder: (context) => MapPickerScreen(initialLocation: _deliveryLocation)),
              );
              if (result != null) {
                setState(() {
                  _deliveryLocation = result;
                  _updateShippingCost();
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.map, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(_deliveryLocation == null
                        ? 'Pilih lokasi di peta'
                        : 'Lokasi dipilih (${_calculateDistance().toStringAsFixed(1)} km)'),
                  ),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressNotesController,
          decoration: const InputDecoration(labelText: 'Catatan Alamat (Opsional)', hintText: 'Cth: Rumah warna hijau', border: OutlineInputBorder()),
          maxLines: 2,
        ),
      ],
    );
  }

  // Widget untuk form Pickup
 Widget _buildPickupForm() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Menggunakan Row untuk menempatkan judul dan tombol
        Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Bungkus Text dengan Expanded agar fleksibel
          Expanded(
            child: Text(
              'Lokasi & Waktu Pengambilan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // 2. Tombol akan ditempatkan di sebelah kanan tanpa mendorong teks
          IconButton(
            icon: Icon(Icons.open_in_new_rounded, color: Theme.of(context).primaryColor),
            tooltip: 'Buka di aplikasi peta',
            onPressed: () => _launchMapsUrl(_storeLocation),
          ),
        ],
      ),
      const SizedBox(height: 8), // Mengurangi jarak agar lebih rapat
      // Peta Lokasi Toko
      SizedBox(
        height: 150,
        child: AbsorbPointer(
          child: FlutterMap(
            options: MapOptions(initialCenter: _storeLocation, initialZoom: 15),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(markers: [Marker(point: _storeLocation, child: Icon(Icons.store, size: 50, color: Theme.of(context).primaryColor))]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
        // Pemilihan Waktu
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _selectPickupTime,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(_selectedPickupTime == null
                        ? 'Pilih waktu pengambilan'
                        : DateFormat('d MMM y, HH:mm', 'id_ID').format(_selectedPickupTime!)),
                  ),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget untuk metode pembayaran
  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Metode Pembayaran', style: Theme.of(context).textTheme.titleLarge),
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
        // PERUBAHAN LOGIKA: Tampilkan COD hanya untuk metode Pickup
        if (_method == FulfillmentMethod.pickup)
          RadioListTile<String>(
            title: const Text('Bayar di Tempat (COD)'),
            value: 'COD',
            groupValue: _paymentMethod,
            onChanged: (value) => setState(() => _paymentMethod = value!),
          ),
      ],
    );
  }
  
  // Widget untuk ringkasan pesanan
  Widget _buildOrderSummary() {
    final cart = context.watch<Cart>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ringkasan Pesanan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ...cart.items.map((item) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${item.barang.namaBarang} x${item.quantity}'),
            Text(currencyFormatter.format(item.subtotal)),
          ],
        )),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal Barang'),
            Text(currencyFormatter.format(cart.itemsPrice)),
          ],
        ),
        if (_method == FulfillmentMethod.delivery)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ongkos Kirim'),
              Text(currencyFormatter.format(cart.shippingCost)),
            ],
          ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(currencyFormatter.format(cart.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _orderNotesController,
          decoration: const InputDecoration(labelText: 'Catatan Pesanan (Opsional)', border: OutlineInputBorder()),
          maxLines: 2,
        ),
      ],
    );
  }
}