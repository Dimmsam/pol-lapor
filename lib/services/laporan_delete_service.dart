import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LaporanDeleteService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<void> deleteLaporanRemotely({
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
}
