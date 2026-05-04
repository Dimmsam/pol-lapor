import 'package:hive_flutter/hive_flutter.dart';
import '../../models/laporan_lokal.dart';
import '../../../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

class HiveLocalDatasource {
  Box<LaporanLokal> get _box => Hive.box<LaporanLokal>(AppConstants.boxLaporan);

  // ── CREATE ────────────────────────────────────────────────────────────────
  Future<void> saveLaporan(LaporanLokal laporan) async {
    await _box.put(laporan.formulirId, laporan);
  }

  // ── READ ALL ──────────────────────────────────────────────────────────────
  List<LaporanLokal> getAllLaporan() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // terbaru di atas
    return list;
  }

  // ── READ UNSYNCED ─────────────────────────────────────────────────────────
  List<LaporanLokal> getUnsyncedLaporan() {
    return _box.values.where((l) => !l.isSynced).toList();
  }

  // ── READ BY ID ────────────────────────────────────────────────────────────
  LaporanLokal? getLaporanById(String formulirId) {
    return _box.get(formulirId);
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  Future<void> updateLaporan(LaporanLokal laporan) async {
    await _box.put(laporan.formulirId, laporan);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteLaporan(String formulirId) async {
    await _box.delete(formulirId);
  }

  // ── MARK SYNCED ───────────────────────────────────────────────────────────
  Future<void> markAsSynced(String formulirId, String fotoCloudUrl) async {
    final laporan = _box.get(formulirId);
    if (laporan == null) return;
    
    laporan.isSynced = true;
    laporan.fotoKerusakanUrl = fotoCloudUrl; 
    laporan.updatedAt = DateTime.now();
    await laporan.save(); 
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────
  Future<void> updateStatus(String formulirId, String statusBaru) async {
    final laporan = _box.get(formulirId);
    if (laporan == null) return;
    
    laporan.status = statusBaru;
    laporan.updatedAt = DateTime.now();
    await laporan.save();
  }

  // ── COUNT ─────────────────────────────────────────────────────────────────
  int countAll() =>
      Hive.box<LaporanLokal>(AppConstants.boxLaporan).length;

  int countUnsynced() =>
      Hive.box<LaporanLokal>(AppConstants.boxLaporan)
          .values
          .where((l) => !l.isSynced)
          .length;

  // ── LISTENABLE (REALTIME UI) ─────────────────────────────────────────
  ValueListenable<Box<LaporanLokal>> listenable() {
    return Hive.box<LaporanLokal>(AppConstants.boxLaporan).listenable();
  }
}