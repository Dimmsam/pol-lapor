import 'package:flutter/foundation.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/local/hive_local_datasource.dart';
import '../../data/models/user_session.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/laporan_lokal.dart';

class HomeProvider extends ChangeNotifier {
  final AuthLocalDatasource _auth = AuthLocalDatasource();
  final HiveLocalDatasource _hive = HiveLocalDatasource();

  UserSession? _session;
  int _totalLaporan = 0;
  int _totalUnsynced = 0;

  UserSession? get session => _session;
  int get totalLaporan => _totalLaporan;
  int get totalUnsynced => _totalUnsynced;

  // nama & role untuk ditampilkan di HomeScreen
  String get namaUser => _session?.nama ?? '-';
  String get roleUser => _session?.role ?? '-';
  String get emailUser => _session?.email ?? '-';

  // ── Load data saat HomeScreen pertama dibuka ──────────────────────────────
  void init() {
    _session = _auth.getSession();
    _refresh();

    // aktifkan realtime listener
    _listenRealtimeLaporan();
  }

  // ── Refresh statistik laporan ─────────────────────────────────────────────
  void _refresh() {
    _totalLaporan = _hive.countAll();
    _totalUnsynced = _hive.countUnsynced();
    notifyListeners();
  }

  // ── Dipanggil saat kembali dari FormLaporan (laporan baru ditambah) ───────
  void onReturnFromForm() {
    _refresh();
  }

  // =========================================================
  // REALTIME LISTENER (AUTO UPDATE HOME)
  // =========================================================

  ValueListenable<Box<LaporanLokal>>? _listenable;

  void _listenRealtimeLaporan() {
    _listenable = Hive.box<LaporanLokal>('laporan_box').listenable();

    _listenable!.addListener(() {
      debugPrint('📡 Laporan berubah (Realtime)');
      _refresh();
    });
  }

  // =========================================================
  // NOTIF COUNT (untuk badge di dashboard)
  // =========================================================

  int get totalNotif {
    final box = Hive.box<LaporanLokal>('laporan_box');
    return box.values.where((l) => !l.isSynced).length;
  }

  // =========================================================
  // CLEANUP (BEST PRACTICE)
  // =========================================================

  @override
  void dispose() {
    _listenable?.removeListener(_refresh);
    super.dispose();
  }
}