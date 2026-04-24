// lib/data/models/laporan_lokal.dart
import 'package:hive/hive.dart';

part 'laporan_lokal.g.dart';

@HiveType(typeId: 0)
class LaporanLokal extends HiveObject {
  @HiveField(0)
  String laporanId;

  @HiveField(1)
  String judul;

  @HiveField(2)
  String deskripsi;

  @HiveField(3)
  String kategori;

  @HiveField(4)
  String lokasi;

  @HiveField(5)
  String? nomorInventaris;

  @HiveField(6)
  String tingkatKerusakan;

  @HiveField(7)
  String? fotoPath;

  @HiveField(8)
  String? fotoCloudUrl;

  @HiveField(9)
  String status; // 'menunggu', 'diproses', 'selesai', dll.

  @HiveField(10)
  bool isSynced;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  String pelaporId;

  LaporanLokal({
    required this.laporanId,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.lokasi,
    this.nomorInventaris,
    required this.tingkatKerusakan,
    this.fotoPath,
    this.fotoCloudUrl,
    this.status = 'menunggu',
    this.isSynced = false,
    DateTime? createdAt,
    required this.pelaporId,
  }) : createdAt = createdAt ?? DateTime.now();
}
