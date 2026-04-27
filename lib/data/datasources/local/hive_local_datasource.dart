import 'package:hive/hive.dart';
import '../../models/laporan_lokal.dart';
import '../../../core/constants/app_constants.dart';

class HiveLocalDatasource {
  Box<LaporanLokal> get _box => Hive.box<LaporanLokal>(AppConstants.boxLaporan);

  // ── CREATE ────────────────────────────────────────────────────────────────
  Future<void> saveLaporan(LaporanLokal laporan) async {
    await _box.put(laporan.laporanId, laporan);
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
  LaporanLokal? getLaporanById(String laporanId) {
    return _box.get(laporanId);
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  Future<void> updateLaporan(LaporanLokal laporan) async {
    await _box.put(laporan.laporanId, laporan);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteLaporan(String laporanId) async {
    await _box.delete(laporanId);
  }

  // ── MARK SYNCED ───────────────────────────────────────────────────────────
  Future<void> markAsSynced(String laporanId, String fotoCloudUrl) async {
    final laporan = _box.get(laporanId);
    if (laporan == null) return;
    laporan.isSynced = true;
    laporan.fotoUrl = fotoCloudUrl;
    laporan.updatedAt = DateTime.now();
    await laporan.save(); // HiveObject.save() langsung update tanpa put ulang
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────
  Future<void> updateStatus(String laporanId, String statusBaru) async {
    final laporan = _box.get(laporanId);
    if (laporan == null) return;
    laporan.status = statusBaru;
    laporan.updatedAt = DateTime.now();
    await laporan.save();
  }

  // ── COUNT ─────────────────────────────────────────────────────────────────
  int countAll() => _box.length;
  int countUnsynced() => _box.values.where((l) => !l.isSynced).length;
}
