import 'package:hive/hive.dart';
import '/data/models/laporan_lokal.dart'; // Sesuaikan jika nama filenya laporan_model.dart

class HiveService {
  static const String boxName = 'laporanBox';

  // Fungsi helper untuk membuka box
  Future<Box<LaporanLokal>> get _box async => await Hive.openBox<LaporanLokal>(boxName);

  // 1. CREATE / UPDATE
  // Menggunakan laporanId sebagai key agar konsisten dengan Controller
  Future<void> saveLaporan(LaporanLokal laporan) async {
    final box = await _box;
    await box.put(laporan.laporanId, laporan);
  }

  // 2. READ ALL
  Future<List<LaporanLokal>> getAllLaporan() async {
    final box = await _box;
    return box.values.toList();
  }

  // 3. READ BY ID
  Future<LaporanLokal?> getLaporanById(String id) async {
    final box = await _box;
    return box.get(id);
  }

  // 4. DELETE
  Future<void> deleteLaporan(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  // 5. MARK AS SYNCED
  // Fungsi krusial untuk sinkronisasi cloud nanti
  Future<void> markSynced(String id) async {
    final box = await _box;
    final laporan = box.get(id);
    if (laporan != null) {
      laporan.isSynced = true;
      await laporan.save(); // Menggunakan HiveObject.save()
    }
  }

  // 6. CLEAR ALL DATA (Opsional, berguna untuk testing)
  Future<void> deleteAllData() async {
    final box = await _box;
    await box.clear();
  }
}