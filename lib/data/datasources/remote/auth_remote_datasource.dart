import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_session.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_service.dart';

class AuthRemoteDatasource {
  // ── Register pelapor baru ─────────────────────────────────────────────────
  Future<UserSession> register({
    required String namaLengkap,
    required String email,
    required String password,
    String? nomorTelepon,
  }) async {
    // LANGKAH 1: Buat akun di Supabase Auth
    // Tidak ada trigger → signUp murni hanya buat di auth.users
    final signUpResponse = await SupabaseService.auth.signUp(
      email: email,
      password: password,
    );

    if (signUpResponse.user == null) {
      throw Exception('Registrasi gagal: akun tidak dapat dibuat');
    }

    final userId = signUpResponse.user!.id;

    // LANGKAH 2: Login langsung untuk mendapatkan token aktif
    // (tanpa token aktif, INSERT ke tabel pengguna akan diblokir RLS)
    final loginResponse = await SupabaseService.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (loginResponse.session == null) {
      throw Exception('Registrasi berhasil tapi login otomatis gagal. Silakan login manual.');
    }

    // LANGKAH 3: Insert profil ke tabel pengguna (sekarang sudah autentikasi)
    await SupabaseService.db.from('pengguna').insert({
      'user_id': userId,
      'nama_lengkap': namaLengkap.trim(),
      'email': email.trim(),
      'role': AppConstants.rolePelapor,
      'nomor_telepon': nomorTelepon?.trim().isEmpty == true
          ? null
          : nomorTelepon?.trim(),
    });

    return UserSession(
      userId: userId,
      nama: namaLengkap.trim(),
      email: email.trim(),
      role: AppConstants.rolePelapor,
      token: loginResponse.session!.accessToken,
      nomorTelepon: nomorTelepon?.trim().isEmpty == true
          ? null
          : nomorTelepon?.trim(),
    );
  }

  // ── Login dengan Supabase Auth ────────────────────────────────────────────
  Future<UserSession> login(String email, String password) async {
    final response = await SupabaseService.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login gagal: user tidak ditemukan');
    }

    // Ambil data profil dari tabel pengguna menggunakan user_id (auth id disimpan di kolom user_id)
    final profil = await SupabaseService.db
        .from('pengguna')
        .select()
        .eq('user_id', response.user!.id)
        .single();

    return UserSession(
      userId: profil['user_id'] as String,
      nama: profil['nama_lengkap'] as String,
      email: profil['email'] as String,
      role: profil['role'] as String,
      token: response.session?.accessToken ?? '',
      keahlian: profil['keahlian'] as String?,
      nomorTelepon: profil['nomor_telepon'] as String?,
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await SupabaseService.auth.signOut();
  }

  // ── Ubah password ────────────────────────────────────────────────────────
  Future<void> updatePassword(String email, String oldPassword, String newPassword) async {
    // Re-authenticate untuk memastikan oldPassword benar
    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: oldPassword,
      );
      if (response.user == null) {
        throw Exception('Password lama salah');
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw Exception('Password lama salah');
      }
      rethrow;
    }

    // Update ke password baru
    await SupabaseService.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ── Update nama lengkap di tabel pengguna ─────────────────────────────────
  Future<void> updateNamaLengkap(String userId, String namaLengkap) async {
    await SupabaseService.db
        .from('pengguna')
        .update({'nama_lengkap': namaLengkap})
        .eq('user_id', userId);
  }

  // ── Cek session masih valid ───────────────────────────────────────────────
  Future<UserSession?> getSessionFromSupabase() async {
    final supabaseSession = SupabaseService.auth.currentSession;
    if (supabaseSession == null) return null;

    // Token masih valid, ambil profil
    try {
      final profil = await SupabaseService.db
          .from('pengguna')
          .select()
          .eq('user_id', supabaseSession.user.id)
          .single();

      return UserSession(
        userId: profil['user_id'] as String,
        nama: profil['nama_lengkap'] as String,
        email: profil['email'] as String,
        role: profil['role'] as String,
        token: supabaseSession.accessToken,
        keahlian: profil['keahlian'] as String?,
        nomorTelepon: profil['nomor_telepon'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
