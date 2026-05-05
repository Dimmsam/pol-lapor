import 'package:flutter/foundation.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/local/hive_local_datasource.dart';
import '../../data/models/user_session.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/laporan_lokal.dart';
import '../../core/constants/app_constants.dart';

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

  // init notif awal
    _initNotif();
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

   // trigger notif saat ada laporan baru
    addNotification();
  }

  // =========================================================
  // REALTIME LISTENER (AUTO UPDATE HOME)
  // =========================================================

  ValueListenable<Box<LaporanLokal>>? _listenable;
   // simpan reference listener biar bisa dihapus
  VoidCallback? _listener;

  void _listenRealtimeLaporan() {
    _listenable = Hive.box<LaporanLokal>('laporan_box').listenable();

    // gunakan listener yang bisa diremove
    _listener = () {
      debugPrint('📡 Laporan berubah (Realtime)');
      _refresh();
    };

    _listenable!.addListener(() {
      debugPrint('📡 Laporan berubah (Realtime)');
      _refresh();
    });
  }

  // =========================================================
  // NOTIF COUNT (untuk badge di dashboard)
  // =========================================================

   int _unreadNotif = 0;

  int get unreadNotifCount => _unreadNotif;

  int get totalNotif {
    final box = Hive.box<LaporanLokal>(AppConstants.boxLaporan);
    return box.values.where((l) => !l.isSynced).length;
  }

  // init notif dari data lama
  void _initNotif() {
    _unreadNotif = totalNotif;
  }

  // tambah notif
  void addNotification() {
    _unreadNotif++;
    notifyListeners();
  }

  // clear notif
  void clearNotification() {
    _unreadNotif = 0;
    notifyListeners();
  }

  // =========================================================
  // CLEANUP (BEST PRACTICE)
  // =========================================================

 @override
  void dispose() {
    // FIX: remove listener yang benar
    if (_listenable != null && _listener != null) {
      _listenable!.removeListener(_listener!);
    }

    super.dispose();
  }