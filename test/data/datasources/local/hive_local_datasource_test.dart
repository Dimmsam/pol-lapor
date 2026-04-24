import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pol_lapor/core/constants/app_constants.dart';
import 'package:pol_lapor/data/datasources/local/hive_local_datasource.dart';
import 'package:pol_lapor/data/models/laporan_lokal.dart';

void main() {
  late HiveLocalDatasource datasource;

  // ── helper buat dummy laporan ─────────────────────────────────────────────
  LaporanLokal makeLaporan({
    String id = 'laporan-001',
    String judul = 'AC rusak di kelas',
    String status = AppConstants.statusMenunggu,
    bool isSynced = false,
    DateTime? createdAt,
  }) {
    return LaporanLokal(
      laporanId: id,
      judul: judul,
      deskripsi: 'Deskripsi kerusakan',
      kategori: 'AC / Kipas',
      lokasi: 'Gedung A Lt 2',
      pelaporId: 'user-123',
      status: status,
      isSynced: isSynced,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('hive_laporan_test_');
    Hive.init(dir.path);
    Hive.registerAdapter(LaporanLokalAdapter());
    await Hive.openBox<LaporanLokal>(AppConstants.boxLaporan);
  });

  setUp(() {
    datasource = HiveLocalDatasource();
  });

  tearDown(() async {
    await Hive.box<LaporanLokal>(AppConstants.boxLaporan).clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  // ── TC-01 ─────────────────────────────────────────────────────────────────
  test('TC-01: saveLaporan() menyimpan laporan dan bisa dibaca kembali', () async {
    final laporan = makeLaporan();
    await datasource.saveLaporan(laporan);

    final result = datasource.getLaporanById('laporan-001');

    expect(result, isNotNull);
    expect(result!.laporanId, equals('laporan-001'));
    expect(result.judul, equals('AC rusak di kelas'));
    expect(result.isSynced, isFalse);
  });

  // ── TC-02 ─────────────────────────────────────────────────────────────────
  test('TC-02: getAllLaporan() return list sorted createdAt DESC', () async {
    final lama = makeLaporan(
      id: 'laporan-001',
      createdAt: DateTime(2025, 1, 1),
    );
    final baru = makeLaporan(
      id: 'laporan-002',
      createdAt: DateTime(2025, 6, 1),
    );

    await datasource.saveLaporan(lama);
    await datasource.saveLaporan(baru);

    final result = datasource.getAllLaporan();

    expect(result.length, equals(2));
    expect(result.first.laporanId, equals('laporan-002')); // terbaru di atas
    expect(result.last.laporanId, equals('laporan-001'));
  });

  // ── TC-03 ─────────────────────────────────────────────────────────────────
  test('TC-03: getAllLaporan() return empty list saat box kosong', () {
    final result = datasource.getAllLaporan();
    expect(result, isEmpty);
  });

  // ── TC-04 ─────────────────────────────────────────────────────────────────
  test('TC-04: getUnsyncedLaporan() hanya return laporan dengan isSynced=false', () async {
    await datasource.saveLaporan(makeLaporan(id: 'a', isSynced: false));
    await datasource.saveLaporan(makeLaporan(id: 'b', isSynced: true));
    await datasource.saveLaporan(makeLaporan(id: 'c', isSynced: false));

    final result = datasource.getUnsyncedLaporan();

    expect(result.length, equals(2));
    expect(result.every((l) => !l.isSynced), isTrue);
  });

  // ── TC-05 ─────────────────────────────────────────────────────────────────
  test('TC-05: getUnsyncedLaporan() return empty jika semua sudah synced', () async {
    await datasource.saveLaporan(makeLaporan(id: 'a', isSynced: true));
    await datasource.saveLaporan(makeLaporan(id: 'b', isSynced: true));

    final result = datasource.getUnsyncedLaporan();

    expect(result, isEmpty);
  });

  // ── TC-06 ─────────────────────────────────────────────────────────────────
  test('TC-06: markAsSynced() mengubah isSynced=true dan mengisi fotoCloudUrl', () async {
    await datasource.saveLaporan(makeLaporan(id: 'laporan-001'));

    await datasource.markAsSynced(
      'laporan-001',
      'https://res.cloudinary.com/foto123.jpg',
    );

    final result = datasource.getLaporanById('laporan-001');
    expect(result!.isSynced, isTrue);
    expect(result.fotoCloudUrl, equals('https://res.cloudinary.com/foto123.jpg'));
  });

  // ── TC-07 ─────────────────────────────────────────────────────────────────
  test('TC-07: updateLaporan() mengupdate data laporan yang sudah ada', () async {
    await datasource.saveLaporan(makeLaporan(id: 'laporan-001', judul: 'Judul Lama'));

    final updated = makeLaporan(id: 'laporan-001', judul: 'Judul Baru');
    await datasource.updateLaporan(updated);

    final result = datasource.getLaporanById('laporan-001');
    expect(result!.judul, equals('Judul Baru'));
  });

  // ── TC-08 ─────────────────────────────────────────────────────────────────
  test('TC-08: deleteLaporan() menghapus laporan dari box', () async {
    await datasource.saveLaporan(makeLaporan(id: 'laporan-001'));
    await datasource.deleteLaporan('laporan-001');

    final result = datasource.getLaporanById('laporan-001');
    expect(result, isNull);
  });

  // ── TC-09 ─────────────────────────────────────────────────────────────────
  test('TC-09: deleteLaporan() tidak error meski ID tidak ditemukan', () async {
    expect(
      () async => await datasource.deleteLaporan('id-tidak-ada'),
      returnsNormally,
    );
  });

  // ── TC-10 ─────────────────────────────────────────────────────────────────
  test('TC-10: updateStatus() mengubah status laporan dengan benar', () async {
    await datasource.saveLaporan(makeLaporan(
      id: 'laporan-001',
      status: AppConstants.statusMenunggu,
    ));

    await datasource.updateStatus('laporan-001', AppConstants.statusDisposisi);

    final result = datasource.getLaporanById('laporan-001');
    expect(result!.status, equals(AppConstants.statusDisposisi));
  });

  // ── TC-11 ─────────────────────────────────────────────────────────────────
  test('TC-11: countAll() return jumlah laporan yang benar', () async {
    await datasource.saveLaporan(makeLaporan(id: 'a'));
    await datasource.saveLaporan(makeLaporan(id: 'b'));
    await datasource.saveLaporan(makeLaporan(id: 'c'));

    expect(datasource.countAll(), equals(3));
  });

  // ── TC-12 ─────────────────────────────────────────────────────────────────
  test('TC-12: saveLaporan() dengan ID sama overwrite laporan lama', () async {
    await datasource.saveLaporan(makeLaporan(id: 'laporan-001', judul: 'Lama'));
    await datasource.saveLaporan(makeLaporan(id: 'laporan-001', judul: 'Baru'));

    expect(datasource.countAll(), equals(1)); // tidak jadi 2
    expect(datasource.getLaporanById('laporan-001')!.judul, equals('Baru'));
  });
}