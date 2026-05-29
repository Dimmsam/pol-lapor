import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/models/user_session.dart';
import '../../services/sync_service.dart';
import '../providers/notifikasi_provider.dart';
import 'package:provider/provider.dart';

enum LoginStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthLocalDatasource _localAuth = AuthLocalDatasource();
  final AuthRemoteDatasource _remoteAuth = AuthRemoteDatasource();

  LoginStatus _status = LoginStatus.idle;
  String? _errorMessage;
  UserSession? _session;

  LoginStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserSession? get session => _session;
  bool get isLoading => _status == LoginStatus.loading;

  bool isLoggedIn() => _localAuth.isLoggedIn();

  UserSession? getExistingSession() => _localAuth.getSession();

  /// Dipakai splash: restore session Supabase atau bersihkan lokal
  Future<UserSession?> restoreSession() async {
    final remote = await _remoteAuth.getSessionFromSupabase();
    if (remote != null) {
      await _localAuth.saveSession(remote);
      _session = remote;
      notifyListeners();
      return remote;
    }

    await _localAuth.clearSession();
    _session = null;
    notifyListeners();
    return null;
  }

  Future<void> login(String email, String password) async {
    _status = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _remoteAuth.login(email, password);
      await _localAuth.saveSession(session);
      _session = session;
      _status = LoginStatus.success;
    } on AuthException catch (e) {
      _status = LoginStatus.error;
      _errorMessage = _mapAuthError(e.message);
    } catch (e, st) {
      _status = LoginStatus.error;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      debugPrint('AuthProvider unexpected error: $e');
      debugPrint('$st');
    }

    notifyListeners();
  }

  /// Method untuk init services setelah login berhasil
  /// Dipanggil dari UI setelah login success
  void initPostLoginServices(BuildContext context) {
    if (_session == null) return;
    
    // Init NotifikasiProvider untuk realtime notifications
    try {
      context.read<NotifikasiProvider>().init(_session!.userId);
    } catch (e) {
      debugPrint('Error init NotifikasiProvider: $e');
    }
  }

  Future<void> logout() async {
    await _localAuth.clearSession();
    _session = null;
    _status = LoginStatus.idle;
    notifyListeners();

    try {
      await _remoteAuth.logout();
    } catch (e) {
      debugPrint('AuthProvider logout remote warning: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await _remoteAuth.updatePassword(newPassword);
  }

  Future<void> updateNama(String nama) async {
    final current = _session ?? _localAuth.getSession();
    if (current == null) return;

    // Validasi nama tidak boleh kosong
    if (nama.trim().isEmpty) {
      throw Exception('Nama tidak boleh kosong');
    }

    // Update ke Supabase terlebih dahulu
    await _remoteAuth.updateNamaLengkap(current.userId, nama.trim());

    // Kemudian update lokal
    final updated = UserSession(
      userId: current.userId,
      nama: nama.trim(),
      email: current.email,
      role: current.role,
      token: current.token,
      keahlian: current.keahlian,
      nomorTelepon: current.nomorTelepon,
    );
    await _localAuth.saveSession(updated);
    _session = updated;
    notifyListeners();
  }

  void resetError() {
    _errorMessage = null;
    _status = LoginStatus.idle;
    notifyListeners();
  }

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
