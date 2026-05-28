import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
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
}
