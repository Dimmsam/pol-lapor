import 'package:hive/hive.dart';

part 'laporan_lokal.g.dart';

@HiveType(typeId: 0)
class LaporanLokal extends HiveObject {
  @HiveField(0)
  final String laporanId;

  @HiveField(1)
  final String judul;

  @HiveField(2)
  final String deskripsi;

  @HiveField(3)
  final String kategori; // AC_Kipas | Proyektor | Listrik | dll

  @HiveField(4)
  final String lokasi;

  @HiveField(5)
  final String? nomorInventaris;

  @HiveField(6)
  String? fotoLokalPath;

  @HiveField(7)
  String? fotoUrl; // URL Supabase Storage (diisi setelah sync)

  @HiveField(8)
  String status; // 8 status sesuai AppConstants

  @HiveField(9)
  String? tingkatKerusakan; // rusak_ringan | rusak_berat | null

  @HiveField(10)
  final String pelaporId;

  @HiveField(11)
  bool isSynced;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  DateTime updatedAt;

  LaporanLokal({
    required this.laporanId,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.lokasi,
    this.nomorInventaris,
    String? fotoLokalPath,
    String? fotoPath,
    String? fotoUrl,
    String? fotoCloudUrl,
    String? status,
    this.tingkatKerusakan,
    required this.pelaporId,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : fotoLokalPath = fotoLokalPath ?? fotoPath,
       fotoUrl = fotoUrl ?? fotoCloudUrl,
       status = status ?? 'menunggu_klasifikasi',
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  String? get fotoPath => fotoLokalPath;
  set fotoPath(String? value) => fotoLokalPath = value;

  String? get fotoCloudUrl => fotoUrl;
  set fotoCloudUrl(String? value) => fotoUrl = value;
}
