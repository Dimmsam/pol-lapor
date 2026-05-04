import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../../data/models/tugas_teknisi_lokal.dart';

class TeknisiSupabaseService {
  final supabase = Supabase.instance.client;

  // Buka box Hive khusus teknisi
  Future<Box<TugasTeknisiLokal>> get _box async => await Hive.openBox<TugasTeknisiLokal>('tugasTeknisiBox');

  // ── 1. READ: TARIK DATA TUGAS DARI CLOUD (BERDASARKAN JURUSAN) ────────────
  Future<void> fetchTugasDariCloud(String unitJurusanTeknisi) async {
    try {
      final response = await supabase
          .from('penanganan')
          .select('''
            penanganan_id,
            status,
            formulir_id,
            formulir_laporan!inner (
              nama_sarana,
              lokasi_perbaikan,
              keterangan_kerusakan,
              unit_jurusan
            )
          ''')
          .eq('status', 'sedang_dikerjakan')
          .eq('formulir_laporan.unit_jurusan', unitJurusanTeknisi);

      final box = await _box;

      for (var row in response) {
        final formulir = row['formulir_laporan'];
        
        final tugasBaru = TugasTeknisiLokal(
          penangananId: row['penanganan_id'].toString(),
          formulirId: row['formulir_id'].toString(),
          namaSarana: formulir['nama_sarana'],
          lokasi: formulir['lokasi_perbaikan'],
          keteranganKerusakan: formulir['keterangan_kerusakan'],
          status: row['status'],
          isSynced: true, 
          updatedAt: DateTime.now(),
        );

        await box.put(tugasBaru.penangananId, tugasBaru);
      }
    } catch (e) {
      debugPrint('Error fetch tugas teknisi: $e');
    }
  }

  // ── 2. WRITE: SYNC DATA (ESKALASI & SELESAI) KE CLOUD ─────────────────────
  Future<void> syncAksiTeknisiKeCloud() async {
    final box = await _box;
    final unsyncedTugas = box.values.where((t) => !t.isSynced).toList();

    if (unsyncedTugas.isEmpty) return;

    for (var tugas in unsyncedTugas) {
      try {
        String? cloudImageUrl;

        // Jika statusnya SELESAI, upload foto hasil kerja dulu
        if (tugas.status == 'selesai' && tugas.fotoHasilLokalPath != null) {
          final file = File(tugas.fotoHasilLokalPath!);
          if (await file.exists()) {
            final fileName = 'hasil_${tugas.penangananId}.jpg';
            final pathTujuan = 'foto_penanganan/$fileName';

            await supabase.storage
                .from('bukti_laporan') 
                .upload(pathTujuan, file, fileOptions: const FileOptions(upsert: true));

            cloudImageUrl = supabase.storage.from('bukti_laporan').getPublicUrl(pathTujuan);
          }
        }

        // UPDATE TABEL DI SUPABASE
        await supabase.from('penanganan').update({
          'status': tugas.status,
          if (tugas.catatanTeknisi != null) 'catatan_teknisi': tugas.catatanTeknisi,
          if (cloudImageUrl != null) 'foto_hasil_url': cloudImageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('penanganan_id', tugas.penangananId);

        // Jika berhasil tembus ke Cloud, tandai sync selesai
        tugas.isSynced = true;
        await tugas.save();
        
      } catch (e) {
        debugPrint('Gagal sync penanganan ${tugas.penangananId}: $e');
      }
    }
  }
}