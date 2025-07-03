import 'package:sayurku/models/barang_model.dart';
import 'package:sayurku/models/user_model.dart';

class Order {
  final int id;
  final String idUser;
  final double harga;
  final String metodePembayaran;
  final String status;
  final DateTime createdAt;
  final String metodePengiriman;
  final List<OrderDetail>? orderDetails;
  final String? fotoPembayaran;
  final double? latitude;
  final double? longitude;
  final String? alamatCatatan;
  final String? catatanPesanan;
  final DateTime? waktuPickup;
  final double? ongkir;
  final UserModel? user;

  Order({
    required this.id,
    required this.idUser,
    required this.harga,
    required this.metodePembayaran,
    required this.status,
    required this.createdAt,
    required this.metodePengiriman,
    this.orderDetails,
    this.fotoPembayaran,
    this.latitude,
    this.longitude,
    this.alamatCatatan,
    this.catatanPesanan,
    this.waktuPickup,
    this.ongkir,
    this.user,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime? parseLocal(String? dateString) {
      if (dateString == null) return null;
      // Langsung parse, Dart akan menganggapnya sebagai waktu lokal
      return DateTime.parse(dateString);
    }

    return Order(
      id: json['id'],
      idUser: json['id_user'].toString(),
      harga: json['harga'].toDouble(),
      metodePembayaran: json['metode_pembayaran'],
      status: json['status'],
      createdAt: parseLocal(json['created_at'])!,
      fotoPembayaran: json['foto_pembayaran'],
      orderDetails:
          json['order_detail'] != null
              ? (json['order_detail'] as List)
                  .map((detail) => OrderDetail.fromJson(detail))
                  .toList()
              : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      alamatCatatan: json['catatan_alamat'],
      catatanPesanan: json['catatan_pesanan'],
      metodePengiriman: json['metode_pengiriman'],
      waktuPickup:
          json['waktu_pickup'] != null
              ? parseLocal(json['waktu_pickup'])
              : null,
      ongkir: (json['ongkir'] as num?)?.toDouble(),
      user: json['users'] != null ? UserModel.fromJson(json['users']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'harga': harga,
      'metode_pembayaran': metodePembayaran,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'catatan_alamat': alamatCatatan,
      'catatan_pesanan': catatanPesanan,
    };
  }
}

class OrderDetail {
  final int id;
  final int idOrder;
  final int idBarang;
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
