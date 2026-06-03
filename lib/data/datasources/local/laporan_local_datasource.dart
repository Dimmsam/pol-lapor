import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/status_mapper.dart';
import '../../models/laporan_lokal.dart';

class LaporanLocalDatasource {
  Box<LaporanLokal> get _box =>
      Hive.box<LaporanLokal>(AppConstants.boxLaporan);

  Future<void> saveLaporan(LaporanLokal laporan) async {
    await _box.put(laporan.formulirId, laporan);
  }

  List<LaporanLokal> getAllLaporan() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<LaporanLokal> getUnsyncedLaporan() {
    return _box.values.where((l) => !l.isSynced).toList();
  }

  LaporanLokal? getLaporanById(String formulirId) {
    return _box.get(formulirId);
  }

  Future<void> updateLaporan(LaporanLokal laporan) async {
    await _box.put(laporan.formulirId, laporan);
  }

  Future<void> deleteLaporan(String formulirId) async {
    await _box.delete(formulirId);
  }

  Future<void> markSynced(String formulirId) async {
    final laporan = _box.get(formulirId);
    if (laporan == null) return;

    laporan.isSynced = true;
    laporan.updatedAt = DateTime.now();
    await laporan.save();
  }

  Future<void> markAsSynced(String formulirId, String fotoCloudUrl) async {
    final laporan = _box.get(formulirId);
    if (laporan == null) return;

    laporan.isSynced = true;
    laporan.fotoKerusakanUrl = fotoCloudUrl;
    laporan.updatedAt = DateTime.now();
    await laporan.save();
  }

  Future<void> updateStatus(String formulirId, String statusBaru) async {
    final laporan = _box.get(formulirId);
    if (laporan == null) return;

    laporan.status = statusBaru;
    laporan.updatedAt = DateTime.now();
    await laporan.save();
  }

  int countAll() => _box.length;

  int countUnsynced() => _box.values.where((l) => !l.isSynced).length;

  ValueListenable<Box<LaporanLokal>> listenable() => _box.listenable();

  List<LaporanLokal> getLaporanAktifByLokasi(String lokasi) {
    return _box.values.where((l) {
      final sameLokasi = l.lokasiPerbaikan.trim().toLowerCase() ==
          lokasi.trim().toLowerCase();
      final masihAktif = l.status != StatusLaporan.selesai;
      return sameLokasi && masihAktif;
    }).toList();
  }

  /// Sinkronkan laporan dari remote ke lokal (merge/update/delete deleted records).
  Future<void> syncFromRemote(List<Map<String, dynamic>> remoteLaporan, String pelaporId, {bool isFullSync = false}) async {
    final remoteIds = <String>{};
    for (final json in remoteLaporan) {
      try {
        final formulirId = json['formulir_id'] as String;
        final existing = _box.get(formulirId);

        // Gunakan factory yang sudah ada agar semua field (termasuk nomor_inventaris) ter-mapping dengan benar
        final laporan = LaporanLokal.fromSupabaseJson(json);

        // Hanya update jika belum ada atau versi remote lebih baru
        if (existing == null ||
            laporan.updatedAt.isAfter(existing.updatedAt)) {
          await _box.put(formulirId, laporan);
        }
        
        remoteIds.add(formulirId);
      } catch (e) {
        debugPrint('syncFromRemote error untuk item: $e');
      }
    }

    // 2. Hapus data lokal yang sudah tidak ada di server (yang dihapus lewat admin/dashboard web)
    final allLokal = _box.values.toList();
    for (final lokal in allLokal) {
      if (lokal.isSynced) {
        bool shouldDelete = false;
        if (isFullSync) {
          shouldDelete = !remoteIds.contains(lokal.formulirId);
        } else {
          shouldDelete = lokal.pelaporId == pelaporId && !remoteIds.contains(lokal.formulirId);
        }
        
        if (shouldDelete) {
          await _box.delete(lokal.formulirId);
        }
      }
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
