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

  // =========================================================
  // INIT
  // =========================================================

  void init() {
    _session = _auth.getSession();
    _refresh();

    // init notif awal
    _initNotif();

    // aktifkan realtime listener
    _listenRealtimeLaporan();
  }

  // =========================================================
  // REFRESH DATA
  // =========================================================

  void _refresh() {
    _totalLaporan = _hive.countAll();
    _totalUnsynced = _hive.countUnsynced();
    notifyListeners();
  }

  void onReturnFromForm() {
    _refresh();

  // =========================================================
// REALTIME LISTENER (FIXED & CLEAN)
// =========================================================

ValueListenable<Box<LaporanLokal>>? _listenable;
VoidCallback? _listener;

void _listenRealtimeLaporan() {
  // ambil box dari konstanta (lebih aman)
  final box = Hive.box<LaporanLokal>(AppConstants.boxLaporan);

  _listenable = box.listenable();

  // IMPORTANT: simpan reference listener biar bisa di-remove
  _listener = () {
    debugPrint('📡 Laporan berubah (Realtime)');

    // update statistik
    _totalLaporan = _hive.countAll();
    _totalUnsynced = _hive.countUnsynced();

    // update notif dari data real (sinkron)
    _unreadNotif = box.values.where((l) => !l.isSynced).length;

    notifyListeners();
  };

  _listenable!.addListener(_listener!);
}

  // =========================================================
  // NOTIFICATION SYSTEM
  // =========================================================

  int _unreadNotif = 0;

  int get unreadNotifCount => _unreadNotif;

  int get totalNotif {
    final box = Hive.box<LaporanLokal>(AppConstants.boxLaporan);
    return box.values.where((l) => !l.isSynced).length;
  }

  void _initNotif() {
    _unreadNotif = totalNotif;
    notifyListeners();
  }

  void addNotification() {
    _unreadNotif++;
    notifyListeners();
  }

  void clearNotification() {
    _unreadNotif = 0;
    notifyListeners();
  }

  // =========================================================
  // CLEANUP (FIX MEMORY LEAK)
  // =========================================================

  @override
  void dispose() {
    if (_listenable != null && _listener != null) {
      _listenable!.removeListener(_listener!);
    }
    super.dispose();
  }
}