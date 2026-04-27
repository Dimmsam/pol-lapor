import 'package:flutter/foundation.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/models/user_session.dart';
import '../../core/constants/app_constants.dart';

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
      'email': 'mahasiswa@polban.ac.id',
      'password': 'password123',
      'role': AppConstants.roleMahasiswa,
    },
    {
      'userId': 'user-002',
      'nama': 'Rudi Teknisi Jurusan',
      'email': 'teknisi.jurusan@polban.ac.id',
      'password': 'password123',
      'role': AppConstants.roleTeknisiJurusan,
      'unitGedung': 'Jurusan Teknik Informatika',
    },
    {
      'userId': 'user-003',
      'nama': 'Sari Admin Jurusan',
      'email': 'admin.jurusan@polban.ac.id',
      'password': 'password123',
      'role': AppConstants.roleAdminJurusan,
      'unitGedung': 'Jurusan Teknik Informatika',
    },
    {
      'userId': 'user-004',
      'nama': 'Dr. Ahmad Kajur',
      'email': 'kajur@polban.ac.id',
      'password': 'password123',
      'role': AppConstants.roleKajur,
    },
    {
      'userId': 'user-005',
      'nama': 'Dewi Admin UPT PP',
      'email': 'admin.upt@polban.ac.id',
      'password': 'password123',
      'role': AppConstants.roleAdminUptPp,
    },
    {
      'userId': 'user-006',
      'nama': 'Dr. Budi Ketua UPT PP',
      'email': 'ketua.upt@polban.ac.id',
      'password': 'password123',
      'role': AppConstants.roleKetuaUptPp,
    },
    {
      'userId': 'user-007',
      'nama': 'Joko Teknisi UPT PP',
      'email': 'teknisi.upt@polban.ac.id',
      'password': 'password123',
      'role': AppConstants.roleTeknisiUptPp,
    },
  ];
  }
}
