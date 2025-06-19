import 'dart:io';
import 'package:sayurku/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Order>> getAllOrders() async {
    final response = await _client
        .from('orders')
        .select('*, order_detail(*, barang(*))')
        .order('created_at', ascending: false);
    return (response as List).map((json) => Order.fromJson(json)).toList();
  }

  Future<List<Order>> getUserOrders(String userId) async {
    final response = await _client
        .from('orders')
        .select('*, order_detail(*, barang(*))')
        .eq('id_user', userId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Order.fromJson(json)).toList();
  }

  // Mengubah return type menjadi Future<Order>
  Future<Order> createOrder(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> orderDetails,
  ) async {
    // Memanggil RPC dan mengambil data yang baru dibuat
    final response =
        await _client
            .rpc(
              'create_order_with_details',
              params: {'order_data': orderData, 'order_details': orderDetails},
            )
            .select()
            .single(); // .single() untuk mendapatkan satu baris data

    // Mengembalikan data sebagai objek Order
    return Order.fromJson(response);
  }

  // Fungsi baru untuk upload bukti pembayaran
  Future<String> uploadPaymentProof(File imageFile) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
    await _client.storage.from('payment.image').upload(fileName, imageFile);
    return _client.storage.from('payment.image').getPublicUrl(fileName);
  }

  // Memperbarui status dan foto pembayaran
  Future<void> updateOrderPayment({
    required int orderId,
    required String newStatus,
    String? paymentImageUrl,
  }) async {
    final updates = {'status': newStatus};
    if (paymentImageUrl != null) {
      updates['foto_pembayaran'] = paymentImageUrl;
    }
    await _client.from('orders').update(updates).eq('id', orderId);
  }
}
