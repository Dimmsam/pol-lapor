import 'package:hive/hive.dart';

part 'notifikasi_laporan.g.dart';

@HiveType(typeId: 2)
class NotifikasiLaporan extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String message;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  bool isRead;

  NotifikasiLaporan({
    required this.id,
    required this.title,
    required this.message,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();
}