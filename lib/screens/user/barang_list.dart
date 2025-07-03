import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sayurku/models/cart_model.dart';
import 'package:sayurku/models/barang_model.dart';
import 'package:sayurku/services/barang_service.dart';
import 'package:sayurku/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

class BarangListScreen extends StatefulWidget {
  BarangListScreen({super.key});

  @override
  State<BarangListScreen> createState() => _BarangListScreenState();
}

class _BarangListScreenState extends State<BarangListScreen> {
  final BarangService _barangService = BarangService();
  List<Barang> _barangs = [];
  List<Kategori> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Mengambil data barang dan kategori secara bersamaan
      final results = await Future.wait([
        _barangService.getAllBarangs(),
        _barangService.getCategories(),
      ]);
      _barangs = results[0] as List<Barang>;
      _categories = results[1] as List<Kategori>;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Logika filter yang diperbarui
  List<Barang> get _filteredBarangs {
    List<Barang> barangs = _barangs;

    if (_selectedCategory != 'Semua') {
      barangs =
          barangs
              .where(
                (barang) => barang.kategori?.namaKategori == _selectedCategory,
              )
              .toList();
    }

    if (_searchQuery.isNotEmpty) {
      barangs =
          barangs
              .where(
                (barang) => barang.namaBarang.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }
    return barangs;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari Sayur...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // 2. Filter Kategori
        _buildCategoryFilter(),

        // 3. Daftar Barang (ListView)
        Expanded(
          child:
              _isLoading
                  ? const LoadingIndicator()
                  : RefreshIndicator(
                    onRefresh: _loadData,
                    child:
                        _filteredBarangs.isEmpty
                            ? const Center(
                              child: Text('Barang tidak ditemukan.'),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              itemCount: _filteredBarangs.length,
                              itemBuilder: (context, index) {
                                return _buildNewBarangCard(
                                  _filteredBarangs[index],
                                );
                              },
                            ),
                  ),
        ),
      ],
    );
  }

  // Widget untuk filter kategori
  Widget _buildCategoryFilter() {
    final List<Kategori> displayCategories = [
      Kategori(id: -1, namaKategori: 'Semua'), // Kategori dummy 'Semua'
      ..._categories,
    ];

    final categoryIcons = {
      'Semua': Icons.fastfood_outlined,
      'Nasi': Icons.rice_bowl_outlined,
      'Snack': Icons.cookie_outlined,
      'Dessert': Icons.cake_outlined,
      'Minuman': Icons.local_drink_outlined,
    };

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          final bool isSelected = category.namaKategori == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                categoryIcons[category.namaKategori] ?? Icons.label_outline,
                color:
                    isSelected ? Colors.white : Theme.of(context).primaryColor,
                size: 20,
              ),
              label: Text(category.namaKategori),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category.namaKategori);
                }
              },
              backgroundColor:
                  isSelected ? Theme.of(context).primaryColor : Colors.white,
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: StadiumBorder(
                side: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
              elevation: 1,
              pressElevation: 3,
            ),
          );
        },
      ),
    );
  }

  // Widget untuk kartu barang baru
  Widget _buildNewBarangCard(Barang barang) {
    final cart = Provider.of<Cart>(context, listen: false);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final bool isOutOfStock = barang.stok <= 0;

    return Card(
      color: isOutOfStock ? Colors.grey.shade200 : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gambar
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child:
                  barang.gambar != null && barang.gambar!.isNotEmpty
                      ? Image.network(
                        barang.gambar!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.grey,
                              ),
                            ),
                      )
                      : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
            ),
            const SizedBox(width: 12),

            // Detail Barang
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    barang.namaBarang,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration:
                          isOutOfStock ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  // const SizedBox(height: 5),
                  // Row(
                  //   children: [
                  //     const Icon(Icons.star, color: Colors.amber, size: 18),
                  //     const SizedBox(width: 4),
                  //     Text(
                  //       '4.8',
                  //       style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  //     ),
                  //     const SizedBox(width: 12),
                  //     Icon(
                  //       Icons.timer_outlined,
                  //       color: Colors.grey[700],
                  //       size: 16,
                  //     ),
                  //     const SizedBox(width: 4),
                  //     Text(
                  //       '15 menit',
                  //       style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 8),
                  Text(
                    '${currencyFormatter.format(barang.harga)} / ${barang.satuan ?? ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color:
                          isOutOfStock
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isOutOfStock)
                    Text(
                      'Sisa Stok: ${barang.stok}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  // Tampilkan label "Stok Habis"
                  if (isOutOfStock)
                    const Text(
                      'Stok Habis',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Tombol Tambah
            // ElevatedButton(
            //   onPressed: () {
            //     cart.addItem(barang);
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       SnackBar(
            //         content: Text('${barang.namaBarang} ditambahkan ke keranjang.'),
            //         duration: const Duration(seconds: 1),
            //         backgroundColor: Colors.green,
            //       ),
            //     );
            //   },
            //   style: ElevatedButton.styleFrom(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(10),
            //     ),
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 16,
            //       vertical: 12,
            //     ),
            //   ),
            //   child: const Text('Tambah'),
            // ),
            FloatingActionButton.small(
              heroTag: 'add_barang_${barang.id}',
              // Nonaktifkan tombol jika stok habis
              onPressed:
                  isOutOfStock
                      ? null
                      : () {
                        final cart = context.read<Cart>();
                        final itemInCart = cart.items.firstWhere(
                          (item) => item.barang.id == barang.id,
                          orElse:
                              () => CartItem(
                                barang: barang,
                                quantity: 0,
                              ), // Item dummy jika tidak ditemukan
                        );

                        if (itemInCart.quantity < barang.stok) {
                          cart.addItem(barang);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${barang.namaBarang} ditambahkan ke keranjang.',
                              ),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          // Beri feedback jika stok di keranjang sudah maksimal
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Jumlah pesanan sudah mencapai batas stok.',
                              ),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
              // Ubah ikon dan warna jika stok habis
              backgroundColor:
                  isOutOfStock ? Colors.grey : Theme.of(context).primaryColor,
              child:
                  isOutOfStock
                      ? const Icon(Icons.remove_shopping_cart)
                      : const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
