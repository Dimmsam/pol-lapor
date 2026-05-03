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

    // Ambil data profil dari tabel pengguna menggunakan auth_id
    final profil = await SupabaseService.db
        .from('pengguna')
        .select()
        .eq('auth_id', response.user!.id)
        .single();

    return UserSession(
      userId: profil['user_id'] as String,
      nama: profil['nama_lengkap'] as String,
      email: profil['email'] as String,
      role: profil['role'] as String,
      token: response.session?.accessToken ?? '',
      unitGedung: profil['unit_jurusan'] as String?,
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await SupabaseService.auth.signOut();
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
          .eq('auth_id', supabaseSession.user.id)
          .single();

      return UserSession(
        userId: profil['user_id'] as String,
        nama: profil['nama_lengkap'] as String,
        email: profil['email'] as String,
        role: profil['role'] as String,
        token: supabaseSession.accessToken,
        unitGedung: profil['unit_jurusan'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
