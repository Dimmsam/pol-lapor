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
  int _unreadNotif = 0;
  int _lastKnownCount = 0;
  ValueListenable<Box<LaporanLokal>>? _listenable;
  VoidCallback? _listener;

  UserSession? get session => _session;
  int get totalLaporan => _totalLaporan;
  int get totalUnsynced => _totalUnsynced;
  int get unreadNotifCount => _unreadNotif;
  String get namaUser => _session?.nama ?? '-';
  String get roleUser => _session?.role ?? '-';
  String get emailUser => _session?.email ?? '-';

  // =========================================================
  // INIT
  // =========================================================

  void init() {
    _session = _auth.getSession();
    _refresh();
    _initNotif();
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
  }

  // =========================================================
  // REALTIME LISTENER
  // =========================================================

  void _listenRealtimeLaporan() {
    final box = Hive.box<LaporanLokal>(AppConstants.boxLaporan);
    _listenable = box.listenable();

    _listener = () {
      debugPrint('📡 Laporan berubah (Realtime)');

      final currentCount = box.length;

      // Tambah notif hanya kalau ada laporan BARU
      if (currentCount > _lastKnownCount) {
        _unreadNotif += (currentCount - _lastKnownCount);
      }
      _lastKnownCount = currentCount;

      _totalLaporan = box.length;
      _totalUnsynced = box.values.where((l) => !l.isSynced).length;

      notifyListeners();
    };

    _listenable!.addListener(_listener!);
  }

  // =========================================================
  // NOTIFICATION
  // =========================================================

  void _initNotif() {
    final box = Hive.box<LaporanLokal>(AppConstants.boxLaporan);
    _lastKnownCount = box.length; // snapshot awal
    _unreadNotif = 0;             // mulai dari 0
    notifyListeners();
  }

  void clearNotification() {
    _unreadNotif = 0;
    notifyListeners();
  }

  // =========================================================
  // CLEANUP
  // =========================================================

  @override
  void dispose() {
    if (_listenable != null && _listener != null) {
      _listenable!.removeListener(_listener!);
    }
    super.dispose();
  }
}