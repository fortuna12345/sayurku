import 'package:sayurku/models/barang_model.dart';

class Order {
  final int id; // Diubah dari String ke int
  final String idUser;
  final double harga;
  final String metodePembayaran;
  final String status;
  final DateTime createdAt;
  final List<OrderDetail>? orderDetails;
  final String? fotoPembayaran; // Kolom baru ditambahkan

  Order({
    required this.id,
    required this.idUser,
    required this.harga,
    required this.metodePembayaran,
    required this.status,
    required this.createdAt,
    this.orderDetails,
    this.fotoPembayaran, // Ditambahkan di constructor
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'], // Tipe data sudah int
      idUser: json['id_user'].toString(),
      harga: json['harga'].toDouble(),
      metodePembayaran: json['metode_pembayaran'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      fotoPembayaran: json['foto_pembayaran'], // Ditambahkan
      orderDetails:
          json['order_detail'] != null
              ? (json['order_detail'] as List)
                  .map((detail) => OrderDetail.fromJson(detail))
                  .toList()
              : null,
    );
  }

  // toJson tidak perlu diubah karena data ini dikirim ke RPC
  // yang di-handle di service
  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'harga': harga,
      'metode_pembayaran': metodePembayaran,
      'status': status,
    };
  }
}

class OrderDetail {
  final int id; // Diubah dari String ke int
  final int idOrder; // Diubah dari String ke int
  final int idBarang; // Diubah dari String ke int
  final int jumlah;
  final double subtotal;
  final Barang? barang;

  OrderDetail({
    required this.id,
    required this.idOrder,
    required this.idBarang,
    required this.jumlah,
    required this.subtotal,
    this.barang,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'],
      idOrder: json['id_order'],
      idBarang: json['id_barang'],
      jumlah: json['jumlah'],
      subtotal: json['subtotal'].toDouble(),
      barang: json['barang'] != null ? Barang.fromJson(json['barang']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_order': idOrder,
      'id_barang': idBarang,
      'jumlah': jumlah,
      'subtotal': subtotal,
    };
  }
}
