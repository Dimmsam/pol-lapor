import 'package:hive/hive.dart';
import '../models/laporan_model.dart';

class HiveService {
  static const String boxName = 'laporanBox';

  // 1. CREATE / SAVE
  Future<void> saveLaporan(LaporanLokal laporan) async {
    var box = await Hive.openBox<LaporanLokal>(boxName);
    // Kita gunakan uuid sebagai key agar mudah dicari (update/delete)
    await box.put(laporan.uuid, laporan);
  }

  // 2. READ ALL
  Future<List<LaporanLokal>> getAllLaporan() async {
    var box = await Hive.openBox<LaporanLokal>(boxName);
    return box.values.toList();
  }

  // 3. READ BY UUID (Untuk pengecekan spesifik)
  LaporanLokal? getLaporanByUuid(String uuid) {
    var box = Hive.box<LaporanLokal>(boxName);
    return box.get(uuid);
  }

  // 4. UPDATE (Bisa untuk edit data atau sekedar update status)
  Future<void> updateLaporan(String uuid, LaporanLokal dataBaru) async {
    var box = await Hive.openBox<LaporanLokal>(boxName);
    // Saat data lokal diupdate, kita harus set isSynced ke false lagi
    dataBaru.isSynced = false; 
    await box.put(uuid, dataBaru);
  }

  // 5. DELETE
  Future<void> deleteLaporan(String uuid) async {
    var box = await Hive.openBox<LaporanLokal>(boxName);
    await box.delete(uuid);
  }

  // 6. MARK AS SYNCED (Khusus dipanggil setelah sukses kirim ke Laravel)
  Future<void> markSynced(String uuid) async {
    var box = await Hive.openBox<LaporanLokal>(boxName);
    var laporan = box.get(uuid);
    if (laporan != null) {
      laporan.isSynced = true;
      await laporan.save(); // Method bawaan HiveObject
    }
  }
}