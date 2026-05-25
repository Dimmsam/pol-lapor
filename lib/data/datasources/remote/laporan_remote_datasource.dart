// lib/data/datasources/remote/laporan_remote_datasource.dart
// Query Supabase untuk fitur peringatan laporan serupa.

import '../../../core/supabase/supabase_service.dart';

class LaporanRemoteDatasource {
  // ── CEK LAPORAN AKTIF DI LOKASI YANG SAMA (ONLINE CHECK) ─────────────────
  /// Mengembalikan jumlah laporan aktif (belum selesai) di lokasi tertentu
  /// langsung dari Supabase. Return null jika gagal/offline.
  Future<int?> countLaporanAktifByLokasi(String lokasi) async {
    try {
      final response = await SupabaseService.db
          .from('formulir_laporan')
          .select('formulir_id')
          .eq('lokasi_perbaikan', lokasi)
          .neq('status', 'selesai')
          .count();

      return response.count;
    } catch (_) {
      return null; // Gagal (misal offline) → fallback ke data lokal
    }
  }

  /// Mengembalikan detail singkat laporan aktif di lokasi tertentu.
  /// Dipakai untuk menampilkan info lebih lengkap pada peringatan.
  Future<List<Map<String, dynamic>>> getLaporanAktifByLokasi(
    String lokasi,
  ) async {
    try {
      final response = await SupabaseService.db
          .from('formulir_laporan')
          .select('formulir_id, nama_sarana, status, created_at')
          .eq('lokasi_perbaikan', lokasi)
          .neq('status', 'selesai')
          .order('created_at', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }
}
