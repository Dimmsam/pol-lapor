import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_session.dart';
import '../../../core/supabase/supabase_service.dart';

class AuthRemoteDatasource {
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
  Future<void> updatePassword(String newPassword) async {
    await SupabaseService.auth.updateUser(
      UserAttributes(password: newPassword),
    );
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
