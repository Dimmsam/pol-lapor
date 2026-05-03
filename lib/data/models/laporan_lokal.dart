import 'package:hive/hive.dart';

part 'laporan_lokal.g.dart'; // Jangan lupa jalankan build_runner lagi nanti

@HiveType(typeId: 0)
class LaporanLokal extends HiveObject {
  @HiveField(0)
  final String formulirId; // Dulu laporanId

  @HiveField(1)
  final String namaSarana; // Gabungan/pengganti judul & kategori

  @HiveField(2)
  final String keteranganKerusakan; // Dulu deskripsi

  @HiveField(3)
  final String lokasiPerbaikan; // Dulu lokasi

  @HiveField(4)
  final String? nomorInventaris;

  @HiveField(5)
  String? fotoLokalPath;

  @HiveField(6)
  String? fotoKerusakanUrl; // Dulu fotoUrl

  @HiveField(7)
  String status;

  @HiveField(8)
  final String pelaporId;

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  bool tandaTanganPelapor; // Tambahan dari ERD baru

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  LaporanLokal({
    required this.formulirId,
    required this.namaSarana,
    required this.keteranganKerusakan,
    required this.lokasiPerbaikan,
    this.nomorInventaris,
    this.fotoLokalPath,
    this.fotoKerusakanUrl,
    String? status,
    required this.pelaporId,
    this.isSynced = false,
    this.tandaTanganPelapor = true, // Asumsi pelapor setuju saat submit
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : status = status ?? 'menunggu_klasifikasi',
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();
}