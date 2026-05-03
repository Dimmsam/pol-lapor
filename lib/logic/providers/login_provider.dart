import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/models/user_session.dart';

enum LoginStatus { idle, loading, success, error }

class LoginProvider extends ChangeNotifier {
  final AuthLocalDatasource _localAuth = AuthLocalDatasource();
  final AuthRemoteDatasource _remoteAuth = AuthRemoteDatasource();

  LoginStatus _status = LoginStatus.idle;
  String? _errorMessage;
  UserSession? _session;

  LoginStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserSession? get session => _session;
  bool get isLoading => _status == LoginStatus.loading;

  // ── Cek session lokal saat splash ────────────────────────────────────────
  bool isLoggedIn() => _localAuth.isLoggedIn();

  UserSession? getExistingSession() => _localAuth.getSession();

  // ── Login via Supabase Auth ───────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    _status = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Hit Supabase Auth → ambil JWT + profil dari tabel pengguna
      final session = await _remoteAuth.login(email, password);

      // Simpan ke Hive lokal untuk offline session
      await _localAuth.saveSession(session);
      _session = session;
      _status = LoginStatus.success;
    } on AuthException catch (e) {
      _status = LoginStatus.error;
      _errorMessage = _mapAuthError(e.message);
    } catch (e) {
      _status = LoginStatus.error;
      _errorMessage = 'Terjadi kesalahan. Periksa koneksi internet kamu.';
    }

    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _remoteAuth.logout();
    await _localAuth.clearSession();
    _session = null;
    _status = LoginStatus.idle;
    notifyListeners();
  }

  // ── Reset error ───────────────────────────────────────────────────────────
  void resetError() {
    _errorMessage = null;
    _status = LoginStatus.idle;
    notifyListeners();
  }

  // ── Map pesan error Supabase → bahasa Indonesia ───────────────────────────
  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox kamu.';
    }
    if (message.contains('Too many requests')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa saat.';
    }
    if (message.contains('network') || message.contains('connect')) {
      return 'Tidak ada koneksi internet.';
    }
    return 'Login gagal: $message';
  }
}
