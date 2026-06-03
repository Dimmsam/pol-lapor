import 'package:flutter/foundation.dart';

import '../../../core/supabase/supabase_service.dart';

class LokasiRemoteDatasource {
  final _db = SupabaseService.db;

  Future<String?> lookupLokasiId(String namaRuangan) async {
    final normalized = _normalizeNama(namaRuangan);
    if (normalized.isEmpty) return null;

    try {
      final resp = await _db
          .from('lokasi')
          .select('lokasi_id')
          .eq('nama_ruangan', normalized)
          .eq('is_active', true)
          .maybeSingle();

      if (resp == null) {
        debugPrint(
          'LokasiRemote: "$normalized" tidak ditemukan di tabel lokasi. '
          'Mengirim lokasi_id = NULL.',
        );
        return null;
      }

      return resp['lokasi_id'] as String?;
    } catch (e) {
      debugPrint('LokasiRemote: gagal lookup lokasi_id untuk "$normalized": $e');
      return null;
    }
  }

  /// Normalisasi nama ruangan
  String _normalizeNama(String namaRuangan) {
    final trimmed = namaRuangan.trim();
    if (trimmed.isEmpty) return '';

    const aliasMap = <String, String>{
      'D101': 'D101 - Kelas',
      'D102': 'D102 - Lab. MT',
      'D105': 'D105 - Kelas',
      'D106': 'D106 - Lab. SDB',
      'D107': 'D107 - Lab. RPL',
      'D108': 'D108 - Kelas',
      'D111': 'D111 - Kelas',
      'D112': 'D112 - Kelas',
      'D115': 'D115 - Lab. PjBL-1',
      'D116': 'D116 - Lab. PjBL-2',
      'D217': 'D217 - Kelas',
      'D219': 'D219 - Kelas',
      'D223': 'D223 - Kelas',
      'D224': 'D224 - Kelas',
    };

    return aliasMap[trimmed.toUpperCase()] ?? trimmed;
  }
}
