import 'package:hive/hive.dart';

part 'laporan_model.g.dart';

@HiveType(typeId: 0)
class LaporanLokal extends HiveObject {
  @HiveField(0)
  String uuid;

  @HiveField(1)
  String judul;

  @HiveField(2)
  String deskripsi;

  @HiveField(3)
  int status; // Kita pakai angka 1-8

  @HiveField(4)
  bool isSynced;

  LaporanLokal({
    required this.uuid,
    required this.judul,
    required this.deskripsi,
    this.status = 1,
    this.isSynced = false,
  });
}