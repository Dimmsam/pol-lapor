import '../../../core/supabase/supabase_service.dart';
import '../../../core/utils/status_mapper.dart';
import '../../models/laporan_lokal.dart';
import '../../models/penanganan.dart';

class PenangananRemoteDatasource {
  final _db = SupabaseService.db;

  static const _formulirSelect = '''
            formulir_id,
            nama_sarana,
            keterangan_kerusakan,
            lokasi_id,
            nomor_inventaris,
            foto_kerusakan_url,
            status,
            pelapor_id,
            created_at,
            updated_at,
            penanganan!inner (
              teknisi_id
            ),
            lokasi:lokasi_id (nama_ruangan),
            pengguna:pelapor_id (nama_lengkap)
          ''';

  Future<List<Map<String, dynamic>>> fetchPenangananRows(
    String teknisiId,
  ) async {
    final response = await _db
        .from('penanganan')
        .select('''
            penanganan_id,
            formulir_id,
            teknisi_id,
            status_penanganan,
            catatan_progres,
            deskripsi_hasil,
            foto_progres_url,
            foto_hasil_url,
            tanggal_mulai,
            tanggal_selesai,
            updated_at
          ''')
        .eq('teknisi_id', teknisiId)
        .order('updated_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<Map<String, dynamic>?> fetchPenangananByFormulir(String formulirId) async {
    final response = await _db
        .from('penanganan')
        .select('''
            penanganan_id,
            formulir_id,
            teknisi_id,
            status_penanganan,
            catatan_progres,
            deskripsi_hasil,
            kategori_kerusakan,
            foto_progres_url,
            foto_hasil_url,
            tanggal_mulai,
            tanggal_selesai,
            updated_at
          ''')
        .eq('formulir_id', formulirId)
        .maybeSingle();

    return response != null ? Map<String, dynamic>.from(response as Map) : null;
  }

  Future<Map<String, int>> fetchStats(String teknisiId) async {
    final response = await _db
        .from('penanganan')
        .select('penanganan_id, status_penanganan')
        .eq('teknisi_id', teknisiId);

    int belumDimulai = 0;
    int aktif = 0;
    int selesai = 0;

    for (final row in (response as List)) {
      final status = row['status_penanganan'] as String?;
      if (status == null || status == StatusPenanganan.mulaiDikerjakan) {
        belumDimulai++;
      } else if (status == StatusPenanganan.selesai) {
        selesai++;
      } else {
        aktif++;
      }
    }

    return {
      'belum_dimulai': belumDimulai,
      'aktif': aktif,
      'selesai': selesai,
      'total': response.length,
    };
  }

  Future<List<LaporanLokal>> fetchDaftarTugas(String teknisiId) async {
    final response = await _db
        .from('formulir_laporan')
        .select(_formulirSelect)
        .eq('penanganan.teknisi_id', teknisiId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => LaporanLokal.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LaporanLokal>> fetchLaporanTerbaru(
    String teknisiId, {
    int limit = 5,
  }) async {
    final response = await _db
        .from('formulir_laporan')
        .select(_formulirSelect)
        .eq('penanganan.teknisi_id', teknisiId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => LaporanLokal.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertPenanganan(Map<String, dynamic> data) async {
    await _db.from('penanganan').insert(data);
  }

  Future<void> updatePenanganan(
    String penangananId,
    Map<String, dynamic> data,
  ) async {
    await _db.from('penanganan').update(data).eq('penanganan_id', penangananId);
  }

  Future<void> updateStatusFormulir(
    String formulirId,
    String status, {
    String? updatedAt,
  }) async {
    final statusCloud = StatusMapper.toSupabaseStatus(status);
    await _db.from('formulir_laporan').update({
      'status': statusCloud,
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    }).eq('formulir_id', formulirId);
  }
}
