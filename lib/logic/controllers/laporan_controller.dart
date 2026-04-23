import '/models/laporan_model.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class LaporanController {
  static const String boxName = 'laporanBox';
  final _uuid = Uuid();

  // 1. Ambil Semua Laporan untuk ditampilkan di Dashboard
  Future<List<LaporanLokal>> getAllLaporan() async {
    var box = await Hive.openBox<LaporanLokal>(boxName);
    return box.values.toList();
  }

  // 2. Buat Laporan Baru (Create)
  Future<void> tambahLaporan(String judul, String deskripsi) async {
    var box = await Hive.openBox<LaporanLokal>(boxName);
    
    final baru = LaporanLokal(
      uuid: _uuid.v4(),
      judul: judul,
      deskripsi: deskripsi,
      status: 1, // Default status awal
      isSynced: false,
    );

    await box.put(baru.uuid, baru);
  }

  // 3. Ubah Status Laporan (Update Status)
  // Kamu tinggal panggil ini dan masukkan angka statusnya (misal: 2, 3, dst)
  Future<void> gantiStatus(String uuid, int statusTarget) async {
    var box = await Hive.openBox<LaporanLokal>(boxName);
    var laporan = box.get(uuid);
    
    if (laporan != null) {
      laporan.status = statusTarget;
      laporan.isSynced = false; // Reset flag sync karena ada perubahan data
      await laporan.save(); // Simpan perubahan ke Hive
    }
  }

  // 4. Hapus Laporan (Delete)
  Future<void> hapusLaporan(String uuid) async {
    var box = await Hive.openBox<LaporanLokal>(boxName);
    await box.delete(uuid);
  }
}