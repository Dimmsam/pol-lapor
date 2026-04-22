import 'package:hive/hive.dart';

part 'laporan_lokal.g.dart'; // di-generate otomatis oleh build_runner

@HiveType(typeId: 0)
class LaporanLokal extends HiveObject {
  @HiveField(0)
  final String laporanId;       // UUID — primary key

  @HiveField(1)
  final String judul;

  @HiveField(2)
  final String deskripsi;

  @HiveField(3)
  final String kategori;

  @HiveField(4)
  final String lokasi;

  @HiveField(5)
  final String? nomorInventaris; // opsional

  @HiveField(6)
  final String? fotoLokalPath;   // path foto di device storage

  @HiveField(7)
  String? fotoCloudUrl;          // URL Cloudinary, diisi setelah sync

  @HiveField(8)
  String status;                 // menunggu_disposisi, dst

  @HiveField(9)
  final String pelaporId;        // userId dari UserSession

  @HiveField(10)
  bool isSynced;                 // false = belum terkirim ke server

  @HiveField(11)
  final DateTime createdAt;

  LaporanLokal({
    required this.laporanId,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.lokasi,
    this.nomorInventaris,
    this.fotoLokalPath,
    this.fotoCloudUrl,
    this.status = 'menunggu_disposisi',
    required this.pelaporId,
    this.isSynced = false,
    required this.createdAt,
  });
}