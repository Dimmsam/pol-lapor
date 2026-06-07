import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pol_lapor/data/datasources/local/auth_local_datasource.dart';
import 'package:pol_lapor/data/datasources/remote/auth_remote_datasource.dart';
import 'package:pol_lapor/data/models/user_session.dart';
import 'package:pol_lapor/logic/providers/auth_provider.dart';
import 'package:pol_lapor/logic/providers/notifikasi_provider.dart';
import 'package:pol_lapor/logic/providers/laporan_provider.dart';

import 'auth_provider_test.mocks.dart';

// Generate mocks: flutter pub run build_runner build --delete-conflicting-outputs

@GenerateMocks([
  AuthLocalDatasource,
  AuthRemoteDatasource,
  NotifikasiProvider,
  LaporanProvider,
])
void main() {
  late MockAuthLocalDatasource mockLocal;
  late MockAuthRemoteDatasource mockRemote;
  late AuthProvider authProvider;

  final dummySession = UserSession(
    userId: 'user-123',
    nama: 'Budi Santoso',
    email: 'budi@example.com',
    role: 'pelapor',
    token: 'token-abc',
    keahlian: null,
    nomorTelepon: '081234567890',
  );

  setUp(() {
    mockLocal = MockAuthLocalDatasource();
    mockRemote = MockAuthRemoteDatasource();
    authProvider = AuthProvider.withDependencies(
      localAuth: mockLocal,
      remoteAuth: mockRemote,
    );
  });

  // ══════════════════════════════════════════════════════════════
  // WHITE BOX TESTING — fokus pada method login()
  // Menguji alur internal: branch, state transitions, side effects
  // ══════════════════════════════════════════════════════════════

  group('[WHITE BOX] login() — path sukses', () {
    test('WB-01: Status berubah loading → success secara berurutan', () async {
      final statuses = <LoginStatus>[];
      authProvider.addListener(() => statuses.add(authProvider.status));

      when(mockRemote.login(any, any)).thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      await authProvider.login('budi@example.com', 'password123');

      expect(statuses[0], LoginStatus.loading);
      expect(statuses[1], LoginStatus.success);
    });

    test('WB-02: errorMessage direset ke null di awal setiap login', () async {
      // Simulasi login gagal dulu agar errorMessage terisi
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Invalid login credentials'));
      await authProvider.login('x@x.com', 'salah');
      expect(authProvider.errorMessage, isNotNull);

      // Login ulang dengan kredensial valid
      when(mockRemote.login(any, any)).thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});
      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.errorMessage, isNull);
    });

    test('WB-03: saveSession dipanggil tepat 1x dengan session yang benar', () async {
      when(mockRemote.login(any, any)).thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      await authProvider.login('budi@example.com', 'password123');

      verify(mockLocal.saveSession(dummySession)).called(1);
    });

    test('WB-04: _session terupdate ke nilai yang dikembalikan remote', () async {
      when(mockRemote.login(any, any)).thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.session, dummySession);
    });

    test('WB-05: notifyListeners dipanggil saat loading dan saat selesai', () async {
      int notifyCount = 0;
      authProvider.addListener(() => notifyCount++);

      when(mockRemote.login(any, any)).thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      await authProvider.login('budi@example.com', 'password123');

      // Minimal 2x: saat set loading, saat set success
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('[WHITE BOX] login() — branch catch AuthException (_mapAuthError)', () {
    test('WB-06: "Invalid login credentials" → pesan credentials salah', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Invalid login credentials'));

      await authProvider.login('budi@example.com', 'salah');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, 'Email atau password salah.');
    });

    test('WB-07: "Email not confirmed" → pesan belum dikonfirmasi', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Email not confirmed'));

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('belum dikonfirmasi'));
    });

    test('WB-08: "Too many requests" → pesan tunggu beberapa saat', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Too many requests'));

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('Terlalu banyak percobaan'));
    });

    test('WB-09: "network" → pesan tidak ada koneksi internet', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('network connection failed'));

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('koneksi internet'));
    });

    test('WB-10: AuthException tidak dikenal → pesan generik "Login gagal: ..."', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('some unknown supabase error'));

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('Login gagal'));
    });

    test('WB-11: saveSession TIDAK dipanggil saat AuthException', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Invalid login credentials'));

      await authProvider.login('budi@example.com', 'salah');

      verifyNever(mockLocal.saveSession(any));
    });
  });

  group('[WHITE BOX] login() — branch catch Exception umum', () {
    test('WB-12: Exception biasa → status error, pesan "Terjadi kesalahan: ..."', () async {
      when(mockRemote.login(any, any))
          .thenThrow(Exception('Unexpected server failure'));

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('Terjadi kesalahan'));
    });

    test('WB-13: saveSession TIDAK dipanggil saat exception umum', () async {
      when(mockRemote.login(any, any))
          .thenThrow(Exception('Unexpected server failure'));

      await authProvider.login('budi@example.com', 'password123');

      verifyNever(mockLocal.saveSession(any));
    });

    test('WB-14: Status loading → error meskipun exception umum', () async {
      final statuses = <LoginStatus>[];
      authProvider.addListener(() => statuses.add(authProvider.status));

      when(mockRemote.login(any, any))
          .thenThrow(Exception('Unexpected server failure'));

      await authProvider.login('budi@example.com', 'password123');

      expect(statuses.first, LoginStatus.loading);
      expect(statuses.last, LoginStatus.error);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // BLACK BOX TESTING — semua method
  // Menguji perilaku dari perspektif pengguna (input → output)
  // ══════════════════════════════════════════════════════════════

  group('[BLACK BOX - POSITIF] login()', () {
    test('BB-P-01: Email & password valid → status success, session berisi data user', () async {
      when(mockRemote.login('budi@example.com', 'password123'))
          .thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.status, LoginStatus.success);
      expect(authProvider.session?.userId, 'user-123');
      expect(authProvider.session?.email, 'budi@example.com');
      expect(authProvider.errorMessage, isNull);
    });

    test('BB-P-02: Login sukses → isLoggedIn() mengembalikan true', () async {
      when(mockRemote.login(any, any)).thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});
      when(mockLocal.isLoggedIn()).thenReturn(true);

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.isLoggedIn(), isTrue);
    });
  });

  group('[BLACK BOX - POSITIF] register()', () {
    test('BB-P-03: Data lengkap valid → status success, session tidak null', () async {
      when(mockRemote.register(
        namaLengkap: anyNamed('namaLengkap'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        nomorTelepon: anyNamed('nomorTelepon'),
      )).thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      await authProvider.register(
        namaLengkap: 'Budi Santoso',
        email: 'budi@example.com',
        password: 'password123',
        nomorTelepon: '081234567890',
      );

      expect(authProvider.status, LoginStatus.success);
      expect(authProvider.session, isNotNull);
    });

    test('BB-P-04: Register tanpa nomor telepon (field opsional) → tetap sukses', () async {
      when(mockRemote.register(
        namaLengkap: anyNamed('namaLengkap'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        nomorTelepon: null,
      )).thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      await authProvider.register(
        namaLengkap: 'Budi Santoso',
        email: 'budi@example.com',
        password: 'password123',
      );

      expect(authProvider.status, LoginStatus.success);
    });
  });

  group('[BLACK BOX - POSITIF] restoreSession()', () {
    test('BB-P-05: Token Supabase masih aktif → kembalikan session, tidak perlu login ulang', () async {
      when(mockRemote.getSessionFromSupabase())
          .thenAnswer((_) async => dummySession);
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      final result = await authProvider.restoreSession();

      expect(result, isNotNull);
      expect(result?.userId, 'user-123');
      expect(authProvider.session, isNotNull);
    });
  });

  group('[BLACK BOX - POSITIF] updateNama()', () {
    test('BB-P-06: Nama baru valid → session lokal memuat nama yang diperbarui', () async {
      authProvider.setSessionForTest(dummySession);
      when(mockRemote.updateNamaLengkap(any, any)).thenAnswer((_) async {});
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      await authProvider.updateNama('Budi Baru');

      expect(authProvider.session?.nama, 'Budi Baru');
    });

    test('BB-P-07: Nama dengan spasi di tepi → tersimpan dalam bentuk trimmed', () async {
      authProvider.setSessionForTest(dummySession);
      when(mockRemote.updateNamaLengkap(any, 'Budi Baru')).thenAnswer((_) async {});
      when(mockLocal.saveSession(any)).thenAnswer((_) async {});

      await authProvider.updateNama('  Budi Baru  ');

      expect(authProvider.session?.nama, 'Budi Baru');
    });
  });

  group('[BLACK BOX - POSITIF] updatePassword()', () {
    test('BB-P-08: Password lama benar, password baru valid → tidak throw', () async {
      authProvider.setSessionForTest(dummySession);
      when(mockRemote.updatePassword(any, any, any)).thenAnswer((_) async {});

      await expectLater(
        authProvider.updatePassword('oldpass123', 'newpass456'),
        completes,
      );
    });
  });

  group('[BLACK BOX - POSITIF] logout()', () {
    test('BB-P-09: User sedang login lalu logout → session null, status idle', () async {
      authProvider.setSessionForTest(dummySession);
      when(mockLocal.clearSession()).thenAnswer((_) async {});
      when(mockRemote.logout()).thenAnswer((_) async {});

      await authProvider.logout();

      expect(authProvider.session, isNull);
      expect(authProvider.status, LoginStatus.idle);
    });
  });

  group('[BLACK BOX - POSITIF] resetError()', () {
    test('BB-P-10: Ada error aktif lalu reset → errorMessage null, status idle', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Invalid login credentials'));
      await authProvider.login('x@x.com', 'salah');
      expect(authProvider.status, LoginStatus.error);

      authProvider.resetError();

      expect(authProvider.errorMessage, isNull);
      expect(authProvider.status, LoginStatus.idle);
    });
  });

  // ──────────────────────────────────────────────

  group('[BLACK BOX - NEGATIF] login()', () {
    test('BB-N-01: Password salah → status error, pesan kredensial salah, session null', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Invalid login credentials'));

      await authProvider.login('budi@example.com', 'wrongpassword');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, 'Email atau password salah.');
      expect(authProvider.session, isNull);
    });

    test('BB-N-02: Email tidak terdaftar → status error', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Invalid login credentials'));

      await authProvider.login('tidakada@example.com', 'password123');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.session, isNull);
    });

    test('BB-N-03: Email belum dikonfirmasi → pesan konfirmasi email', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Email not confirmed'));

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('belum dikonfirmasi'));
    });

    test('BB-N-04: Tanpa koneksi internet → pesan tidak ada koneksi', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('network connection failed'));

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('koneksi internet'));
    });

    test('BB-N-05: Rate limit (terlalu banyak percobaan) → pesan tunggu', () async {
      when(mockRemote.login(any, any))
          .thenThrow(AuthException('Too many requests'));

      await authProvider.login('budi@example.com', 'password123');

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('Terlalu banyak percobaan'));
    });
  });

  group('[BLACK BOX - NEGATIF] register()', () {
    test('BB-N-06: Email sudah terdaftar → pesan sudah terdaftar', () async {
      when(mockRemote.register(
        namaLengkap: anyNamed('namaLengkap'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        nomorTelepon: anyNamed('nomorTelepon'),
      )).thenThrow(AuthException('User already registered'));

      await authProvider.register(
        namaLengkap: 'Budi',
        email: 'budi@example.com',
        password: 'password123',
      );

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('sudah terdaftar'));
    });

    test('BB-N-07: Password kurang dari 6 karakter → pesan minimal 6 karakter', () async {
      when(mockRemote.register(
        namaLengkap: anyNamed('namaLengkap'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        nomorTelepon: anyNamed('nomorTelepon'),
      )).thenThrow(AuthException('Password should be at least 6 characters'));

      await authProvider.register(
        namaLengkap: 'Budi',
        email: 'budi@example.com',
        password: '123',
      );

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('minimal 6 karakter'));
    });

    test('BB-N-08: Format email tidak valid → pesan format email', () async {
      when(mockRemote.register(
        namaLengkap: anyNamed('namaLengkap'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        nomorTelepon: anyNamed('nomorTelepon'),
      )).thenThrow(AuthException('Please enter a valid email'));

      await authProvider.register(
        namaLengkap: 'Budi',
        email: 'bukan-email',
        password: 'password123',
      );

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('Format email'));
    });

    test('BB-N-09: Tanpa koneksi saat register → pesan jaringan', () async {
      when(mockRemote.register(
        namaLengkap: anyNamed('namaLengkap'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        nomorTelepon: anyNamed('nomorTelepon'),
      )).thenThrow(AuthException('network unavailable'));

      await authProvider.register(
        namaLengkap: 'Budi',
        email: 'budi@example.com',
        password: 'password123',
      );

      expect(authProvider.status, LoginStatus.error);
      expect(authProvider.errorMessage, contains('koneksi internet'));
    });
  });

  group('[BLACK BOX - NEGATIF] updateNama()', () {
    test('BB-N-10: Input string kosong → throw Exception "Nama tidak boleh kosong"', () async {
      authProvider.setSessionForTest(dummySession);

      expect(
        () async => await authProvider.updateNama(''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Nama tidak boleh kosong'),
        )),
      );
    });

    test('BB-N-11: Input hanya spasi → throw Exception', () async {
      authProvider.setSessionForTest(dummySession);

      expect(
        () async => await authProvider.updateNama('   '),
        throwsA(isA<Exception>()),
      );
    });

    test('BB-N-12: Session tidak ada → tidak ada perubahan, session tetap null', () async {
      await authProvider.updateNama('Nama Baru');

      expect(authProvider.session, isNull);
    });
  });

  group('[BLACK BOX - NEGATIF] updatePassword()', () {
    test('BB-N-13: Session tidak ada → throw Exception "Sesi tidak ditemukan"', () async {
      expect(
        () async => await authProvider.updatePassword('oldpass', 'newpass'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Sesi tidak ditemukan'),
        )),
      );
    });
  });

  group('[BLACK BOX - NEGATIF] restoreSession()', () {
    test('BB-N-14: Token expired / tidak ada sesi → return null', () async {
      when(mockRemote.getSessionFromSupabase()).thenAnswer((_) async => null);
      when(mockLocal.clearSession()).thenAnswer((_) async {});

      final result = await authProvider.restoreSession();

      expect(result, isNull);
      expect(authProvider.session, isNull);
    });
  });

  group('[BLACK BOX - NEGATIF] logout()', () {
    test('BB-N-15: Remote logout gagal → tidak throw, sesi lokal tetap terhapus', () async {
      authProvider.setSessionForTest(dummySession);
      when(mockLocal.clearSession()).thenAnswer((_) async {});
      when(mockRemote.logout()).thenThrow(Exception('Network error'));

      await expectLater(authProvider.logout(), completes);

      expect(authProvider.session, isNull);
      expect(authProvider.status, LoginStatus.idle);
    });
  });
}