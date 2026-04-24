import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pol_lapor/core/constants/app_constants.dart';
import 'package:pol_lapor/data/datasources/local/auth_local_datasource.dart';
import 'package:pol_lapor/data/models/user_session.dart';

void main() {
  late AuthLocalDatasource datasource;

  final dummySession = UserSession(
    userId: 'user-123',
    nama: 'Dimas Rizal',
    email: 'dimas@polban.ac.id',
    role: 'pelapor',
    token: 'jwt-token-abc',
  );

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(UserSessionAdapter());
    await Hive.openBox<UserSession>(AppConstants.boxUser);
  });

  setUp(() {
    datasource = AuthLocalDatasource();
  });

  tearDown(() async {
    await Hive.box<UserSession>(AppConstants.boxUser).clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  // TC-01 sampai TC-10 tidak berubah, biarkan apa adanya
  test('TC-01: saveSession() menyimpan session dan bisa dibaca kembali', () async {
    await datasource.saveSession(dummySession);
    final result = datasource.getSession();
    expect(result, isNotNull);
    expect(result!.userId, equals('user-123'));
    expect(result.nama, equals('Dimas Rizal'));
    expect(result.email, equals('dimas@polban.ac.id'));
    expect(result.role, equals('pelapor'));
    expect(result.token, equals('jwt-token-abc'));
  });

  test('TC-02: getSession() return null jika belum pernah login', () {
    final result = datasource.getSession();
    expect(result, isNull);
  });

  test('TC-03: isLoggedIn() return false jika belum ada session', () {
    expect(datasource.isLoggedIn(), isFalse);
  });

  test('TC-04: isLoggedIn() return true setelah saveSession()', () async {
    await datasource.saveSession(dummySession);
    expect(datasource.isLoggedIn(), isTrue);
  });

  test('TC-05: clearSession() menghapus session, getSession() jadi null', () async {
    await datasource.saveSession(dummySession);
    await datasource.clearSession();
    expect(datasource.getSession(), isNull);
  });

  test('TC-06: isLoggedIn() return false setelah clearSession()', () async {
    await datasource.saveSession(dummySession);
    await datasource.clearSession();
    expect(datasource.isLoggedIn(), isFalse);
  });

  test('TC-07: saveSession() overwrite session lama jika dipanggil dua kali', () async {
    final sessionLama = UserSession(
      userId: 'user-999',
      nama: 'User Lama',
      email: 'lama@polban.ac.id',
      role: 'pelapor',
      token: 'token-lama',
    );
    final sessionBaru = UserSession(
      userId: 'user-123',
      nama: 'Dimas Rizal',
      email: 'dimas@polban.ac.id',
      role: 'pelapor',
      token: 'token-baru',
    );
    await datasource.saveSession(sessionLama);
    await datasource.saveSession(sessionBaru);
    final result = datasource.getSession();
    expect(result!.userId, equals('user-123'));
    expect(result.token, equals('token-baru'));
  });

  test('TC-08: session menyimpan role dengan benar untuk semua role yang valid', () async {
    final roles = ['pelapor', 'kasubbag_tu', 'petugas_bmn', 'teknisi_upt', 'admin'];
    for (final role in roles) {
      await datasource.saveSession(UserSession(
        userId: 'user-test',
        nama: 'Test User',
        email: 'test@polban.ac.id',
        role: role,
        token: 'token-test',
      ));
      final result = datasource.getSession();
      expect(result!.role, equals(role), reason: 'Role $role harus tersimpan dengan benar');
      await datasource.clearSession();
    }
  });

  test('TC-09: clearSession() tidak error meski dipanggil saat box kosong', () async {
    expect(() async => await datasource.clearSession(), returnsNormally);
  });

  test('TC-10: token tersimpan utuh dan tidak terpotong', () async {
    const longToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJ1c2VySWQiOiJ1c2VyLTEyMyIsInJvbGUiOiJwZWxhcG9yIn0.'
        'dummysignature123456';
    await datasource.saveSession(UserSession(
      userId: 'user-123',
      nama: 'Dimas',
      email: 'dimas@polban.ac.id',
      role: 'pelapor',
      token: longToken,
    ));
    final result = datasource.getSession();
    expect(result!.token, equals(longToken));
  });
}