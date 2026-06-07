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

    // Hapus baris terkait di tracking & penanganan agar tidak terjadi orphaned records
    await _db.from('tracking').delete().eq('formulir_id', formulirId);
    await _db.from('penanganan').delete().eq('formulir_id', formulirId);

    final response = await _db
        .from('formulir_laporan')
        .delete()
        .eq('formulir_id', formulirId)
        .eq('pelapor_id', pelaporId)
        .select();

    if (response.isEmpty) {
      debugPrint('Laporan $formulirId tidak ditemukan atau RLS block delete. Melanjutkan hapus lokal.');
    }
  }

  /// Update laporan yang sudah tersync langsung di Supabase
  Future<void> updateLaporanRemote({
    required String formulirId,
    required String namaSarana,
    required String keteranganKerusakan,
    String? namaRuangan,
    String? nomorInventaris,
    String? fotoUrl,
  }) async {
    final updateMap = <String, dynamic>{
      'nama_sarana': namaSarana,
      'keterangan_kerusakan': keteranganKerusakan,
      'nomor_inventaris': nomorInventaris,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (namaRuangan != null) {
      try {
        final lokasiId = await _resolveLokasiId(namaRuangan);
        if (lokasiId != null) updateMap['lokasi_id'] = lokasiId;
      } catch (e) {
        debugPrint('updateLaporanRemote: gagal resolve lokasi ($namaRuangan): $e');
      }
    }

    if (fotoUrl != null) updateMap['foto_kerusakan_url'] = fotoUrl;

    final response = await _db
        .from('formulir_laporan')
        .update(updateMap)
        .eq('formulir_id', formulirId)
        .select();
        
    if (response.isEmpty) {
      debugPrint('WARNING: updateLaporanRemote gagal! RLS policy mungkin memblokir UPDATE.');
      throw Exception('Gagal mengupdate laporan di server. Pastikan RLS policy UPDATE sudah benar.');
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
            nomor_inventaris,
            foto_kerusakan_url,
            status,
            prioritas,
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

  /// Fetch semua laporan (publik)
  Future<List<Map<String, dynamic>>> fetchAllLaporan() async {
    try {
      final response = await _db
          .from('formulir_laporan')
          .select('''
            formulir_id,
            pelapor_id,
            nama_sarana,
            keterangan_kerusakan,
            nomor_inventaris,
            foto_kerusakan_url,
            status,
            prioritas,
            created_at,
            updated_at,
            lokasi:lokasi_id (nama_ruangan)
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('fetchAllLaporan error: $e');
      return [];
    }
  }
}
