import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local/laporan_local_datasource.dart';
import '../../data/datasources/remote/laporan_remote_datasource.dart';
import '../../data/models/laporan_lokal.dart';
import '../../services/sync_service.dart';

class FormLaporanProvider extends ChangeNotifier {
  final LaporanLocalDatasource _local = LaporanLocalDatasource();
  final LaporanRemoteDatasource _remote = LaporanRemoteDatasource();
  final SyncService _sync = SyncService();
  final _uuid = const Uuid();

  int _jumlahLaporanSerupa = 0;
  bool _isCheckingSerupa = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  int get jumlahLaporanSerupa => _jumlahLaporanSerupa;
  bool get isCheckingSerupa => _isCheckingSerupa;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> checkLaporanSerupa(String lokasi) async {
    _isCheckingSerupa = true;
    _jumlahLaporanSerupa = 0;
    notifyListeners();

    var count = _local.getLaporanAktifByLokasi(lokasi).length;

    final remoteCount = await _remote.countLaporanAktifByLokasi(lokasi);
    if (remoteCount != null && remoteCount > count) {
      count = remoteCount;
    }

    _jumlahLaporanSerupa = count;
    _isCheckingSerupa = false;
    notifyListeners();
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

  Future<void> updateLaporan(LaporanLokal existing, {
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
      final updated = existing.copyWith(
        namaSarana: namaSarana,
        keteranganKerusakan: keteranganKerusakan,
        lokasiPerbaikan: lokasiPerbaikan,
        nomorInventaris: nomorInventaris,
        fotoLokalPath: fotoLokalPath,
        isSynced: false,
        updatedAt: DateTime.now(),
      );

      await _local.updateLaporan(updated);
      syncInBackground();
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
