class UserModel {
  final String id;
  final String? email;
  final String nama;
  final String role;
  final String? no_telepon;

  UserModel({
    required this.id,
    this.email,
    required this.nama,
    required this.role,
    this.no_telepon,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      nama: json['nama'] ?? 'User Tidak Ditemukan',
      role: json['role'] ?? 'user',
      no_telepon: json['no_telepon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nama': nama,
      'role': role,
      'no_telepon': no_telepon,
    };
  }
}