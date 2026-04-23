import 'package:flutter/foundation.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../data/models/user_session.dart';

enum LoginStatus { idle, loading, success, error }

class LoginProvider extends ChangeNotifier {
  final AuthLocalDatasource _auth = AuthLocalDatasource();

  LoginStatus _status = LoginStatus.idle;
  String? _errorMessage;
  UserSession? _session;

  LoginStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserSession? get session => _session;
  bool get isLoading => _status == LoginStatus.loading;

  // ── Cek session saat splash screen ───────────────────────────────────────
  bool isLoggedIn() => _auth.isLoggedIn();

  UserSession? getExistingSession() => _auth.getSession();

  // ── Login ─────────────────────────────────────────────────────────────────
  // Untuk MVP: validasi lokal dengan kredensial hardcode per role.
  // Milestone 2: ganti dengan hit MongoDB langsung.
  Future<void> login(String email, String password) async {
    _status = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500)); // simulasi proses

    try {
      final mockUsers = _getMockUsers();
      final matched = mockUsers.where(
        (u) => u['email'] == email && u['password'] == password,
      );

      if (matched.isEmpty) {
        _status = LoginStatus.error;
        _errorMessage = 'Email atau password salah.';
        notifyListeners();
        return;
      }

      final user = matched.first;
      final session = UserSession(
        userId: user['userId']!,
        nama: user['nama']!,
        email: user['email']!,
        role: user['role']!,
        token: 'mock-token-${user['userId']}', // diganti token nyata di M2
      );

      await _auth.saveSession(session);
      _session = session;
      _status = LoginStatus.success;
      notifyListeners();
    } catch (e) {
      _status = LoginStatus.error;
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.clearSession();
    _session = null;
    _status = LoginStatus.idle;
    notifyListeners();
  }

  // ── Reset state error ─────────────────────────────────────────────────────
  void resetError() {
    _errorMessage = null;
    _status = LoginStatus.idle;
    notifyListeners();
  }

  // ── Mock users untuk MVP (sebelum MongoDB auth siap) ─────────────────────
  List<Map<String, String>> _getMockUsers() {
    return [
      {
        'userId': 'user-001',
        'nama': 'Budi Mahasiswa',
        'email': 'pelapor@polban.ac.id',
        'password': 'password123',
        'role': 'pelapor',
      },
      {
        'userId': 'user-002',
        'nama': 'Drs. Ahmad Kasubbag',
        'email': 'kasubbag@polban.ac.id',
        'password': 'password123',
        'role': 'kasubbag_tu',
      },
      {
        'userId': 'user-003',
        'nama': 'Siti Petugas BMN',
        'email': 'bmn@polban.ac.id',
        'password': 'password123',
        'role': 'petugas_bmn',
      },
      {
        'userId': 'user-004',
        'nama': 'Rudi Teknisi',
        'email': 'teknisi@polban.ac.id',
        'password': 'password123',
        'role': 'teknisi_upt',
      },
      {
        'userId': 'user-005',
        'nama': 'Admin Sistem',
        'email': 'admin@polban.ac.id',
        'password': 'admin123',
        'role': 'admin',
      },
    ];
  }
}