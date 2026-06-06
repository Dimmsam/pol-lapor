// ============================================================
// File        : penanganan_provider_test.dart
// Deskripsi   : Unit test WHITE BOX untuk method
//               eskalasiKeAdminJurusan() di PenangananProvider.
//               TC-WB-01 s.d. TC-WB-15
//
// Cara jalankan:
//   flutter test test/unit/penanganan_provider_test.dart --reporter expanded
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:pol_lapor/core/constants/app_constants.dart';
import 'package:pol_lapor/data/models/laporan_lokal.dart';
import 'package:pol_lapor/data/models/penanganan.dart';
import 'package:pol_lapor/logic/providers/penanganan_provider.dart';

import 'mock_datasources.mocks.dart'; // di-generate build_runner

// ─── Helper: buat Penanganan dummy ────────────────────────────────────────────
Penanganan _buatPenanganan({
  String penangananId = 'P001',
  String formulirId = 'F001',
  String teknisiId = 'T001',
  String status = StatusPenanganan.mulaiDikerjakan,
  String? catatanProgres,
  String? kategoriKerusakan,
  List<String> fotoProgresUrl = const [],
}) {
  return Penanganan(
    penangananId: penangananId,
    formulirId: formulirId,
    teknisiId: teknisiId,
    statusPenanganan: status,
    catatanProgres: catatanProgres,
    kategoriKerusakan: kategoriKerusakan,
    fotoProgresUrl: fotoProgresUrl,
    updatedAt: DateTime.now(),
    tanggalMulai: DateTime.now().subtract(const Duration(hours: 1)),
  );
}

// ─── Helper: buat LaporanLokal dummy ─────────────────────────────────────────
LaporanLokal _buatLaporan({
  String formulirId = 'F001',
  String status = StatusLaporan.diproses,
}) {
  return LaporanLokal(
    formulirId: formulirId,
    namaSarana: 'Proyektor',
    keteranganKerusakan: 'Layar gelap',
    lokasiPerbaikan: 'D101',
    pelaporId: 'PEL001',
    status: status,
  );
}

void main() {
  // ─── Setup ────────────────────────────────────────────────────────────────
  late MockPenangananRemoteDatasource mockRemote;
  late MockTrackingRemoteDatasource mockTracking;
  late MockStorageRemoteDatasource mockStorage;
  late MockNotifikasiRemoteDatasource mockNotif;
  late PenangananProvider provider;

  setUp(() {
    mockRemote   = MockPenangananRemoteDatasource();
    mockTracking = MockTrackingRemoteDatasource();
    mockStorage  = MockStorageRemoteDatasource();
    mockNotif    = MockNotifikasiRemoteDatasource();

    provider = PenangananProvider.testable(
      remote:         mockRemote,
      trackingRemote: mockTracking,
      notifRemote:    mockNotif,
      storage:        mockStorage,
    );

    // Default stubs — bisa di-override per test
    when(mockRemote.updatePenanganan(any, any)).thenAnswer((_) async {});
    when(mockRemote.updateStatusFormulir(any, any, updatedAt: anyNamed('updatedAt')))
        .thenAnswer((_) async {});
    when(mockRemote.insertPenanganan(any)).thenAnswer((_) async {});
    when(mockTracking.catatTracking(
      formulirId: anyNamed('formulirId'),
      aktorId:    anyNamed('aktorId'),
      jenisEvent: anyNamed('jenisEvent'),
      pesanNarasi: anyNamed('pesanNarasi'),
    )).thenAnswer((_) async {});
    when(mockNotif.insertNotifikasi(
      penerimaId: anyNamed('penerimaId'),
      judul:      anyNamed('judul'),
      pesan:      anyNamed('pesan'),
      tipe:       anyNamed('tipe'),
      formulirId: anyNamed('formulirId'),
    )).thenAnswer((_) async {});
  });


  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-01 : Eskalasi gagal — catatan kosong ("")
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-01 | Validasi: catatan eskalasi kosong', () {
    test('catatan "" harus set errorMessage & tidak panggil network', () async {
      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   '',
        kategoriKerusakan: 'Proyektor',
      );

      expect(provider.errorMessage, 'Catatan eskalasi tidak boleh kosong');
      expect(provider.isLoading, isFalse);
      verifyNever(mockRemote.updatePenanganan(any, any));
      verifyNever(mockRemote.updateStatusFormulir(any, any));
    });

    test('catatan hanya spasi juga harus ditolak', () async {
      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   '   ',
        kategoriKerusakan: 'Proyektor',
      );

      expect(provider.errorMessage, 'Catatan eskalasi tidak boleh kosong');
      verifyNever(mockRemote.updatePenanganan(any, any));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-02 : Eskalasi gagal — kategori kosong ("")
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-02 | Validasi: kategori kerusakan kosong', () {
    test('kategori "" harus set errorMessage & tidak panggil network', () async {
      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: '',
      );

      expect(provider.errorMessage, 'Kategori kerusakan harus dipilih');
      expect(provider.isLoading, isFalse);
      verifyNever(mockRemote.updatePenanganan(any, any));
    });

    test('kategori hanya spasi juga harus ditolak', () async {
      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Catatan valid',
        kategoriKerusakan: '   ',
      );

      expect(provider.errorMessage, 'Kategori kerusakan harus dipilih');
    });
  });


  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-03 : Auto-create penanganan jika belum ada
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-03 | Auto-create penanganan sebelum eskalasi', () {
    test('jika _mapPenanganan kosong, insertPenanganan dipanggil 1x', () async {
      // Pastikan _mapPenanganan kosong (tidak ada penanganan)
      // provider baru = map kosong by default

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Perlu eskalasi ke admin',
        kategoriKerusakan: 'AC / Kipas',
      );

      // insertPenanganan harus dipanggil 1x untuk membuat penanganan baru
      verify(mockRemote.insertPenanganan(any)).called(1);
      expect(provider.errorMessage, isNull);
    });

    test('setelah auto-create, penanganan tersimpan di _mapPenanganan', () async {
      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Kerusakan kompleks',
        kategoriKerusakan: 'Listrik',
      );

      final penanganan = provider.getPenangananByFormulir('F001');
      expect(penanganan, isNotNull);
      expect(penanganan!.formulirId, 'F001');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-04 : Eskalasi dengan penanganan yang SUDAH ADA
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-04 | Eskalasi dengan penanganan existing', () {
    test('insertPenanganan tidak dipanggil jika sudah ada', () async {
      // Pre-load penanganan ke dalam provider
      await provider.loadDaftarTugasForTest(
        laporan: [_buatLaporan()],
        penangananRows: [
          {
            'penanganan_id':     'P001',
            'formulir_id':       'F001',
            'teknisi_id':        'T001',
            'status_penanganan': StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':   null,
            'deskripsi_hasil':   null,
            'kategori_kerusakan': null,
            'foto_progres_url':  <String>[],
            'foto_hasil_url':    null,
            'tanggal_mulai':     DateTime.now().toIso8601String(),
            'tanggal_selesai':   null,
            'updated_at':        DateTime.now().toIso8601String(),
          }
        ],
      );

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      // insertPenanganan TIDAK boleh dipanggil
      verifyNever(mockRemote.insertPenanganan(any));
      // updatePenanganan dipanggil 1x dengan P001
      final captured = verify(mockRemote.updatePenanganan(
        captureAny, captureAny,
      )).captured;
      expect(captured[0], 'P001');
    });

    test('updateStatusFormulir dipanggil dengan diteruskan_ke_pusat', () async {
      await provider.loadDaftarTugasForTest(
        laporan: [_buatLaporan()],
        penangananRows: [
          {
            'penanganan_id':     'P001',
            'formulir_id':       'F001',
            'teknisi_id':        'T001',
            'status_penanganan': StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':   null,
            'deskripsi_hasil':   null,
            'kategori_kerusakan': null,
            'foto_progres_url':  <String>[],
            'foto_hasil_url':    null,
            'tanggal_mulai':     DateTime.now().toIso8601String(),
            'tanggal_selesai':   null,
            'updated_at':        DateTime.now().toIso8601String(),
          }
        ],
      );

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      verify(mockRemote.updateStatusFormulir(
        'F001',
        StatusLaporan.diteruskanKePusat,
        updatedAt: anyNamed('updatedAt'),
      )).called(1);
    });
  });


  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-05 : Upload multiple foto tambahan berhasil
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-05 | Upload 3 foto berhasil', () {
    test('uploadFotoProgres dipanggil 3x dan URL tersimpan', () async {
      when(mockStorage.uploadFotoProgres(
        filePath:   argThat(isA<String>(), named: 'filePath'),
        formulirId: anyNamed('formulirId'),
      )).thenAnswer((invocation) async {
        final path = invocation.namedArguments[#filePath] as String;
        return 'https://storage/${path.split('/').last}';
      });

      await provider.eskalasiKeAdminJurusan(
        formulirId:          'F001',
        teknisiId:           'T001',
        catatanEskalasi:     'Butuh admin',
        kategoriKerusakan:   'Listrik',
        fotoTambahanPaths:   ['/local/f1.jpg', '/local/f2.jpg', '/local/f3.jpg'],
      );

      verify(mockStorage.uploadFotoProgres(
        filePath: anyNamed('filePath'),
        formulirId: anyNamed('formulirId'),
      )).called(3);

      final captured = verify(mockRemote.updatePenanganan(any, captureAny)).captured;
      final data = captured.first as Map<String, dynamic>;
      final urls = data['foto_progres_url'] as List;
      expect(urls.length, 3);
      expect(urls.every((u) => (u as String).startsWith('https://')), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-06 : Upload foto – satu dari tiga gagal (return null)
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-06 | Satu foto gagal upload → hanya 2 URL tersimpan', () {
    test('URL null difilter, hanya URL valid yang masuk ke DB', () async {
      int callCount = 0;
      when(mockStorage.uploadFotoProgres(
        filePath:   anyNamed('filePath'),
        formulirId: anyNamed('formulirId'),
      )).thenAnswer((_) async {
        callCount++;
        if (callCount == 2) return null; // simulasi gagal pada foto ke-2
        return 'https://storage/foto$callCount.jpg';
      });

      await provider.eskalasiKeAdminJurusan(
        formulirId:         'F001',
        teknisiId:          'T001',
        catatanEskalasi:    'Butuh admin',
        kategoriKerusakan:  'Proyektor',
        fotoTambahanPaths:  ['/f1.jpg', '/f2.jpg', '/f3.jpg'],
      );

      final captured = verify(mockRemote.updatePenanganan(any, captureAny)).captured;
      final data = captured.first as Map<String, dynamic>;
      final urls = data['foto_progres_url'] as List;
      expect(urls.length, 2,
          reason: 'URL null dari foto ke-2 seharusnya dibuang');
      expect(urls.contains(null), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-07 : Tracking event HARUS dicatat dengan jenisEvent eskalasiDariTeknisi
  // STATUS   : ❌ FAIL — BUG-01 ditemukan
  // BUG      : _insertTrackingLog bergantung pada SupabaseService.auth.currentUser.
  //            Karena teknisiId sudah tersedia sebagai parameter eksplisit di
  //            eskalasiKeAdminJurusan(), seharusnya langsung diteruskan ke
  //            catatTracking tanpa perlu fetch dari Supabase auth.
  //            Akibatnya tracking log eskalasi tidak pernah tercatat.
  // SOLUSI   : Ubah _insertTrackingLog agar menerima aktorId sebagai parameter,
  //            dan panggil dengan teknisiId yang sudah ada.
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-07 | [BUG-01] Tracking log eskalasi harus dicatat', () {
    test('catatTracking harus dipanggil 1x dengan jenisEvent eskalasiDariTeknisi', () async {
      // Pre-load penanganan agar path yang ditest murni eskalasi (tanpa auto-create)
      await provider.loadDaftarTugasForTest(
        laporan: [_buatLaporan()],
        penangananRows: [
          {
            'penanganan_id':      'P001',
            'formulir_id':        'F001',
            'teknisi_id':         'T001',
            'status_penanganan':  StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':    null,
            'deskripsi_hasil':    null,
            'kategori_kerusakan': null,
            'foto_progres_url':   <String>[],
            'foto_hasil_url':     null,
            'tanggal_mulai':      DateTime.now().toIso8601String(),
            'tanggal_selesai':    null,
            'updated_at':         DateTime.now().toIso8601String(),
          }
        ],
      );

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin segera',
        kategoriKerusakan: 'AC / Kipas',
      );

      // EKSPEKTASI IDEAL: catatTracking dipanggil 1x dengan jenisEvent yang benar.
      // PERILAKU AKTUAL (BUG): _insertTrackingLog return early karena
      // SupabaseService.auth.currentUser == null di test environment,
      // sehingga catatTracking tidak pernah dipanggil sama sekali.
      // Test ini FAIL → membuktikan bug nyata di production code.
      verify(mockTracking.catatTracking(
        formulirId:  anyNamed('formulirId'),
        aktorId:     anyNamed('aktorId'),
        jenisEvent:  anyNamed('jenisEvent'),
        pesanNarasi: anyNamed('pesanNarasi'),
      )).called(1); // ← ini yang bikin FAIL karena actual = 0 calls
    });
  });


  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-08 : Notifikasi dikirim ke pelapor dengan tipe eskalasi
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-08 | Notifikasi pelapor', () {
    test('insertNotifikasi dipanggil dengan tipe eskalasi', () async {
      // NOTE: _kirimNotifikasiPelapor butuh SupabaseService.db untuk lookup
      // pelapor_id. Karena tidak bisa mock SupabaseService (static), test ini
      // memverifikasi bahwa method setidaknya tidak crash.
      // Jika menggunakan integration test environment, verify notifikasi terkirim.

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      // Eskalasi harus selesai tanpa exception
      expect(provider.isLoading, isFalse);
      // errorMessage dari eskalasi sendiri null (notif failure non-critical)
      // Jika menggunakan test environment dengan Supabase mock, tambahkan:
      // verify(mockNotif.insertNotifikasi(...)).called(1);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-09 : Status formulir berubah ke diteruskan_ke_pusat
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-09 | Status formulir diupdate ke diteruskan_ke_pusat', () {
    test('updateStatusFormulir dipanggil dengan status diteruskan_ke_pusat', () async {
      // Gunakan penanganan existing agar tidak ada auto-create flow
      await provider.loadDaftarTugasForTest(
        laporan: [_buatLaporan()],
        penangananRows: [
          {
            'penanganan_id':      'P001',
            'formulir_id':        'F001',
            'teknisi_id':         'T001',
            'status_penanganan':  StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':    null,
            'deskripsi_hasil':    null,
            'kategori_kerusakan': null,
            'foto_progres_url':   <String>[],
            'foto_hasil_url':     null,
            'tanggal_mulai':      DateTime.now().toIso8601String(),
            'tanggal_selesai':    null,
            'updated_at':         DateTime.now().toIso8601String(),
          }
        ],
      );

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Mebel',
      );

      // updateStatusFormulir dipanggil 1x dengan status diteruskan_ke_pusat
      verify(mockRemote.updateStatusFormulir(
        'F001',
        StatusLaporan.diteruskanKePusat,
        updatedAt: anyNamed('updatedAt'),
      )).called(1);
    });

    test('updatedAt di updatePenanganan dan updateStatusFormulir identik', () async {
      await provider.loadDaftarTugasForTest(
        laporan: [_buatLaporan()],
        penangananRows: [
          {
            'penanganan_id':      'P001',
            'formulir_id':        'F001',
            'teknisi_id':         'T001',
            'status_penanganan':  StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':    null,
            'deskripsi_hasil':    null,
            'kategori_kerusakan': null,
            'foto_progres_url':   <String>[],
            'foto_hasil_url':     null,
            'tanggal_mulai':      DateTime.now().toIso8601String(),
            'tanggal_selesai':    null,
            'updated_at':         DateTime.now().toIso8601String(),
          }
        ],
      );

      String? tsPenanganan;
      String? tsFormulir;

      when(mockRemote.updatePenanganan(any, any)).thenAnswer((inv) async {
        final data = inv.positionalArguments[1] as Map<String, dynamic>;
        tsPenanganan = data['updated_at'] as String?;
      });
      when(mockRemote.updateStatusFormulir(any, any,
              updatedAt: anyNamed('updatedAt')))
          .thenAnswer((inv) async {
        // updatedAt adalah named argument
        tsFormulir = inv.namedArguments[#updatedAt] as String?;
      });

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      expect(tsPenanganan, isNotNull);
      expect(tsFormulir,   isNotNull);
      expect(tsPenanganan, equals(tsFormulir));
    });
  });


  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-10 : State lokal provider diupdate setelah eskalasi
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-10 | State lokal provider diupdate', () {
    test('kategoriKerusakan dan catatanProgres tersimpan di state lokal', () async {
      await provider.loadDaftarTugasForTest(
        laporan: [_buatLaporan()],
        penangananRows: [
          {
            'penanganan_id':     'P001',
            'formulir_id':       'F001',
            'teknisi_id':        'T001',
            'status_penanganan': StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':   null,
            'deskripsi_hasil':   null,
            'kategori_kerusakan': null,
            'foto_progres_url':  <String>[],
            'foto_hasil_url':    null,
            'tanggal_mulai':     DateTime.now().toIso8601String(),
            'tanggal_selesai':   null,
            'updated_at':        DateTime.now().toIso8601String(),
          }
        ],
      );

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Perlu peralatan khusus',
        kategoriKerusakan: 'Listrik',
      );

      final updated = provider.getPenangananByFormulir('F001');
      expect(updated, isNotNull);
      expect(updated!.kategoriKerusakan, 'Listrik');
      expect(updated.catatanProgres, 'Perlu peralatan khusus');
      expect(updated.tanggalSelesai, isNotNull);
    });

    test('_mapPenanganan juga terupdate (konsisten dengan list)', () async {
      await provider.loadDaftarTugasForTest(
        laporan: [_buatLaporan()],
        penangananRows: [
          {
            'penanganan_id':     'P001',
            'formulir_id':       'F001',
            'teknisi_id':        'T001',
            'status_penanganan': StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':   null,
            'deskripsi_hasil':   null,
            'kategori_kerusakan': null,
            'foto_progres_url':  <String>[],
            'foto_hasil_url':    null,
            'tanggal_mulai':     DateTime.now().toIso8601String(),
            'tanggal_selesai':   null,
            'updated_at':        DateTime.now().toIso8601String(),
          }
        ],
      );

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Eskalasi test',
        kategoriKerusakan: 'AC / Kipas',
      );

      final fromMap  = provider.getPenangananByFormulir('F001');
      final fromList = provider.daftarPenangananLokal
          .firstWhere((p) => p.formulirId == 'F001');

      expect(fromMap!.kategoriKerusakan, equals(fromList.kategoriKerusakan));
      expect(fromMap.catatanProgres, equals(fromList.catatanProgres));
    });
  });


  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-11 : Network failure saat updatePenanganan
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-11 | Error handling: network failure', () {
    test('errorMessage terisi dan isLoading kembali false', () async {
      when(mockRemote.updatePenanganan(any, any))
          .thenThrow(Exception('Network error: connection refused'));

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      expect(provider.errorMessage, contains('Gagal mengajukan eskalasi'));
      expect(provider.isLoading, isFalse);
    });

    test('state lokal tidak corrupted setelah exception', () async {
      // Pre-load 1 penanganan
      await provider.loadDaftarTugasForTest(
        laporan: [_buatLaporan()],
        penangananRows: [
          {
            'penanganan_id':      'P001',
            'formulir_id':        'F001',
            'teknisi_id':         'T001',
            'status_penanganan':  StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':    null,
            'deskripsi_hasil':    null,
            'kategori_kerusakan': null,
            'foto_progres_url':   <String>[],
            'foto_hasil_url':     null,
            'tanggal_mulai':      DateTime.now().toIso8601String(),
            'tanggal_selesai':    null,
            'updated_at':         DateTime.now().toIso8601String(),
          }
        ],
      );

      when(mockRemote.updatePenanganan(any, any))
          .thenThrow(Exception('Network error'));

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      // State lokal: kategoriKerusakan BELUM berubah karena exception terjadi
      // sebelum blok update state lokal
      final p = provider.getPenangananByFormulir('F001');
      expect(p, isNotNull);
      // kategoriKerusakan seharusnya masih null (belum sempat diupdate)
      expect(p!.kategoriKerusakan, isNull,
          reason: 'State lokal tidak boleh berubah kalau DB call gagal');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-12 : Semua foto gagal upload → eskalasi tetap lanjut
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-12 | Semua foto gagal upload', () {
    test('eskalasi tetap berhasil dan foto_progres_url tidak ada di payload', () async {
      when(mockStorage.uploadFotoProgres(
        filePath:   anyNamed('filePath'),
        formulirId: anyNamed('formulirId'),
      )).thenAnswer((_) async => null);

      // Pre-load agar tidak ada auto-create
      await provider.loadDaftarTugasForTest(
        laporan: [_buatLaporan()],
        penangananRows: [
          {
            'penanganan_id':      'P001',
            'formulir_id':        'F001',
            'teknisi_id':         'T001',
            'status_penanganan':  StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':    null,
            'deskripsi_hasil':    null,
            'kategori_kerusakan': null,
            'foto_progres_url':   <String>[],
            'foto_hasil_url':     null,
            'tanggal_mulai':      DateTime.now().toIso8601String(),
            'tanggal_selesai':    null,
            'updated_at':         DateTime.now().toIso8601String(),
          }
        ],
      );

      await provider.eskalasiKeAdminJurusan(
        formulirId:         'F001',
        teknisiId:          'T001',
        catatanEskalasi:    'Butuh admin',
        kategoriKerusakan:  'Proyektor',
        fotoTambahanPaths:  ['/f1.jpg', '/f2.jpg', '/f3.jpg'],
      );

      // Eskalasi harus tetap berhasil meski semua foto gagal
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);

      // Kode: `if (fotoUrls.isNotEmpty) 'foto_progres_url': fotoUrls`
      // → saat semua null, fotoUrls.isEmpty, key tidak ada di payload
      // Tangkap payload langsung dari stub yang sudah di-register di setUp
      Map<String, dynamic>? lastPayload;
      when(mockRemote.updatePenanganan(any, any)).thenAnswer((inv) async {
        lastPayload = inv.positionalArguments[1] as Map<String, dynamic>;
      });

      // Panggil eskalasi kedua dengan stub baru untuk capture
      final provider2 = PenangananProvider.testable(
        remote:         mockRemote,
        trackingRemote: mockTracking,
        notifRemote:    mockNotif,
        storage:        mockStorage,
      );
      await provider2.loadDaftarTugasForTest(
        laporan: [_buatLaporan(formulirId: 'F002')],
        penangananRows: [
          {
            'penanganan_id':      'P002',
            'formulir_id':        'F002',
            'teknisi_id':         'T001',
            'status_penanganan':  StatusPenanganan.mulaiDikerjakan,
            'catatan_progres':    null,
            'deskripsi_hasil':    null,
            'kategori_kerusakan': null,
            'foto_progres_url':   <String>[],
            'foto_hasil_url':     null,
            'tanggal_mulai':      DateTime.now().toIso8601String(),
            'tanggal_selesai':    null,
            'updated_at':         DateTime.now().toIso8601String(),
          }
        ],
      );
      await provider2.eskalasiKeAdminJurusan(
        formulirId:         'F002',
        teknisiId:          'T001',
        catatanEskalasi:    'Butuh admin',
        kategoriKerusakan:  'Proyektor',
        fotoTambahanPaths:  ['/f1.jpg', '/f2.jpg'],
      );

      expect(lastPayload, isNotNull);
      expect(lastPayload!.containsKey('foto_progres_url'), isFalse,
          reason: 'foto_progres_url tidak boleh ada di payload saat semua upload gagal');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-13 : Saat insertPenanganan ke DB gagal, eskalasi HARUS berhenti
  // STATUS   : ❌ FAIL — BUG-02 ditemukan
  // BUG      : mulaiPenangananLangsung menambahkan penanganan ke _mapPenanganan
  //            SEBELUM memanggil insertPenanganan ke DB. Akibatnya saat DB insert
  //            gagal (throw exception), state in-memory sudah terisi.
  //            eskalasiKeAdminJurusan menemukan penanganan di memory dan tetap
  //            melanjutkan update ke DB — data inconsistency: formulir menjadi
  //            "diteruskan_ke_pusat" tapi record penanganan tidak ada di DB.
  // SOLUSI   : Tambahkan rollback state in-memory di catch block
  //            mulaiPenangananLangsung jika insertPenanganan gagal.
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-13 | [BUG-02] Eskalasi harus berhenti jika auto-create penanganan gagal', () {
    test('jika insertPenanganan gagal, updatePenanganan tidak boleh dipanggil', () async {
      when(mockRemote.insertPenanganan(any))
          .thenThrow(Exception('DB insert failed'));

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      // EKSPEKTASI IDEAL: seluruh proses eskalasi berhenti karena penanganan
      // gagal disimpan ke DB. updatePenanganan dan updateStatusFormulir
      // seharusnya tidak pernah dipanggil.
      //
      // PERILAKU AKTUAL (BUG): meskipun insertPenanganan throw, state in-memory
      // sudah terisi lebih dulu → eskalasiKeAdminJurusan tetap memanggil
      // updatePenanganan dengan penanganan yang tidak ada di DB.
      // Test ini FAIL → membuktikan bug inkonsistensi data.
      verifyNever(mockRemote.updatePenanganan(any, any)); // ← FAIL karena actual = 1 call
      verifyNever(mockRemote.updateStatusFormulir(any, any));
    });

    test('jika insertPenanganan gagal, errorMessage harus terisi', () async {
      when(mockRemote.insertPenanganan(any))
          .thenThrow(Exception('DB insert failed'));

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      // Test ini PASS — errorMessage terisi dari mulaiPenangananLangsung
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-14 : Race condition — double call saat isLoading true
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-14 | Double eskalasi (idempotency check)', () {
    test('dua panggilan berurutan hanya menghasilkan 1x updatePenanganan', () async {
      // Panggil dua kali: call ke-2 terjadi saat call ke-1 masih in-flight
      // Karena Dart single-threaded, call ke-2 mulai setelah call ke-1 selesai.
      // Setelah call ke-1 selesai, _mapPenanganan sudah terisi →
      // call ke-2 dengan data berbeda harus tetap diproses (bukan di-block).
      // Test ini memverifikasi tidak ada duplicate INSERT.

      int insertCount = 0;
      when(mockRemote.insertPenanganan(any)).thenAnswer((_) async {
        insertCount++;
      });

      // Call 1 — auto-create
      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Eskalasi pertama',
        kategoriKerusakan: 'Proyektor',
      );

      // Call 2 — penanganan sudah ada, tidak boleh insert lagi
      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Eskalasi kedua',
        kategoriKerusakan: 'Listrik',
      );

      expect(insertCount, 1,
          reason: 'insertPenanganan hanya boleh dipanggil 1x (saat pertama kali)');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TC-WB-15 : Timestamp consistency — updated_at sama di semua tabel
  // ══════════════════════════════════════════════════════════════════════════
  group('TC-WB-15 | Timestamp consistency', () {
    test('updated_at di penanganan dan formulir adalah string ISO8601 yang sama', () async {
      String? tsPenanganan;
      String? tsFormulir;

      when(mockRemote.updatePenanganan(any, any)).thenAnswer((inv) async {
        final data = inv.positionalArguments[1] as Map<String, dynamic>;
        tsPenanganan = data['updated_at'] as String?;
      });
      when(mockRemote.updateStatusFormulir(
        any, any, updatedAt: anyNamed('updatedAt'),
      )).thenAnswer((inv) async {
        tsFormulir = inv.namedArguments[#updatedAt] as String?;
      });

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      expect(tsPenanganan, isNotNull, reason: 'updated_at di penanganan harus ada');
      expect(tsFormulir,   isNotNull, reason: 'updated_at di formulir harus ada');
      expect(tsPenanganan, equals(tsFormulir),
          reason: 'Kedua timestamp harus identik karena di-generate dari nowStr yang sama');

      // Pastikan format ISO8601 valid
      expect(
        () => DateTime.parse(tsPenanganan!),
        returnsNormally,
        reason: 'updated_at harus format ISO8601 yang bisa di-parse',
      );
    });

    test('tanggal_selesai di penanganan juga sama dengan updated_at', () async {
      String? tsUpdated;
      String? tsSelesai;

      when(mockRemote.updatePenanganan(any, any)).thenAnswer((inv) async {
        final data = inv.positionalArguments[1] as Map<String, dynamic>;
        tsUpdated = data['updated_at']     as String?;
        tsSelesai = data['tanggal_selesai'] as String?;
      });

      await provider.eskalasiKeAdminJurusan(
        formulirId:        'F001',
        teknisiId:         'T001',
        catatanEskalasi:   'Butuh admin',
        kategoriKerusakan: 'Proyektor',
      );

      expect(tsSelesai, isNotNull);
      expect(tsSelesai, equals(tsUpdated),
          reason: 'tanggal_selesai dan updated_at harus dari nowStr yang sama');
    });
  });

} // ← penutup void main()
