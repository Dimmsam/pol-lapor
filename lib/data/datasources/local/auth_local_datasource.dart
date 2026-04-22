import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user_session.dart';
import '../../../core/constants/app_constants.dart';

class AuthLocalDatasource {
  Box<UserSession> get _box => Hive.box<UserSession>(AppConstants.boxUser);

  // Simpan session setelah login berhasil
  Future<void> saveSession(UserSession session) async {
    await _box.put('current_user', session);
  }

  // Ambil session yang sedang aktif
  UserSession? getSession() {
    return _box.get('current_user');
  }

  // Cek apakah user sudah login
  bool isLoggedIn() {
    return _box.get('current_user') != null;
  }

  // Hapus session saat logout
  Future<void> clearSession() async {
    await _box.delete('current_user');
  }
}