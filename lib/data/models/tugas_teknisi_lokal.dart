import 'package:hive/hive.dart';

part 'tugas_teknisi_lokal.g.dart';

@HiveType(typeId: 2)
class TugasTeknisiLokal extends HiveObject {
  @HiveField(0)
  String penangananId; 

  @HiveField(1)
  String formulirId; 

  @HiveField(2)
  String namaSarana; 

  @HiveField(3)
  String lokasi; 

  @HiveField(4)
  String keteranganKerusakan; 

  @HiveField(5)
  String status; 

  @HiveField(6)
  String? catatanTeknisi; 

  @HiveField(7)
  String? fotoHasilLokalPath; 

  @HiveField(8)
  bool isSynced; 

  @HiveField(9)
  DateTime updatedAt;

  TugasTeknisiLokal({
    required this.penangananId,
    required this.formulirId,
    required this.namaSarana,
    required this.lokasi,
    required this.keteranganKerusakan,
    required this.status,
    this.catatanTeknisi,
    this.fotoHasilLokalPath,
    this.isSynced = true, 
    required this.updatedAt,
  });
}