import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/models/laporan_lokal.dart';
import 'hive_service.dart';

class SyncService {
  final HiveService _hiveService = HiveService();
  final supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // ── 1. FUNGSI UTAMA: Pemicu Sinkronisasi ─────────────────────────────────
  Future<void> syncUnsyncedData() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      debugPrint('Sync dibatalkan: user belum login di Supabase Auth.');
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('Tidak ada internet. Sync ditunda.');
      return;
    }

    final semuaLaporan = await _hiveService.getAllLaporan();
    final unsyncedLaporan = semuaLaporan.where((lap) => !lap.isSynced).toList();

    if (unsyncedLaporan.isEmpty) return;

    for (var laporan in unsyncedLaporan) {
      try {
        // Step A: Upload foto fisik ke Supabase Storage (jika ada)
        String? cloudImageUrl;
        if (laporan.fotoLokalPath != null &&
            laporan.fotoLokalPath!.isNotEmpty) {
          cloudImageUrl = await _uploadFotoToSupabase(
            laporan.fotoLokalPath!,
            laporan.formulirId,
          );
        }

        // Step B: Simpan data ke tabel formulir_laporan
        await _upsertDataToSupabase(laporan, cloudImageUrl);

        // Step B2: Tandai sebagai synced di Hive begitu data laporan utama
        // berhasil masuk, supaya badge lokal tidak tertahan oleh tracking.
        await _hiveService.markSynced(laporan.formulirId);

        // Step B3: Tracking bersifat pelengkap; gagal di sini tidak boleh
        // mengembalikan status laporan utama menjadi belum tersinkron.
        try {
          await _insertInitialTracking(
            formulirId: laporan.formulirId,
            aktorId: authUser.id,
            pesanNarasi: 'Laporan sudah dibuat',
          );
        } catch (e) {
          debugPrint(
            'Tracking awal gagal untuk laporan ${laporan.formulirId}: $e',
          );
        }

        // Step C: Log sukses sinkron laporan utama
        debugPrint('Laporan ${laporan.formulirId} berhasil di-sync.');
      } on StorageException catch (e) {
        debugPrint(
          'Gagal upload storage laporan ${laporan.formulirId}: ${e.message} '
          '(status: ${e.statusCode})',
        );
      } catch (e) {
        debugPrint('Gagal sync laporan ${laporan.formulirId}: $e');
      }
    }
  }

  // ── 2. Upload Foto ke Supabase Storage ───────────────────────────────────
  Future<String?> _uploadFotoToSupabase(
    String filePath,
    String formulirId,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final fileExt = filePath.split('.').last;
    final fileName = 'formulir_$formulirId.$fileExt';
    final pathTujuan = 'foto_kerusakan/$fileName';

    await supabase.storage
        .from('bukti_laporan')
        .upload(pathTujuan, file, fileOptions: const FileOptions(upsert: true));

    return supabase.storage.from('bukti_laporan').getPublicUrl(pathTujuan);
  }

  // ── 3. Upsert Data ke formulir_laporan ───────────────────────────────────
  Future<void> _upsertDataToSupabase(
    LaporanLokal laporan,
    String? imageUrl,
  ) async {
    String pelaporId = laporan.pelaporId;
    if (pelaporId.isEmpty) {
      pelaporId = await _getMyUserId();
    }

    // Lookup lokasi_id dari tabel lokasi berdasarkan nama ruangan
    // lokasiPerbaikan di Hive menyimpan string nama ruangan (contoh: "D108 - Kelas")
    final lokasiId = await _lookupLokasiId(laporan.lokasiPerbaikan);

    final statusCloud = _mapStatusForSupabase(laporan.status);

    await supabase.from('formulir_laporan').insert({
      'formulir_id': laporan.formulirId,
      'pelapor_id': pelaporId,
      'nama_sarana': laporan.namaSarana,
      'keterangan_kerusakan': laporan.keteranganKerusakan,
      'lokasi_id': lokasiId, // ← UUID FK, bukan string lagi
      'nomor_inventaris': laporan.nomorInventaris,
      'foto_kerusakan_url': imageUrl ?? laporan.fotoKerusakanUrl,
      'status': statusCloud,
      'is_synced': true,
      'created_at': laporan.createdAt.toIso8601String(),
      'updated_at': laporan.updatedAt.toIso8601String(),
      // kolom yang dihapus dari schema baru:
      // tanda_tangan_pelapor          → tidak ada
      // tanggal_tanda_tangan_pelapor  → tidak ada
      // lokasi_perbaikan              → tidak ada (diganti lokasi_id)
    });
  }

  Future<void> _insertInitialTracking({
    required String formulirId,
    required String aktorId,
    required String pesanNarasi,
  }) async {
    await supabase.from('tracking').insert({
      'tracking_id': _uuid.v4(),
      'formulir_id': formulirId,
      'aktor_id': aktorId,
      'pesan_narasi': pesanNarasi,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ── 4. Lookup lokasi_id dari tabel lokasi ────────────────────────────────
  // Mencari UUID lokasi berdasarkan nama_ruangan yang tersimpan di Hive.
  // Jika tidak ditemukan, kirim null (lokasi_id nullable di schema).
  Future<String?> _lookupLokasiId(String namaRuangan) async {
    final normalizedNama = _normalizeLokasiName(namaRuangan);
    if (normalizedNama.isEmpty) return null;

    try {
      final resp = await supabase
          .from('lokasi')
          .select('lokasi_id')
          .eq('nama_ruangan', normalizedNama)
          .eq('is_active', true)
          .maybeSingle();

      if (resp == null) {
        debugPrint(
          'Lokasi "$normalizedNama" tidak ditemukan di tabel lokasi. '
          'lokasi_id akan dikirim sebagai NULL.',
        );
        return null;
      }

      return resp['lokasi_id'] as String?;
    } catch (e) {
      debugPrint('Gagal lookup lokasi_id untuk "$normalizedNama": $e');
      return null;
    }
  }

  String _normalizeLokasiName(String namaRuangan) {
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

  // ── 5. Map status lokal → enum status_formulir di Supabase ───────────────
  String _mapStatusForSupabase(String statusLokal) {
    // Nilai valid di enum status_formulir (schema baru)
    const validNewEnum = <String>{
      'menunggu',
      'ditugaskan',
      'sedang_dikerjakan',
      'selesai',
      'diteruskan_ke_pusat',
    };

    if (validNewEnum.contains(statusLokal)) return statusLokal;

    // Mapping dari status lama (Hive / schema lama) ke enum baru
    switch (statusLokal) {
      case 'menunggu_klasifikasi':
      case 'draft':
        return 'menunggu';
      case 'klasifikasi_selesai':
      case 'pengajuan_dibuat':
      case 'terkirim':
      case 'dicatat_admin':
      case 'diketahui_ka_upt':
      case 'surat_pengajuan_dibuat':
      case 'surat_kerja_diterbitkan':
        return 'ditugaskan';
      case 'sedang_ditangani':
      case 'selesai_ditangani':
        return 'sedang_dikerjakan';
      case 'berita_acara_dibuat':
      case 'selesai':
        return 'selesai';
      default:
        debugPrint(
          'Status "$statusLokal" tidak dikenal, fallback ke "menunggu".',
        );
        return 'menunggu';
    }
  }

  // ── 6. Helper: ambil user_id dari tabel pengguna ─────────────────────────
  Future<String> _getMyUserId() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) throw Exception('User tidak terautentikasi');

    final resp = await supabase
        .from('pengguna')
        .select('user_id')
        .eq('user_id', authUser.id)
        .single();

    if (resp['user_id'] == null) {
      throw Exception('Profil pengguna tidak ditemukan di tabel pengguna');
    }

    return resp['user_id'] as String;
  }
}
