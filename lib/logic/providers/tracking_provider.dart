import 'package:flutter/material.dart';
import '../../data/models/tracking.dart';
import '../../data/datasources/remote/tracking_remote_datasource.dart';

class TrackingProvider extends ChangeNotifier {
  final TrackingRemoteDatasource _trackingRemote = TrackingRemoteDatasource();

  List<Tracking> _riwayatTracking = [];
  List<Tracking> get riwayatTracking => _riwayatTracking;

  int get currentStep {
    if (_riwayatTracking.any((e) => e.jenisEvent == 'penanganan_selesai')) return 4;
    if (_riwayatTracking.any((e) => e.jenisEvent == 'penanganan_dimulai' || e.jenisEvent == 'teknisi_mulai_periksa')) return 3;
    if (_riwayatTracking.any((e) => e.jenisEvent == 'teknisi_ditugaskan')) return 2;
    if (_riwayatTracking.any((e) => e.jenisEvent == 'laporan_diterima_admin')) return 1;
    return 0; // Default / laporan_dibuat
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _currentFormulirId;

  // ─── FETCH: Ambil riwayat tracking satu kali ─────────────────────────────
  Future<void> fetchRiwayat(String formulirId) async {
    _isLoading = true;
    _errorMessage = null;
    _riwayatTracking = [];
    notifyListeners();

    try {
      _riwayatTracking =
          await _trackingRemote.fetchRiwayatTracking(formulirId);
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat tracking';
      debugPrint('Error fetch tracking: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── REALTIME: Subscribe ke tracking baru secara realtime ─────────────────
  void startRealtimeListener(String formulirId) {
    // Jika sudah listening ke formulir yang sama, skip
    if (_currentFormulirId == formulirId && _trackingRemote.isListening) {
      return;
    }
    
    // Stop listener sebelumnya jika ada
    stopRealtimeListener();
    
    _currentFormulirId = formulirId;

    _trackingRemote.subscribeRealtime(
      formulirId: formulirId,
      onNewTracking: (newTracking) {
        // Cegah duplikasi jika tracking sudah ada di list
        final exists = _riwayatTracking.any(
          (t) => t.trackingId == newTracking.trackingId,
        );
        if (!exists) {
          _riwayatTracking.add(newTracking);
          _riwayatTracking.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          notifyListeners();
        }
      },
    );
  }


  /// Hentikan listener realtime (dipanggil saat screen di-dispose).
  void stopRealtimeListener() {
    _trackingRemote.unsubscribe();
    _currentFormulirId = null;
    _riwayatTracking = [];
  }

  // ─── COMBINED: Catat tracking baru lalu refresh list ──────────────────────
  Future<bool> catatTrackingDanRefresh({
    required String formulirId,
    String? aktorId,
    required String jenisEvent,
    required String pesanNarasi,
  }) async {
    try {
      await _trackingRemote.catatTracking(
        formulirId: formulirId,
        aktorId: aktorId,
        jenisEvent: jenisEvent,
        pesanNarasi: pesanNarasi,
      );

      // Refresh list hanya jika belum pakai realtime
      // (realtime akan otomatis menambahkan ke list)
      if (_currentFormulirId != formulirId) {
        await fetchRiwayat(formulirId);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengirim catatan';
      debugPrint('Error catat tracking: $e');
      notifyListeners();
      return false;
    }
  }

  // ─── CLEAR ERROR ──────────────────────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── DISPOSE ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    stopRealtimeListener();
    super.dispose();
  }
}
