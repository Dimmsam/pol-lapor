import 'package:hive/hive.dart';

part 'user_session.g.dart';

@HiveType(typeId: 1)
class UserSession extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String nama;

  @HiveField(2)
  final String email;

  @HiveField(3)
  // Role sesuai 7 aktor: pelapor | teknisi_jurusan | admin_jurusan |
  // kajur | admin_upt_pp | ketua_upt_pp | teknisi_upt_pp
  final String role;

  @HiveField(4)
  final String token; // JWT dari Supabase Auth

  @HiveField(5)
  final String? unitGedung; // untuk teknisi & admin jurusan

  UserSession({
    required this.userId,
    required this.nama,
    required this.email,
    required this.role,
    required this.token,
    this.unitGedung,
  });
}