import 'dart:io';
import 'package:sayurku/models/barang_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class BarangService {
  final SupabaseClient supabase = Supabase.instance.client;

  final String _barangTable = 'barang';
  final String _kategoriTable = 'kategori';
  final String _storageBucket =
      'barang.images'; // NAMA BUCKET DI SUPABASE STORAGE

  Future<List<Kategori>> getCategories() async {
    try {
      final response = await supabase.from(_kategoriTable).select();
      return response.map((item) => Kategori.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil kategori: $e');
    }
  }

  Future<List<Barang>> getAllBarangs() async {
    try {
      // Join dengan tabel kategori untuk mendapatkan nama kategori
      final response = await supabase
          .from(_barangTable)
          .select('*, kategori(id, nama_kategori)');
      return response.map((item) => Barang.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil barang: $e');
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';

      await supabase.storage.from(_storageBucket).upload(fileName, file);

      final urlResponse = supabase.storage
          .from(_storageBucket)
          .getPublicUrl(fileName);
      return urlResponse;
    } catch (e) {
      throw Exception('Gagal mengunggah gambar: $e');
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await supabase.storage.from(_storageBucket).remove([fileName]);
    } catch (e) {
      // Tidak melempar exception agar proses delete barang tetap berjalan
      // jika file tidak ada di storage.
      print('Gagal menghapus gambar: $e');
    }
  }

  Future<void> addBarang(Map<String, dynamic> data, {XFile? imageFile}) async {
    try {
      if (imageFile != null) {
        final imageUrl = await _uploadImage(imageFile);
        data['gambar'] = imageUrl;
      }
      await supabase.from(_barangTable).insert(data);
    } catch (e) {
      throw Exception('Gagal menambah barang: $e');
    }
  }

  Future<void> updateBarang(
    int id,
    Map<String, dynamic> data, {
    XFile? imageFile,
    String? oldImageUrl,
  }) async {
    try {
      if (imageFile != null) {
        // Hapus gambar lama jika ada dan unggah yang baru
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await _deleteImage(oldImageUrl);
        }
        final newImageUrl = await _uploadImage(imageFile);
        data['gambar'] = newImageUrl;
      }
      await supabase.from(_barangTable).update(data).eq('id', id);
    } catch (e) {
      throw Exception('Gagal memperbarui barang: $e');
    }
  }

  Future<void> deleteBarang(int id, {String? imageUrl}) async {
    try {
      // Hapus gambar dari storage terlebih dahulu
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _deleteImage(imageUrl);
      }
      await supabase.from(_barangTable).delete().eq('id', id);
    } catch (e) {
      // Handle error jika barang terkait dengan order
      if (e.toString().contains('violates foreign key constraint')) {
        throw Exception('Gagal: Barang ini sudah digunakan dalam data order.');
      }
      throw Exception('Gagal menghapus barang: $e');
    }
  }
}
