class Barang {
  final int id;
  final String namaBarang;
  final double harga;
  final String? deskripsi;
  final String? gambar;
  final int? idKategori;
  final Kategori? kategori;
  final String? satuan;
  final int stok; // Tambahkan ini

  Barang({
    required this.id,
    required this.namaBarang,
    required this.harga,
    this.deskripsi,
    this.gambar,
    this.idKategori,
    this.kategori,
    this.satuan,
    required this.stok, // Tambahkan ini
  });

  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'],
      namaBarang: json['nama_barang'],
      harga: (json['harga'] as num).toDouble(),
      deskripsi: json['deskripsi'],
      gambar: json['gambar'],
      idKategori: json['id_kategori'],
      kategori:
          json['kategori'] != null ? Kategori.fromJson(json['kategori']) : null,
      satuan: json['satuan'],
      // Tambahkan stok, beri nilai default 0 jika null
      stok: json['stok'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_barang': namaBarang,
      'harga': harga,
      'deskripsi': deskripsi,
      'gambar': gambar,
      'id_kategori': idKategori,
      'satuan': satuan,
      'stok': stok, // Tambahkan ini
    };
  }
}

class Kategori {
  final int id;
  final String namaKategori;

  Kategori({required this.id, required this.namaKategori});

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(id: json['id'], namaKategori: json['nama_kategori']);
  }

  // Override untuk DropdownButton
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kategori && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
