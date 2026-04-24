// lib/data/models/user_session.dart
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
  final String role;

  @HiveField(4)
  final String token;

  UserSession({
    required this.userId,
    required this.nama,
    required this.email,
    required this.role,
    required this.token,
  });
}
