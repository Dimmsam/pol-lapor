// lib/data/datasources/remote/teknisi_upt_remote_datasource.dart
// Nama Pembuat: Dimas Rizal Ramadhani
// Semua operasi Supabase untuk fitur Teknisi UPT-PP
// Disesuaikan dengan skema DB: status_penanganan_enum (mulai_dikerjakan,
// sedang_dikerjakan, selesai), foto_progres_url ARRAY, tanpa persentase_progress.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../models/surat_kerja.dart';
import '../../models/penanganan.dart';

class TeknisiUptRemoteDatasource {
  SupabaseClient get _db => SupabaseService.db;

  // ─────────────────────────────────────────────────────────────────────────
  // SURAT KERJA QUERIES
  // ─────────────────────────────────────────────────────────────────────────

  /// Ambil semua surat kerja milik teknisi yang sedang login.
  /// Join ke formulir_laporan dan penanganan untuk data lengkap.
  ///
  /// [filterStatus] — null = semua, atau salah satu dari:
  ///   'mulai_dikerjakan' | 'sedang_dikerjakan' | 'selesai'
  Future<List<SuratKerja>> getSuratKerjaList({
    required String teknisiId,
    String? filterStatus,
  }) async {
    try {
      final response = await _db
          .from('surat_kerja')
          .select('''
            surat_kerja_id,
            formulir_id,
            surat_pengajuan_id,
            nomor_surat_kerja,
            tanggal_terbit,
            jenis_pelaksana,
            admin_upt_id,
            teknisi_id,
            nama_vendor,
            kontak_vendor,
            instruksi_kerja,
            tanggal_target_selesai,
            created_at,
            formulir_laporan (
              nama_sarana,
              keterangan_kerusakan,
              lokasi_perbaikan,
              nomor_inventaris,
              foto_kerusakan_url,
              status
            ),
            penanganan (
              penanganan_id,
              status_penanganan,
              catatan_progres,
              foto_progres_url,
              tanggal_mulai,
              tanggal_selesai
            )
          ''')
          .eq('teknisi_id', teknisiId)
          .eq('jenis_pelaksana', 'internal')
          .order('created_at', ascending: false);

      List<SuratKerja> list = (response as List)
          .map((json) => SuratKerja.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter status dilakukan di client-side (status ada di nested tabel)
      if (filterStatus != null && filterStatus != 'semua') {
        list = list.where((sk) {
          final status =
              sk.penanganan?.statusPenanganan ?? StatusPenanganan.mulaiDikerjakan;
          return status == filterStatus;
        }).toList();
      }

      return list;
    } catch (e) {
      debugPrint('getSuratKerjaList error: $e');
      rethrow;
    }
  }

  /// Ambil detail satu surat kerja berdasarkan ID.
  Future<SuratKerja> getSuratKerjaDetail(String suratKerjaId) async {
    try {
      final response = await _db
          .from('surat_kerja')
          .select('''
            surat_kerja_id,
            formulir_id,
            surat_pengajuan_id,
            nomor_surat_kerja,
            tanggal_terbit,
            jenis_pelaksana,
            admin_upt_id,
            teknisi_id,
            nama_vendor,
            kontak_vendor,
            instruksi_kerja,
            tanggal_target_selesai,
            created_at,
            formulir_laporan (
              nama_sarana,
              keterangan_kerusakan,
              lokasi_perbaikan,
              nomor_inventaris,
              foto_kerusakan_url,
              status
            ),
            penanganan (
              penanganan_id,
              status_penanganan,
              catatan_progres,
              deskripsi_hasil,
              foto_progres_url,
              foto_hasil_url,
              tanggal_mulai,
              tanggal_selesai,
              updated_at
            )
          ''')
          .eq('surat_kerja_id', suratKerjaId)
          .single();

      return SuratKerja.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('getSuratKerjaDetail error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATISTIK DASHBOARD
  // ─────────────────────────────────────────────────────────────────────────

  /// Ambil ringkasan statistik tugas untuk dashboard teknisi.
  /// Kategori: belum_dimulai (null), aktif (mulai/sedang), selesai.
  Future<Map<String, int>> getDashboardStats(String teknisiId) async {
    try {
      final response = await _db
          .from('surat_kerja')
          .select('''
            surat_kerja_id,
            penanganan ( status_penanganan )
          ''')
          .eq('teknisi_id', teknisiId)
          .eq('jenis_pelaksana', 'internal');

      int belumDimulai = 0;
      int aktif = 0;
      int selesai = 0;

      for (final row in (response as List)) {
        final penangananList = row['penanganan'] as List?;
        final status = penangananList != null && penangananList.isNotEmpty
            ? penangananList.first['status_penanganan'] as String?
            : null;

        if (status == null) {
          belumDimulai++;
        } else if (status == StatusPenanganan.selesai) {
          selesai++;
        } else {
          // mulai_dikerjakan | sedang_dikerjakan
          aktif++;
        }
      }

      return {
        'belum_dimulai': belumDimulai,
        'aktif': aktif,
        'selesai': selesai,
        'total': response.length,
      };
    } catch (e) {
      debugPrint('getDashboardStats error: $e');
      return {'belum_dimulai': 0, 'aktif': 0, 'selesai': 0, 'total': 0};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PENANGANAN — CREATE & UPDATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Mulai mengerjakan tugas: buat record penanganan baru dengan status
  /// 'mulai_dikerjakan' dan catat tanggal_mulai.
  ///
  /// Otomatis update status formulir_laporan ke 'sedang_ditangani'.
  Future<Penanganan> mulaiPengerjaan({
    required String suratKerjaId,
    required String formulirId,
    required String teknisiId,
    required String penangananId, // UUID baru dari caller
  }) async {
    try {
      final now = DateTime.now().toIso8601String();

      // 1. Insert record penanganan baru
      final response = await _db
          .from('penanganan')
          .insert({
            'penanganan_id': penangananId,
            'surat_kerja_id': suratKerjaId,
            'formulir_id': formulirId,
            'teknisi_id': teknisiId,
            'status_penanganan': StatusPenanganan.mulaiDikerjakan,
            'tanggal_mulai': now,
            'foto_progres_url': <String>[], // ARRAY kosong
            'updated_at': now,
          })
          .select()
          .single();

      // 2. Update status formulir_laporan
      await _db
          .from('formulir_laporan')
          .update({'status': 'sedang_ditangani', 'updated_at': now})
          .eq('formulir_id', formulirId);

      // 3. Insert tracking log
      await _insertTrackingLog(
        formulirId: formulirId,
        statusSebelumnya: 'menunggu_konfirmasi',
        statusBaru: 'sedang_ditangani',
        keterangan: 'Teknisi memulai pengerjaan.',
      );

      return Penanganan.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('mulaiPengerjaan error: $e');
      rethrow;
    }
  }

  /// Update progress pekerjaan: simpan catatan, tambah foto progress ke ARRAY,
  /// dan ubah status ke 'sedang_dikerjakan'.
  ///
  /// [fotoLokalPath] — path file lokal; null jika tidak ada foto baru.
  Future<Penanganan> updateProgress({
    required String penangananId,
    required String formulirId,
    required String statusBaru, // 'mulai_dikerjakan' | 'sedang_dikerjakan'
    String? catatanProgres,
    String? fotoLokalPath,
    List<String> existingFotoUrls = const [],
  }) async {
    try {
      // Upload foto progress jika ada, kemudian append ke ARRAY existing
      final List<String> fotoUrls = List<String>.from(existingFotoUrls);
      if (fotoLokalPath != null && fotoLokalPath.isNotEmpty) {
        final fotoUrl = await _uploadFoto(
          filePath: fotoLokalPath,
          bucket: 'bukti_laporan',
          folder: 'foto_progres',
          fileName:
              'progres_${penangananId}_${DateTime.now().millisecondsSinceEpoch}',
        );
        fotoUrls.add(fotoUrl);
      }

      final now = DateTime.now().toIso8601String();

      final updatePayload = <String, dynamic>{
        'status_penanganan': statusBaru,
        'foto_progres_url': fotoUrls, // ARRAY lengkap
        'updated_at': now,
      };
      if (catatanProgres != null) {
        updatePayload['catatan_progres'] = catatanProgres;
      }

      final response = await _db
          .from('penanganan')
          .update(updatePayload)
          .eq('penanganan_id', penangananId)
          .select()
          .single();

      return Penanganan.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('updateProgress error: $e');
      rethrow;
    }
  }

  /// Selesaikan pekerjaan: simpan foto hasil, deskripsi hasil, dan ubah
  /// status penanganan ke 'selesai'. Juga update formulir_laporan.
  ///
  /// [fotoHasilPath] — WAJIB (min 1 foto after sesuai UC-10)
  Future<Penanganan> selesaikanPekerjaan({
    required String penangananId,
    required String formulirId,
    required String fotoHasilPath,
    required String deskripsiHasil,
  }) async {
    try {
      // Upload foto hasil (wajib)
      final fotoUrl = await _uploadFoto(
        filePath: fotoHasilPath,
        bucket: 'bukti_laporan',
        folder: 'foto_hasil',
        fileName: 'hasil_$penangananId',
      );

      final now = DateTime.now().toIso8601String();

      // 1. Update penanganan ke 'selesai'
      final response = await _db
          .from('penanganan')
          .update({
            'status_penanganan': StatusPenanganan.selesai,
            'deskripsi_hasil': deskripsiHasil,
            'foto_hasil_url': fotoUrl,
            'tanggal_selesai': now,
            'updated_at': now,
          })
          .eq('penanganan_id', penangananId)
          .select()
          .single();

      // 2. Update formulir_laporan ke status 'selesai_ditangani'
      //    Admin UPT-PP yang akan membuat berita acara dan menutup ke 'selesai'
      await _db
          .from('formulir_laporan')
          .update({
            'status': 'selesai_ditangani',
            'updated_at': now,
          })
          .eq('formulir_id', formulirId);

      // 3. Insert tracking log
      await _insertTrackingLog(
        formulirId: formulirId,
        statusSebelumnya: 'sedang_ditangani',
        statusBaru: 'selesai_ditangani',
        keterangan: 'Teknisi UPT-PP melaporkan pekerjaan selesai.',
      );

      return Penanganan.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('selesaikanPekerjaan error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RIWAYAT PEKERJAAN
  // ─────────────────────────────────────────────────────────────────────────

  /// Ambil riwayat pekerjaan yang sudah selesai milik teknisi.
  Future<List<SuratKerja>> getRiwayatPekerjaan(String teknisiId) async {
    try {
      final response = await _db
          .from('surat_kerja')
          .select('''
            surat_kerja_id,
            formulir_id,
            nomor_surat_kerja,
            tanggal_terbit,
            instruksi_kerja,
            tanggal_target_selesai,
            created_at,
            formulir_laporan (
              nama_sarana,
              lokasi_perbaikan,
              keterangan_kerusakan,
              status
            ),
            penanganan (
              penanganan_id,
              status_penanganan,
              deskripsi_hasil,
              foto_hasil_url,
              foto_progres_url,
              tanggal_selesai
            )
          ''')
          .eq('teknisi_id', teknisiId)
          .eq('jenis_pelaksana', 'internal')
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => SuratKerja.fromJson(json as Map<String, dynamic>))
          .where((sk) =>
              sk.penanganan?.statusPenanganan == StatusPenanganan.selesai)
          .toList();

      return list;
    } catch (e) {
      debugPrint('getRiwayatPekerjaan error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER PRIVAT
  // ─────────────────────────────────────────────────────────────────────────

  /// Upload file foto ke Supabase Storage, return public URL.
  Future<String> _uploadFoto({
    required String filePath,
    required String bucket,
    required String folder,
    required String fileName,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File foto tidak ditemukan: $filePath');
    }

    final ext = filePath.split('.').last.toLowerCase();
    final storagePath = '$folder/$fileName.$ext';

    await SupabaseService.storage
        .from(bucket)
        .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));

    return SupabaseService.storage.from(bucket).getPublicUrl(storagePath);
  }

  /// Insert log ke tabel tracking untuk audit trail.
  Future<void> _insertTrackingLog({
    required String formulirId,
    required String statusSebelumnya,
    required String statusBaru,
    required String keterangan,
  }) async {
    try {
      final user = SupabaseService.auth.currentUser;
      if (user == null) return;

      await _db.from('tracking').insert({
        'formulir_id': formulirId,
        'status_sebelumnya': statusSebelumnya,
        'status_baru': statusBaru,
        'keterangan': keterangan,
        'aktor_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Tracking log bukan critical path; gagal silently
      debugPrint('_insertTrackingLog error (non-critical): $e');
    }
  }
}