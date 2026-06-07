// ============================================================================
// WHITE-BOX TEST — FormLaporanProvider.updateLaporan()
// Anggota 2 - Rina Permata Dewi: Fitur Pembuatan Laporan (Pelapor)
//
// Jalankan dengan:
//   flutter test test/logic/providers/form_laporan_provider_test.dart
//
// Dependencies yang diperlukan di pubspec.yaml:
//   dev_dependencies:
//     flutter_test:
//       sdk: flutter
//     mockito: ^5.4.4
//     build_runner: ^2.4.8
//
// Generate mock:
//   flutter pub run build_runner build --delete-conflicting-outputs
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pol_lapor/data/datasources/local/laporan_local_datasource.dart';
import 'package:pol_lapor/data/datasources/remote/laporan_remote_datasource.dart';
import 'package:pol_lapor/data/datasources/remote/storage_remote_datasource.dart';
import 'package:pol_lapor/data/models/laporan_lokal.dart';
import 'package:pol_lapor/logic/providers/form_laporan_provider.dart';
import 'package:pol_lapor/services/sync_service.dart';

import 'form_laporan_provider_test.mocks.dart';

// ── Anotasi untuk generate mock ──────────────────────────────────────────────
@GenerateMocks([
  LaporanLocalDatasource,
  LaporanRemoteDatasource,
  StorageRemoteDatasource,
  SyncService,
])

// ── Helper: buat LaporanLokal dummy ──────────────────────────────────────────
LaporanLokal buatLaporan({
  String formulirId = 'F-TEST-001',
  bool isSynced = false,
  String? fotoLokalPath,
  String? fotoKerusakanUrl,
  String? nomorInventaris,
  String namaSarana = 'Proyektor',
  String keteranganKerusakan = 'Tidak menyala',
  String lokasiPerbaikan = 'Lab A',
  String status = StatusLaporan.menungguKlasifikasi,
}) {
  return LaporanLokal(
    formulirId: formulirId,
    namaSarana: namaSarana,
    keteranganKerusakan: keteranganKerusakan,
    lokasiPerbaikan: lokasiPerbaikan,
    nomorInventaris: nomorInventaris,
    fotoLokalPath: fotoLokalPath,
    fotoKerusakanUrl: fotoKerusakanUrl,
    pelaporId: 'PELAPOR-001',
    isSynced: isSynced,
    status: status,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

// ── Helper: buat provider dengan dependency injection ─────────────────────────
//
// CATATAN: FormLaporanProvider perlu direfactor agar menerima
// dependency lewat constructor. Contoh refactor:
//
//   class FormLaporanProvider extends ChangeNotifier {
//     final LaporanLocalDatasource _local;
//     final LaporanRemoteDatasource _remote;
//     final StorageRemoteDatasource _storage;
//     final SyncService _sync;
//
//     FormLaporanProvider({
//       LaporanLocalDatasource? local,
//       LaporanRemoteDatasource? remote,
//       StorageRemoteDatasource? storage,
//       SyncService? sync,
//     })  : _local = local ?? LaporanLocalDatasource(),
//           _remote = remote ?? LaporanRemoteDatasource(),
//           _storage = storage ?? StorageRemoteDatasource(),
//           _sync = sync ?? SyncService();
//     ...
//   }

FormLaporanProvider buatProvider({
  required MockLaporanLocalDatasource mockLocal,
  required MockLaporanRemoteDatasource mockRemote,
  required MockStorageRemoteDatasource mockStorage,
  required MockSyncService mockSync,
}) {
  return FormLaporanProvider(
    local: mockLocal,
    remote: mockRemote,
    storage: mockStorage,
    sync: mockSync,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Setup mock ──────────────────────────────────────────────────────────────
  late MockLaporanLocalDatasource mockLocal;
  late MockLaporanRemoteDatasource mockRemote;
  late MockStorageRemoteDatasource mockStorage;
  late MockSyncService mockSync;
  late FormLaporanProvider provider;

  setUp(() {
    mockLocal = MockLaporanLocalDatasource();
    mockRemote = MockLaporanRemoteDatasource();
    mockStorage = MockStorageRemoteDatasource();
    mockSync = MockSyncService();

    // Default stub sync agar tidak throw
    when(mockSync.syncUnsyncedData()).thenAnswer((_) async {});

    provider = buatProvider(
      mockLocal: mockLocal,
      mockRemote: mockRemote,
      mockStorage: mockStorage,
      mockSync: mockSync,
    );
  });

  // ============================================================================
  // CABANG 1: isSynced = FALSE
  // ============================================================================
  group('TC-WB-01 s/d 03 | isSynced = false', () {

    // TC-WB-01
    test(
      'TC-WB-01: Laporan belum sync → hanya update lokal, remote TIDAK dipanggil, syncInBackground dipanggil',
      () async {
        // Setup
        final existing = buatLaporan(isSynced: false);
        when(mockLocal.updateLaporan(any)).thenAnswer((_) async {});

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'Monitor',
          keteranganKerusakan: 'Layar retak',
          lokasiPerbaikan: 'Lab B',
          fotoLokalPath: null,
        );

        // Verify
        verifyNever(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
        ));
        verifyNever(mockStorage.uploadFotoKerusakan(
          filePath: anyNamed('filePath'),
          formulirId: anyNamed('formulirId'),
        ));
        verify(mockLocal.updateLaporan(any)).called(1);
        verify(mockSync.syncUnsyncedData()).called(1);
        expect(provider.isSubmitting, false);
        expect(provider.errorMessage, isNull);
      },
    );

    // TC-WB-02
    test(
      'TC-WB-02: Laporan belum sync dengan foto baru → foto TIDAK diupload ke remote, lokal diupdate dengan fotoLokalPath baru',
      () async {
        // Setup
        final existing = buatLaporan(isSynced: false);
        LaporanLokal? capturedLaporan;
        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'Printer',
          keteranganKerusakan: 'Paper jam',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: '/new/foto.jpg',
        );

        // Verify
        verifyNever(mockStorage.uploadFotoKerusakan(
          filePath: anyNamed('filePath'),
          formulirId: anyNamed('formulirId'),
        ));
        verify(mockLocal.updateLaporan(any)).called(1);
        expect(capturedLaporan?.fotoLokalPath, '/new/foto.jpg');
        verify(mockSync.syncUnsyncedData()).called(1);
        expect(provider.isSubmitting, false);
      },
    );

    // TC-WB-03
    test(
      'TC-WB-03: isSynced tetap false setelah update lokal (tidak berubah ke true)',
      () async {
        // Setup
        final existing = buatLaporan(isSynced: false);
        LaporanLokal? capturedLaporan;
        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'AC',
          keteranganKerusakan: 'Tidak dingin',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
        );

        // Verify
        expect(capturedLaporan?.isSynced, false,
            reason: 'isSynced harus tetap false agar sync service bisa handle');
      },
    );
  });

  // ============================================================================
  // CABANG 2: isSynced = TRUE, tanpa foto baru
  // ============================================================================
  group('TC-WB-04 s/d 05 | isSynced = true, fotoLokalPath = null', () {

    // TC-WB-04
    test(
      'TC-WB-04: Laporan sudah sync tanpa foto baru → update remote langsung, syncInBackground TIDAK dipanggil',
      () async {
        // Setup
        final existing = buatLaporan(
          isSynced: true,
          fotoKerusakanUrl: 'https://cdn/lama.jpg',
        );
        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenAnswer((_) async {});
        when(mockLocal.updateLaporan(any)).thenAnswer((_) async {});

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'Kursi Rusak',
          keteranganKerusakan: 'Kaki patah',
          lokasiPerbaikan: 'Ruang Rapat',
          fotoLokalPath: null,
        );

        // Verify
        verifyNever(mockStorage.uploadFotoKerusakan(
          filePath: anyNamed('filePath'),
          formulirId: anyNamed('formulirId'),
        ));
        verify(mockRemote.updateLaporanRemote(
          formulirId: existing.formulirId,
          namaSarana: 'Kursi Rusak',
          keteranganKerusakan: 'Kaki patah',
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: null,
        )).called(1);
        verifyNever(mockSync.syncUnsyncedData());
        expect(provider.isSubmitting, false);
        expect(provider.errorMessage, isNull);
      },
    );

    // TC-WB-05
    test(
      'TC-WB-05: isSynced=true tanpa foto baru → fotoKerusakanUrl lokal tetap URL lama',
      () async {
        // Setup
        final existing = buatLaporan(
          isSynced: true,
          fotoKerusakanUrl: 'https://cdn/foto-lama.jpg',
        );
        LaporanLokal? capturedLaporan;
        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenAnswer((_) async {});
        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'Meja',
          keteranganKerusakan: 'Rusak',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
        );

        // Verify
        expect(
          capturedLaporan?.fotoKerusakanUrl,
          'https://cdn/foto-lama.jpg',
          reason: 'URL lama harus dipertahankan saat tidak ada foto baru',
        );
      },
    );
  });

  // ============================================================================
  // CABANG 3: isSynced = TRUE, dengan foto baru
  // ============================================================================
  group('TC-WB-06 s/d 07 | isSynced = true, fotoLokalPath != null', () {

    // TC-WB-06
    test(
      'TC-WB-06: isSynced=true dengan foto baru → upload dulu, URL baru masuk ke remote dan lokal',
      () async {
        // Setup
        final existing = buatLaporan(
          formulirId: 'F-006',
          isSynced: true,
          fotoKerusakanUrl: 'https://cdn/lama.jpg',
        );
        LaporanLokal? capturedLaporan;

        when(mockStorage.uploadFotoKerusakan(
          filePath: '/local/foto-baru.jpg',
          formulirId: 'F-006',
        )).thenAnswer((_) async => 'https://cdn/foto-baru.jpg');

        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenAnswer((_) async {});

        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'Monitor',
          keteranganKerusakan: 'Layar retak',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: '/local/foto-baru.jpg',
        );

        // Verify
        verify(mockStorage.uploadFotoKerusakan(
          filePath: '/local/foto-baru.jpg',
          formulirId: 'F-006',
        )).called(1);

        verify(mockRemote.updateLaporanRemote(
          formulirId: 'F-006',
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: 'https://cdn/foto-baru.jpg',
        )).called(1);

        expect(capturedLaporan?.fotoKerusakanUrl, 'https://cdn/foto-baru.jpg');
        verifyNever(mockSync.syncUnsyncedData());
        expect(provider.isSubmitting, false);
      },
    );

    // TC-WB-07
    test(
      'TC-WB-07: isSynced=true, fotoLokalPath="" (empty string) → upload TIDAK dipanggil (isNotEmpty = false)',
      () async {
        // Setup
        final existing = buatLaporan(
          isSynced: true,
          fotoKerusakanUrl: 'https://cdn/lama.jpg',
        );
        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenAnswer((_) async {});
        when(mockLocal.updateLaporan(any)).thenAnswer((_) async {});

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'AC',
          keteranganKerusakan: 'Rusak',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: '', // empty string
        );

        // Verify: karena ''.isNotEmpty = false, upload tidak dipanggil
        verifyNever(mockStorage.uploadFotoKerusakan(
          filePath: anyNamed('filePath'),
          formulirId: anyNamed('formulirId'),
        ));
        verify(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: null,
        )).called(1);
      },
    );
  });

  // ============================================================================
  // CABANG 4: Upload foto gagal
  // ============================================================================
  group('TC-WB-08 s/d 09 | Upload foto gagal', () {

    // TC-WB-08
    test(
      'TC-WB-08: Upload foto throw exception → proses tetap lanjut, remote dipanggil dengan fotoUrl=null, tidak crash',
      () async {
        // Setup
        final existing = buatLaporan(
          isSynced: true,
          fotoKerusakanUrl: 'https://cdn/lama.jpg',
        );
        LaporanLokal? capturedLaporan;

        when(mockStorage.uploadFotoKerusakan(
          filePath: anyNamed('filePath'),
          formulirId: anyNamed('formulirId'),
        )).thenThrow(Exception('Upload gagal: timeout'));

        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenAnswer((_) async {});

        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise — tidak boleh throw
        await expectLater(
          provider.updateLaporan(
            existing,
            namaSarana: 'Proyektor',
            keteranganKerusakan: 'Rusak',
            lokasiPerbaikan: 'Lab A',
            fotoLokalPath: '/foto.jpg',
          ),
          completes,
        );

        // Verify
        verify(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: null, // upload gagal → null
        )).called(1);

        // URL lama dipertahankan di lokal
        expect(capturedLaporan?.fotoKerusakanUrl, 'https://cdn/lama.jpg');
        expect(provider.errorMessage, isNull);
        expect(provider.isSubmitting, false);
      },
    );

    // TC-WB-09
    test(
      'TC-WB-09: uploadFotoKerusakan return null → newFotoUrl=null, fotoKerusakanUrl lokal pakai URL lama',
      () async {
        // Setup
        final existing = buatLaporan(
          isSynced: true,
          fotoKerusakanUrl: 'https://cdn/lama.jpg',
        );
        LaporanLokal? capturedLaporan;

        when(mockStorage.uploadFotoKerusakan(
          filePath: anyNamed('filePath'),
          formulirId: anyNamed('formulirId'),
        )).thenAnswer((_) async => null); // return null

        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenAnswer((_) async {});

        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'Laptop',
          keteranganKerusakan: 'Layar hitam',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: '/foto.jpg',
        );

        // Verify
        expect(capturedLaporan?.fotoKerusakanUrl, 'https://cdn/lama.jpg',
            reason: 'null return dari upload → pakai URL lama existing');
        expect(provider.isSubmitting, false);
        expect(provider.errorMessage, isNull);
      },
    );
  });

  // ============================================================================
  // CABANG 5 & 6: Remote / Lokal update gagal
  // ============================================================================
  group('TC-WB-10 s/d 11 | Exception dari remote / lokal', () {

    // TC-WB-10
    test(
      'TC-WB-10: updateLaporanRemote() throw → errorMessage terisi, exception di-rethrow, isSubmitting=false',
      () async {
        // Setup
        final existing = buatLaporan(isSynced: true);

        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenThrow(Exception('Network error'));

        // Exercise + Verify: exception harus di-rethrow
        await expectLater(
          provider.updateLaporan(
            existing,
            namaSarana: 'AC',
            keteranganKerusakan: 'Rusak',
            lokasiPerbaikan: 'Lab A',
            fotoLokalPath: null,
          ),
          throwsException,
        );

        expect(provider.errorMessage, 'Gagal memperbarui laporan.');
        expect(provider.isSubmitting, false);
      },
    );

    // TC-WB-11
    test(
      'TC-WB-11: _local.updateLaporan() throw (isSynced=false) → errorMessage terisi, syncInBackground TIDAK dipanggil',
      () async {
        // Setup
        final existing = buatLaporan(isSynced: false);

        when(mockLocal.updateLaporan(any))
            .thenThrow(Exception('Hive error: box closed'));

        // Exercise + Verify
        await expectLater(
          provider.updateLaporan(
            existing,
            namaSarana: 'Keyboard',
            keteranganKerusakan: 'Tombol copot',
            lokasiPerbaikan: 'Lab A',
            fotoLokalPath: null,
          ),
          throwsException,
        );

        expect(provider.errorMessage, 'Gagal memperbarui laporan.');
        expect(provider.isSubmitting, false);
        verifyNever(mockSync.syncUnsyncedData());
      },
    );
  });

  // ============================================================================
  // CABANG 7: State management
  // ============================================================================
  group('TC-WB-12 s/d 13 | State management', () {

    // TC-WB-12
    test(
      'TC-WB-12: isSubmitting = true saat proses, false setelah selesai (via finally), notifyListeners dipanggil',
      () async {
        // Setup
        final existing = buatLaporan(isSynced: false);
        final isSubmittingStates = <bool>[];

        provider.addListener(() {
          isSubmittingStates.add(provider.isSubmitting);
        });

        when(mockLocal.updateLaporan(any)).thenAnswer((_) async {});

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'Meja',
          keteranganKerusakan: 'Kaki patah',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
        );

        // Verify: state berubah true lalu false
        expect(isSubmittingStates, containsAllInOrder([true, false]),
            reason: 'isSubmitting harus true saat proses, false setelah selesai');
        expect(provider.isSubmitting, false);
      },
    );

    // TC-WB-13
    test(
      'TC-WB-13: errorMessage di-reset ke null di awal setiap pemanggilan (clear error lama)',
      () async {
        // Setup: inject error lama secara manual via clearError lalu set ulang
        final existing = buatLaporan(isSynced: false);

        // Paksa error lama ada dulu dengan simulasi call gagal
        when(mockLocal.updateLaporan(any))
            .thenThrow(Exception('Error lama'));
        try {
          await provider.updateLaporan(
            existing,
            namaSarana: 'X',
            keteranganKerusakan: 'X',
            lokasiPerbaikan: 'X',
            fotoLokalPath: null,
          );
        } catch (_) {}

        expect(provider.errorMessage, isNotNull,
            reason: 'Setelah error, errorMessage harus terisi');

        // Sekarang call baru dengan mock yang berhasil
        when(mockLocal.updateLaporan(any)).thenAnswer((_) async {});

        await provider.updateLaporan(
          existing,
          namaSarana: 'Meja Baru',
          keteranganKerusakan: 'Fixed',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
        );

        // Verify: errorMessage di-clear di awal call baru
        expect(provider.errorMessage, isNull,
            reason: 'errorMessage harus null setelah call berhasil berikutnya');
      },
    );
  });

  // ============================================================================
  // CABANG 8: copyWith & nomorInventaris
  // ============================================================================
  group('TC-WB-14 s/d 16 | copyWith & nomorInventaris', () {

    // TC-WB-14
    test(
      'TC-WB-14: nomorInventaris baru tersimpan di copyWith jika diberikan',
      () async {
        // Setup
        final existing = buatLaporan(
          isSynced: false,
          nomorInventaris: 'INV-001',
        );
        LaporanLokal? capturedLaporan;
        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'AC',
          keteranganKerusakan: 'Rusak',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
          nomorInventaris: 'INV-999',
        );

        // Verify
        expect(capturedLaporan?.nomorInventaris, 'INV-999');
      },
    );

    // TC-WB-15
    test(
      'TC-WB-15: nomorInventaris di-clear jika update dengan null (clearNomorInventaris=true)',
      () async {
        // Setup
        final existing = buatLaporan(
          isSynced: false,
          nomorInventaris: 'INV-001',
        );
        LaporanLokal? capturedLaporan;
        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'AC',
          keteranganKerusakan: 'Rusak',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
          nomorInventaris: null, // → clearNomorInventaris = true
        );

        // Verify
        expect(capturedLaporan?.nomorInventaris, isNull,
            reason: 'nomorInventaris harus null karena clearNomorInventaris=true');
      },
    );

    // TC-WB-16
    test(
      'TC-WB-16: updatedAt selalu diperbarui ke waktu terkini pada setiap update',
      () async {
        // Setup
        final waktuLama = DateTime(2024, 1, 1, 0, 0, 0);
        final existing = buatLaporan(isSynced: false);
        // existing.updatedAt = waktuLama (sudah di-set di constructor helper)

        LaporanLokal? capturedLaporan;
        final sebelumCall = DateTime.now();

        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'AC',
          keteranganKerusakan: 'Rusak',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
        );

        final setelahCall = DateTime.now();

        // Verify
        expect(capturedLaporan?.updatedAt, isNotNull);
        expect(
          capturedLaporan!.updatedAt.isAfter(waktuLama),
          true,
          reason: 'updatedAt harus lebih baru dari waktu lama',
        );
        expect(
          capturedLaporan!.updatedAt.isBefore(setelahCall) ||
              capturedLaporan!.updatedAt.isAtSameMomentAs(setelahCall),
          true,
          reason: 'updatedAt harus dalam range waktu test',
        );
        expect(
          capturedLaporan!.updatedAt.isAfter(sebelumCall) ||
              capturedLaporan!.updatedAt.isAtSameMomentAs(sebelumCall),
          true,
        );
      },
    );
  });

  // ============================================================================
  // CABANG 9: syncInBackground kondisional
  // ============================================================================
  group('TC-WB-17 | syncInBackground kondisional', () {

    // TC-WB-17
    test(
      'TC-WB-17: syncInBackground dipanggil hanya jika isSynced=false, TIDAK jika isSynced=true',
      () async {
        when(mockLocal.updateLaporan(any)).thenAnswer((_) async {});
        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenAnswer((_) async {});

        // Test A: isSynced = false → sync dipanggil
        final existingBelumSync = buatLaporan(isSynced: false);
        await provider.updateLaporan(
          existingBelumSync,
          namaSarana: 'AC',
          keteranganKerusakan: 'Rusak',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
        );
        verify(mockSync.syncUnsyncedData()).called(1);

        // Test B: isSynced = true → sync TIDAK dipanggil
        final existingSudahSync = buatLaporan(isSynced: true);
        await provider.updateLaporan(
          existingSudahSync,
          namaSarana: 'Monitor',
          keteranganKerusakan: 'Retak',
          lokasiPerbaikan: 'Lab B',
          fotoLokalPath: null,
        );
        // Setelah test B, total sync call masih 1 (tidak bertambah)
        verifyNever(mockSync.syncUnsyncedData());
      },
    );
  });

  // ============================================================================
  // CABANG 10: Edge cases & konsistensi data
  // ============================================================================
  group('TC-WB-18 s/d 20 | Edge cases', () {

    // TC-WB-18
    test(
      'TC-WB-18: Update dengan data identik → tetap berhasil, lokal tetap dipanggil, updatedAt diperbarui',
      () async {
        // Setup: existing dengan data tertentu
        final existing = buatLaporan(
          isSynced: false,
          namaSarana: 'Proyektor',
          keteranganKerusakan: 'Tidak menyala',
          lokasiPerbaikan: 'Lab A',
        );
        when(mockLocal.updateLaporan(any)).thenAnswer((_) async {});

        // Exercise: update dengan nilai yang sama persis
        await provider.updateLaporan(
          existing,
          namaSarana: 'Proyektor',
          keteranganKerusakan: 'Tidak menyala',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
        );

        // Verify: tetap berhasil, tidak ada error
        verify(mockLocal.updateLaporan(any)).called(1);
        verify(mockSync.syncUnsyncedData()).called(1);
        expect(provider.errorMessage, isNull);
        expect(provider.isSubmitting, false);
      },
    );

    // TC-WB-19
    test(
      'TC-WB-19: isSynced=true setelah update → isSynced tetap true di copyWith',
      () async {
        // Setup
        final existing = buatLaporan(isSynced: true);
        LaporanLokal? capturedLaporan;

        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenAnswer((_) async {});

        when(mockLocal.updateLaporan(any)).thenAnswer((inv) async {
          capturedLaporan = inv.positionalArguments[0] as LaporanLokal;
        });

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'Switch',
          keteranganKerusakan: 'Port mati',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: null,
        );

        // Verify
        expect(capturedLaporan?.isSynced, true,
            reason: 'isSynced harus tetap true untuk laporan yang sudah sync');
      },
    );

    // TC-WB-20
    test(
      'TC-WB-20: formulirId existing dipakai untuk upload foto (bukan UUID baru)',
      () async {
        // Setup
        final existing = buatLaporan(
          formulirId: 'F-020-SPECIFIC-UUID',
          isSynced: true,
        );

        String? capturedFormulirId;
        String? capturedFilePath;

        when(mockStorage.uploadFotoKerusakan(
          filePath: anyNamed('filePath'),
          formulirId: anyNamed('formulirId'),
        )).thenAnswer((inv) async {
          capturedFormulirId =
              inv.namedArguments[const Symbol('formulirId')] as String?;
          capturedFilePath =
              inv.namedArguments[const Symbol('filePath')] as String?;
          return 'https://cdn/foto-baru.jpg';
        });

        when(mockRemote.updateLaporanRemote(
          formulirId: anyNamed('formulirId'),
          namaSarana: anyNamed('namaSarana'),
          keteranganKerusakan: anyNamed('keteranganKerusakan'),
          namaRuangan: anyNamed('namaRuangan'),
          nomorInventaris: anyNamed('nomorInventaris'),
          fotoUrl: anyNamed('fotoUrl'),
        )).thenAnswer((_) async {});

        when(mockLocal.updateLaporan(any)).thenAnswer((_) async {});

        // Exercise
        await provider.updateLaporan(
          existing,
          namaSarana: 'Laptop',
          keteranganKerusakan: 'Layar retak',
          lokasiPerbaikan: 'Lab A',
          fotoLokalPath: '/foto.jpg',
        );

        // Verify: formulirId yang dipakai untuk upload = existing.formulirId
        expect(capturedFormulirId, 'F-020-SPECIFIC-UUID',
            reason: 'Harus pakai formulirId existing, bukan UUID baru');
        expect(capturedFilePath, '/foto.jpg');
      },
    );
  });
}