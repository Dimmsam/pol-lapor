import '/data/models/laporan_lokal.dart'; // Sesuaikan path jika berbeda
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class LaporanController {
  static const String boxName = 'laporanBox';
  final _uuid = Uuid();

  // 1. Ambil Semua Laporan untuk ditampilkan di Dashboard
  Future<List<LaporanLokal>> getAllLaporan() async {
    final box = await Hive.openBox<LaporanLokal>(boxName);
    return box.values.toList();
  }

  // 2. Buat Laporan Baru (Create)
  Future<void> tambahLaporan({
    required String judul,
    required String deskripsi,
    required String kategori,
    required String lokasi,
    required String tingkatKerusakan,
    required String pelaporId, // Wajib ada sesuai model baru
    String? fotoPath,
    String? nomorInventaris,
  }) async {
    // Validasi agar data tidak kosong
    if (judul.trim().isEmpty ||
        deskripsi.trim().isEmpty ||
        kategori.trim().isEmpty ||
        lokasi.trim().isEmpty ||
        tingkatKerusakan.trim().isEmpty ||
        pelaporId.trim().isEmpty) {
      throw ArgumentError('Data laporan wajib belum lengkap');
    }

    final box = await Hive.openBox<LaporanLokal>(boxName);

    final baru = LaporanLokal(
      laporanId: _uuid.v4(), // Disesuaikan: sebelumnya uuid
      judul: judul,
      deskripsi: deskripsi,
      kategori: kategori,
      lokasi: lokasi,
      nomorInventaris: nomorInventaris,
      tingkatKerusakan: tingkatKerusakan,
      fotoPath: fotoPath,
      status: 'menunggu', // Disesuaikan: menggunakan String sesuai model
      isSynced: false,
      pelaporId: pelaporId, // Disesuaikan: parameter baru dari model
      createdAt: DateTime.now(),
    );

    // Disesuaikan: menggunakan laporanId sebagai key di Hive
    await box.put(baru.laporanId, baru); 
  }

  // 3. Ubah Status Laporan (Update Status)
  // Masukkan string statusTarget (misal: 'diproses', 'selesai')
  Future<void> gantiStatus(String laporanId, String statusTarget) async {
    final box = await Hive.openBox<LaporanLokal>(boxName);
    final laporan = box.get(laporanId); // Disesuaikan: cari pakai laporanId

    if (laporan != null) {
      laporan.status = statusTarget;
      laporan.isSynced = false; // Tandai false agar tersinkronisasi ulang ke cloud
      await laporan.save();
    }
  }

  // 4. Hapus Laporan (Delete)
  Future<void> hapusLaporan(String laporanId) async {
    final box = await Hive.openBox<LaporanLokal>(boxName);
    await box.delete(laporanId); // Disesuaikan: hapus pakai laporanId
  }
}