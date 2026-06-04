import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/local/laporan_local_datasource.dart';
import '../../data/datasources/remote/laporan_remote_datasource.dart';
import '../../data/models/laporan_lokal.dart';
import '../../data/models/user_session.dart';

class LaporanProvider extends ChangeNotifier {
  final AuthLocalDatasource _auth = AuthLocalDatasource();
  final LaporanLocalDatasource _laporanLocal = LaporanLocalDatasource();
  final LaporanRemoteDatasource _laporanRemote = LaporanRemoteDatasource();

  UserSession? _session;
  List<LaporanLokal> _laporanList = [];
  List<LaporanLokal> _laporanPublik = []; // Laporan publik langsung dari server
  bool _isLoadingPublik = false;
  int _totalLaporan = 0;
  int _totalUnsynced = 0;
  int _totalDiproses = 0;
  int _totalSelesai = 0;
  int _totalMenunggu = 0;
  // ── SISIPAN BARU ──
  int _totalDitolak = 0; 
  
  ValueListenable<Box<LaporanLokal>>? _listenable;
  VoidCallback? _listener;

  UserSession? get session => _session;
  List<LaporanLokal> get laporanList => _laporanList;
  ValueListenable<Box<LaporanLokal>> get laporanListenable =>
      _laporanLocal.listenable();
  int get totalLaporan => _totalLaporan;
  int get totalUnsynced => _totalUnsynced;
  int get totalDiproses => _totalDiproses;
  int get totalSelesai => _totalSelesai;
  int get totalMenunggu => _totalMenunggu;
  // ── SISIPAN BARU ──
  int get totalDitolak => _totalDitolak; 
  
  String get namaUser => _session?.nama ?? '-';
  String get roleUser => _session?.role ?? '-';
  String get emailUser => _session?.email ?? '-';

  String? get currentUserId => _session?.userId;

  List<LaporanLokal> get laporanPublik => _laporanPublik;
  bool get isLoadingPublik => _isLoadingPublik;

  void init() {
    _session = _auth.getSession();
    _refresh();
    _listenRealtimeLaporan();
    _syncFromRemote(); // Sinkronkan dari Supabase saat init
  }

  void refreshSession() {
    _session = _auth.getSession();
    notifyListeners();
  }

  Future<void> clear() async {
    _session = null;
    _laporanList.clear();
    _totalLaporan = 0;
    _totalUnsynced = 0;
    _totalDiproses = 0;
    _totalSelesai = 0;
    _totalMenunggu = 0;
    // ── SISIPAN BARU ──
    _totalDitolak = 0; 
    
    if (_listenable != null && _listener != null) {
      _listenable!.removeListener(_listener!);
    }
    await _laporanLocal.clearAll();
    notifyListeners();
  }

  /// Sinkronkan laporan dari Supabase ke Hive lokal
  Future<void> _syncFromRemote() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final remoteLaporan = await _laporanRemote.fetchAllLaporan();
      await _laporanLocal.syncFromRemote(remoteLaporan, userId, isFullSync: true);
      _refresh();
    } catch (e) {
      debugPrint('_syncFromRemote error: $e');
    }
  }

  /// Method publik untuk trigger sync manual (misal pull-to-refresh)
  Future<void> syncFromRemote() async {
    await _syncFromRemote();
  }

  /// Fetch semua laporan publik langsung dari server (bukan dari Hive lokal).
  /// Ini penting agar status di laporan publik selalu akurat sesuai database.
  Future<void> fetchLaporanPublik() async {
    _isLoadingPublik = true;
    notifyListeners();
    try {
      final remoteData = await _laporanRemote.fetchAllLaporan();
      _laporanPublik = remoteData
          .map((json) => LaporanLokal.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      debugPrint('fetchLaporanPublik error: $e');
    } finally {
      _isLoadingPublik = false;
      notifyListeners();
    }
  }

  List<LaporanLokal> recentLaporan({int limit = 3}) {
    return _laporanList.where((l) => isOwner(l)).take(limit).toList();
  }

  LaporanLokal? getLaporanById(String formulirId) {
    return _laporanLocal.getLaporanById(formulirId);
  }

  List<LaporanLokal> filterLaporan({
    String filterStatus = 'semua',
    String searchQuery = '',
  }) {
    var data = List<LaporanLokal>.from(_laporanList);

    if (filterStatus != 'semua') {
      data = data.where((l) => l.status == filterStatus).toList();
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      data = data
          .where(
            (l) =>
                l.namaSarana.toLowerCase().contains(query) ||
                l.keteranganKerusakan.toLowerCase().contains(query) ||
                l.lokasiPerbaikan.toLowerCase().contains(query),
          )
          .toList();
    }

    return data;
  }

  void _refresh() {
    _laporanList = _laporanLocal.getAllLaporan();
    _updateStats(_laporanList);
    notifyListeners();
  }

  void _updateStats(List<LaporanLokal> semua) {
    final milikku = semua.where((l) => isOwner(l)).toList();
    
    _totalLaporan = milikku.length;
    _totalUnsynced = milikku.where((l) => !l.isSynced).length;
    _totalDiproses =
        milikku.where((l) => l.status == StatusLaporan.diproses).length;
    _totalSelesai =
        milikku.where((l) => l.status == StatusLaporan.selesai).length;
    _totalMenunggu = milikku
        .where((l) => l.status == StatusLaporan.menungguKlasifikasi) // <─── SUDAH DIPERBAIKI AMAN
        .length;
    // ── SISIPAN BARU ──
    _totalDitolak = milikku
        .where((l) => l.status.toLowerCase() == 'ditolak')
        .length;
  }

  void onReturnFromForm() {
    _refresh();
  }

  bool isOwner(LaporanLokal laporan) {
    final userId = currentUserId;
    return userId != null && userId == laporan.pelaporId;
  }

  bool canDelete(LaporanLokal laporan) => isOwner(laporan);

  bool canEdit(LaporanLokal laporan) {
    return isOwner(laporan) &&
        (laporan.status == StatusLaporan.menungguKlasifikasi || // <─── SUDAH DIPERBAIKI AMAN
         laporan.status.toLowerCase() == 'ditolak');
  }

  Future<void> deleteLaporan(LaporanLokal laporan) async {
    if (!canDelete(laporan)) {
      throw Exception('Kamu hanya bisa menghapus laporan milikmu sendiri');
    }

    if (laporan.isSynced) {
      // Laporan sudah ada di server → hapus remote dulu, jika gagal jangan hapus lokal
      // agar data tetap konsisten (tidak ghost di lokal saja)
      await _laporanRemote.deleteLaporan(
        formulirId: laporan.formulirId,
        pelaporId: laporan.pelaporId,
      );
    } else {
      // Laporan belum pernah dikirim ke server → coba hapus remote juga untuk berjaga-jaga
      // (misal sync sudah berjalan di background tapi isSynced belum ter-update)
      try {
        await _laporanRemote.deleteLaporan(
          formulirId: laporan.formulirId,
          pelaporId: laporan.pelaporId,
        );
      } catch (e) {
        debugPrint('deleteLaporan remote skip (belum pernah sync): $e');
      }
    }

    await _laporanLocal.deleteLaporan(laporan.formulirId);
    _refresh();
  }

  void _listenRealtimeLaporan() {
    // Remove existing listener first to prevent duplicates
    if (_listenable != null && _listener != null) {
      _listenable!.removeListener(_listener!);
    }
    
    _listenable = _laporanLocal.listenable();

    _listener = () {
      debugPrint('Laporan berubah (Realtime)');

      final semua = _laporanLocal.getAllLaporan();
      
      _laporanList = semua;
      _updateStats(semua);
      notifyListeners();
    };

    _listenable!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listenable != null && _listener != null) {
      _listenable!.removeListener(_listener!);
    }
    super.dispose();
  }
}