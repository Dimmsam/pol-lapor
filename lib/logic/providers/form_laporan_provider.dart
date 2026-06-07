import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local/laporan_local_datasource.dart';
import '../../data/datasources/remote/laporan_remote_datasource.dart';
import '../../data/datasources/remote/storage_remote_datasource.dart';
import '../../data/models/laporan_lokal.dart';
import '../../services/sync_service.dart';

class FormLaporanProvider extends ChangeNotifier {
  // ── Dependency injection (untuk production & testing) ─────────────────────
  // Sebelumnya dependency di-hardcode sehingga tidak bisa di-mock saat testing.
  // Sekarang dependency diinject lewat constructor agar bisa di-override dengan mock.
  final LaporanLocalDatasource _local;
  final LaporanRemoteDatasource _remote;
  final StorageRemoteDatasource _storage;
  final SyncService _sync;
  final _uuid = const Uuid();

  /// Constructor dengan optional injection.
  /// - Production: cukup `FormLaporanProvider()` → pakai instance default.
  /// - Testing:    `FormLaporanProvider(local: mockLocal, ...)` → pakai mock.
  FormLaporanProvider({
    LaporanLocalDatasource? local,
    LaporanRemoteDatasource? remote,
    StorageRemoteDatasource? storage,
    SyncService? sync,
  })  : _local = local ?? LaporanLocalDatasource(),
        _remote = remote ?? LaporanRemoteDatasource(),
        _storage = storage ?? StorageRemoteDatasource(),
        _sync = sync ?? SyncService();

  int _jumlahLaporanSerupa = 0;
  bool _isCheckingSerupa = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  Timer? _debounce;

  int get jumlahLaporanSerupa => _jumlahLaporanSerupa;
  bool get isCheckingSerupa => _isCheckingSerupa;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void checkLaporanSerupa(String lokasi) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _isCheckingSerupa = true;
      _jumlahLaporanSerupa = 0;
      notifyListeners();

      try {
        var count = _local.getLaporanAktifByLokasi(lokasi).length;
        final remoteCount = await _remote.countLaporanAktifByLokasi(lokasi);
        if (remoteCount != null && remoteCount > count) {
          count = remoteCount;
        }

        _jumlahLaporanSerupa = count;
      } catch (e) {
        debugPrint('Error checkLaporanSerupa: $e');
      } finally {
        _isCheckingSerupa = false;
        notifyListeners();
      }
    });
  }

  Future<bool> submitLaporan({
    LaporanLokal? laporanEdit,
    required String namaSarana,
    required String keteranganKerusakan,
    required String lokasiPerbaikan,
    required String? fotoLokalPath,
    String? pelaporId,
    String? nomorInventaris,
  }) async {
    try {
      if (laporanEdit != null) {
        await updateLaporan(
          laporanEdit,
          namaSarana: namaSarana,
          keteranganKerusakan: keteranganKerusakan,
          lokasiPerbaikan: lokasiPerbaikan,
          fotoLokalPath: fotoLokalPath,
          nomorInventaris: nomorInventaris,
        );
      } else {
        if (fotoLokalPath == null) throw Exception("Foto wajib ada");
        await createLaporan(
          namaSarana: namaSarana,
          keteranganKerusakan: keteranganKerusakan,
          lokasiPerbaikan: lokasiPerbaikan,
          fotoLokalPath: fotoLokalPath,
          pelaporId: pelaporId ?? '',
          nomorInventaris: nomorInventaris,
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<LaporanLokal> createLaporan({
    required String namaSarana,
    required String keteranganKerusakan,
    required String lokasiPerbaikan,
    required String fotoLokalPath,
    required String pelaporId,
    String? nomorInventaris,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final laporan = LaporanLokal(
        formulirId: _uuid.v4(),
        namaSarana: namaSarana,
        keteranganKerusakan: keteranganKerusakan,
        lokasiPerbaikan: lokasiPerbaikan,
        fotoLokalPath: fotoLokalPath,
        nomorInventaris: nomorInventaris,
        pelaporId: pelaporId,
        tandaTanganPelapor: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _local.saveLaporan(laporan);
      syncInBackground();
      return laporan;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan laporan lokal.';
      debugPrint('createLaporan error: $e');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateLaporan(
    LaporanLokal existing, {
    required String namaSarana,
    required String keteranganKerusakan,
    required String lokasiPerbaikan,
    required String? fotoLokalPath,
    String? nomorInventaris,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? newFotoUrl;

      // Jika laporan sudah tersync di Supabase, update langsung ke remote
      if (existing.isSynced) {
        // Upload foto baru dulu jika ada
        // BUG-03 FIX: Sebelumnya pakai `StorageRemoteDatasource()` langsung (tidak bisa di-mock).
        // Sekarang pakai _storage yang diinject lewat constructor.
        if (fotoLokalPath != null && fotoLokalPath.isNotEmpty) {
          try {
            newFotoUrl = await _storage.uploadFotoKerusakan(
              filePath: fotoLokalPath,
              formulirId: existing.formulirId,
            );
          } catch (e) {
            debugPrint('updateLaporan: gagal upload foto baru: $e');
          }
        }

        // Update langsung ke Supabase
        await _remote.updateLaporanRemote(
          formulirId: existing.formulirId,
          namaSarana: namaSarana,
          keteranganKerusakan: keteranganKerusakan,
          namaRuangan: lokasiPerbaikan,
          nomorInventaris: nomorInventaris,
          fotoUrl: newFotoUrl,
        );
      }

      // Update data lokal (Hive)
      final updated = existing.copyWith(
        namaSarana: namaSarana,
        keteranganKerusakan: keteranganKerusakan,
        lokasiPerbaikan: lokasiPerbaikan,
        nomorInventaris: nomorInventaris,
        clearNomorInventaris: nomorInventaris == null,
        fotoLokalPath: fotoLokalPath,
        fotoKerusakanUrl: newFotoUrl ?? existing.fotoKerusakanUrl,
        isSynced: existing.isSynced,
        updatedAt: DateTime.now(),
      );

      await _local.updateLaporan(updated);

      // Kalau belum tersync, baru trigger sync background
      if (!existing.isSynced) {
        syncInBackground();
      }
    } catch (e) {
      _errorMessage = 'Gagal memperbarui laporan.';
      debugPrint('updateLaporan error: $e');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void syncInBackground() {
    _sync.syncUnsyncedData().catchError((e) {
      debugPrint('syncInBackground error: $e');
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}