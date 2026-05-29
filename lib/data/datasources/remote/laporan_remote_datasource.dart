import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';

class LaporanRemoteDatasource {
  final SupabaseClient _db = SupabaseService.db;

  // ── CEK LAPORAN AKTIF DI LOKASI YANG SAMA (ONLINE CHECK) ─────────────────

  Future<String?> _resolveLokasiId(String namaRuangan) async {
    try {
      final resp = await _db
          .from('lokasi')
          .select('lokasi_id')
          .eq('nama_ruangan', namaRuangan.trim())
          .eq('is_active', true)
          .maybeSingle();
      return resp?['lokasi_id'] as String?;
    } catch (e) {
      debugPrint('_resolveLokasiId gagal untuk "$namaRuangan": $e');
      return null;
    }
  }

  /// Mengembalikan jumlah laporan aktif (belum selesai) di lokasi tertentu
  /// langsung dari Supabase. Return null jika gagal/offline.
  Future<int?> countLaporanAktifByLokasi(String namaRuangan) async {
    try {
      final lokasiId = await _resolveLokasiId(namaRuangan);
      if (lokasiId == null) return 0;

      final response = await _db
          .from('formulir_laporan')
          .select('formulir_id')
          .eq('lokasi_id', lokasiId)
          .neq('status', 'selesai')
          .count();

      return response.count;
    } catch (_) {
      return null; // Gagal (misal offline)
    }
  }

  /// Mengembalikan detail singkat laporan aktif di lokasi tertentu.
  /// Dipakai untuk menampilkan info lebih lengkap pada peringatan.
  Future<List<Map<String, dynamic>>> getLaporanAktifByLokasi(
    String namaRuangan,
  ) async {
    try {
      final lokasiId = await _resolveLokasiId(namaRuangan);
      if (lokasiId == null) return [];

      final response = await _db
          .from('formulir_laporan')
          .select('formulir_id, nama_sarana, status, created_at')
          .eq('lokasi_id', lokasiId)
          .neq('status', 'selesai')
          .order('created_at', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteLaporan({
    required String formulirId,
    required String pelaporId,
  }) async {
    final currentUser = _db.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Sesi login Supabase tidak ditemukan');
    }

    if (currentUser.id != pelaporId) {
      throw Exception('Kamu hanya bisa menghapus laporan milikmu sendiri');
    }

    try {
      await _db.from('tracking').delete().eq('formulir_id', formulirId);
    } catch (e) {
      debugPrint('Gagal hapus tracking untuk $formulirId: $e');
    }

    try {
      await _db.from('penanganan').delete().eq('formulir_id', formulirId);
    } catch (e) {
      debugPrint('Gagal hapus penanganan untuk $formulirId: $e');
    }

    final response = await _db
        .from('formulir_laporan')
        .delete()
        .eq('formulir_id', formulirId)
        .eq('pelapor_id', pelaporId)
        .select();

    if (response.isEmpty) {
      throw Exception('Laporan tidak ditemukan atau tidak punya akses hapus');
    }
  }

  /// Fetch semua laporan milik pelapor dari Supabase untuk sinkronisasi.
  Future<List<Map<String, dynamic>>> fetchLaporanByPelapor(
    String pelaporId,
  ) async {
    try {
      final response = await _db
          .from('formulir_laporan')
          .select('''
            formulir_id,
            pelapor_id,
            nama_sarana,
            keterangan_kerusakan,
            foto_kerusakan_url,
            status,
            created_at,
            updated_at,
            lokasi:lokasi_id (nama_ruangan)
          ''')
          .eq('pelapor_id', pelaporId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('fetchLaporanByPelapor error: $e');
      return [];
    }
  }
}
