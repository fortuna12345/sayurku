import 'package:flutter/material.dart';
import 'package:sayurku/models/barang_model.dart';

class CartItem {
  final Barang barang;
  int quantity;

  CartItem({required this.barang, this.quantity = 1});

  double get subtotal => barang.harga * quantity;
}

class Cart extends ChangeNotifier {
  final List<CartItem> _items = [];
  double _shippingCost = 0.0;

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get itemsPrice => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get shippingCost => _shippingCost;

  // Total harga adalah harga barang + ongkos kirim
  double get totalPrice => itemsPrice + _shippingCost;

  void setShippingCost(double cost) {
    _shippingCost = cost;
    notifyListeners();
  }

  void addItem(Barang barang) {
    // Cari item di keranjang
    final index = _items.indexWhere((item) => item.barang.id == barang.id);

    if (index >= 0) {
      // Jika barang sudah ada di keranjang
      final currentQuantity = _items[index].quantity;
      // Cek apakah jumlah di keranjang masih di bawah stok
      if (currentQuantity < barang.stok) {
        _items[index].quantity++;
        notifyListeners();
      } else {
        // Jika sudah mencapai batas stok, jangan tambahkan dan jangan beri notifikasi.
        // Anda bisa menambahkan feedback ke pengguna di sini jika diperlukan.
      }
    } else {
      // Jika barang belum ada di keranjang dan stok > 0
      if (barang.stok > 0) {
        _items.add(CartItem(barang: barang));
        notifyListeners();
      }
    }
  }

  // Tipe data diubah menjadi 'int' agar sesuai dengan model Barang
  void removeItem(int barangId) {
    final index = _items.indexWhere((item) => item.barang.id == barangId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      // Memberi tahu listener agar UI diperbarui
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _shippingCost = 0.0; // Reset ongkir saat keranjang dibersihkan
    // Memberi tahu listener agar UI diperbarui
    notifyListeners();
  }
}
