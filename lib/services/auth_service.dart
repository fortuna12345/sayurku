import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sayurku/models/user_model.dart';

class AuthService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    // Initialize and check current session when service is created
    initialize();
  }

  Future<void> initialize() async {
    // Check if there's an existing session
    final currentSession = _supabase.auth.currentSession;
    if (currentSession != null) {
      await _fetchUser(currentSession.user.id);
    }
    notifyListeners();
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String no_telepon,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'nama': name,
          'no_telepon': no_telepon,
          'role': 'user', // default role untuk pendaftar baru
        });
      }
    } catch (e) {
      throw Exception('Registration error: ${e.toString()}');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      await _fetchUser(response.user!.id);
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Logout error: ${e.toString()}');
    }
  }

  Future<void> _fetchUser(String userId) async {
    try {
      final data =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();
      if (data == null) {
        _currentUser = null;
        notifyListeners();
        return;
      }

      _currentUser = UserModel.fromJson({
        ...data,
        'email': _supabase.auth.currentUser!.email, // inject email manual
      });
      notifyListeners();
    } catch (e) {
      _currentUser = null;
      notifyListeners();
      throw Exception('Failed to fetch user data: ${e.toString()}');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;

    try {
      await _supabase.from('users').update(updates).eq('id', _currentUser!.id);

      await _fetchUser(_currentUser!.id);
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  Future<void> deleteCurrentUserAccount() async {
    if (_currentUser == null) {
      throw Exception("User not logged in.");
    }

    try {
      await _supabase.rpc('delete_user_account');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Gagal menghapus akun: ${e.toString()}');
    }
  }
}
