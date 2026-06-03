import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/constants/app_constants.dart';
import '../core/supabase/supabase_service.dart';
import '../core/utils/status_mapper.dart';
import '../data/models/laporan_lokal.dart';
import '../data/datasources/local/laporan_local_datasource.dart';
import '../data/datasources/remote/lokasi_remote_datasource.dart';
import '../data/datasources/remote/storage_remote_datasource.dart';

/// Orchestrator sinkronisasi laporan dari penyimpanan lokal (Hive) ke Supabase.
///
/// [SyncService] memiliki satu tanggung jawab: mengkoordinasikan alur sync
/// untuk setiap laporan yang belum tersinkronkan.
///
/// Detail operasi didelegasikan ke:
/// - [StorageRemoteDatasource] → upload foto ke Supabase Storage
/// - [LokasiRemoteDatasource]  → lookup lokasi_id dari nama ruangan
/// - [StatusMapper]             → konversi status lokal ke enum Supabase
/// - [LaporanLocalDatasource]  → baca/tulis data lokal (Hive)
class SyncService {
  final LaporanLocalDatasource _laporanLocal;
  final StorageRemoteDatasource _storage;
  final LokasiRemoteDatasource _lokasi;
  final _uuid = const Uuid();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    LaporanLocalDatasource? laporanLocal,
    StorageRemoteDatasource? storage,
    LokasiRemoteDatasource? lokasi,
  })  : _laporanLocal = laporanLocal ?? LaporanLocalDatasource(),
        _storage = storage ?? StorageRemoteDatasource(),
        _lokasi = lokasi ?? LokasiRemoteDatasource();

  // ── AUTO-SYNC: Start listening to connectivity changes ────────────────────
  void startAutoSync() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        // Jika ada koneksi (wifi atau mobile data) dan tidak sedang syncing
        if (!_isSyncing &&
            (results.contains(ConnectivityResult.wifi) ||
                results.contains(ConnectivityResult.mobile))) {
          debugPrint('SyncService: Koneksi terdeteksi, memulai auto-sync...');
          syncUnsyncedData();
        }
      },
    );
    debugPrint('SyncService: Auto-sync listener started');
  }

  // ── AUTO-SYNC: Stop listening ─────────────────────────────────────────────
  void stopAutoSync() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    debugPrint('SyncService: Auto-sync listener stopped');
  }

  // ── FUNGSI UTAMA: Pemicu Sinkronisasi ─────────────────────────────────────
  Future<void> syncUnsyncedData() async {
    if (_isSyncing) {
      debugPrint('SyncService: sync sudah berjalan, skip.');
      return;
    }

    _isSyncing = true;

    try {
      final authUser = SupabaseService.auth.currentUser;
      if (authUser == null) {
        debugPrint('SyncService: dibatalkan — user belum login.');
        return;
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        debugPrint('SyncService: tidak ada internet, sync ditunda.');
        return;
      }

      final unsyncedLaporan = _laporanLocal.getUnsyncedLaporan();
      if (unsyncedLaporan.isEmpty) {
        debugPrint('SyncService: tidak ada laporan yang perlu di-sync.');
        return;
      }

      debugPrint('SyncService: memulai sync ${unsyncedLaporan.length} laporan...');

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

        // Step B2: Buat entry tracking awal untuk laporan baru
        await insertInitialTracking(
          formulirId: laporan.formulirId,
          aktorId: authUser.id,
          pesanNarasi: 'Laporan sudah dibuat',
          status: _mapStatusForSupabase(laporan.status),
        );

      // Step C: Tandai sebagai synced di Hive
      if (cloudImageUrl != null && cloudImageUrl.isNotEmpty) {
        await _laporanLocal.markAsSynced(laporan.formulirId, cloudImageUrl);
      } else {
        await _laporanLocal.markSynced(laporan.formulirId);
      }

      // Step D: Insert tracking awal (non-critical — gagal tidak rollback laporan)
      await insertInitialTracking(
        formulirId: laporan.formulirId,
        aktorId: aktorId,
      );

      debugPrint('SyncService: laporan ${laporan.formulirId} berhasil di-sync.');
    } catch (e) {
      debugPrint('SyncService: gagal sync laporan ${laporan.formulirId}: $e');
      rethrow; // Re-throw untuk handling di level atas
    }
  }

  // ── UPSERT FORMULIR LAPORAN ───────────────────────────────────────────────
  Future<void> upsertLaporan(LaporanLokal laporan, String? imageUrl) async {
    final pelaporId = laporan.pelaporId.isNotEmpty
        ? laporan.pelaporId
        : SupabaseService.auth.currentUser?.id ?? '';

    // Resolve nama ruangan → UUID via tabel lokasi
    final lokasiId = await _lokasi.lookupLokasiId(laporan.lokasiPerbaikan);

    // Mapping status lokal → enum Supabase
    final statusCloud = StatusMapper.toSupabaseStatus(laporan.status);

    await SupabaseService.db.from('formulir_laporan').upsert({
      'formulir_id': laporan.formulirId,
      'pelapor_id': pelaporId,
      'nama_sarana': laporan.namaSarana,
      'keterangan_kerusakan': laporan.keteranganKerusakan,
      'lokasi_id': lokasiId,
      'nomor_inventaris': laporan.nomorInventaris,
      'foto_kerusakan_url': imageUrl ?? laporan.fotoKerusakanUrl,
      'status': statusCloud,
      'created_at': laporan.createdAt.toIso8601String(),
      'updated_at': laporan.updatedAt.toIso8601String(),
    });
  }

  // ── INSERT TRACKING AWAL ──────────────────────────────────────────────────
  /// Insert tracking pertama saat laporan berhasil sync ke Supabase.
  Future<void> insertInitialTracking({
    required String formulirId,
    required String aktorId,
  }) async {
    try {
      await SupabaseService.db.from('tracking').insert({
        'tracking_id': _uuid.v4(),
        'formulir_id': formulirId,
        'aktor_id': aktorId,
        'jenis_event': JenisEvent.laporanDibuat,
        'pesan_narasi': 'Laporan berhasil dikirim.',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint(
        'SyncService: tracking awal gagal untuk $formulirId '
        '(non-critical): $e',
      );
    }
  }

  Future<bool> laporanExistsOnCloud(String formulirId) async {
    try {
      final resp = await supabase
          .from('formulir_laporan')
          .select('formulir_id')
          .eq('formulir_id', formulirId)
          .maybeSingle();

      return resp != null;
    } catch (e) {
      debugPrint('Gagal memeriksa keberadaan laporan di cloud: $e');
      return false;
    }
  }

  Future<void> deleteLaporanFromSupabase(String formulirId) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw Exception('Supabase auth belum tersedia. Hapus cloud gagal.');
    }

    await supabase
        .from('formulir_laporan')
        .delete()
        .eq('formulir_id', formulirId);

    debugPrint('Laporan $formulirId dihapus dari Supabase.');
  }
}
