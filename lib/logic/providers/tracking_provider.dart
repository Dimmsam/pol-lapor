// lib/logic/providers/tracking_provider.dart
import 'package:flutter/material.dart';
import '../../data/models/tracking.dart';
import '../../services/tracking_service.dart';

class TrackingProvider extends ChangeNotifier {
  final TrackingService _trackingService = TrackingService();

  List<Tracking> _riwayatTracking = [];
  List<Tracking> get riwayatTracking => _riwayatTracking;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _currentFormulirId;

  // ─── FETCH: Ambil riwayat tracking satu kali ─────────────────────────────
  /// Dipanggil saat Pelapor/Teknisi membuka halaman Detail Laporan
  Future<void> fetchRiwayat(String formulirId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _riwayatTracking =
          await _trackingService.fetchRiwayatTracking(formulirId);
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat tracking';
      debugPrint('Error fetch tracking: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── REALTIME: Subscribe ke tracking baru secara realtime ─────────────────
  /// Memulai listener realtime. Harus dipanggil setelah fetchRiwayat.
  void startRealtimeListener(String formulirId) {
    _currentFormulirId = formulirId;

    _trackingService.subscribeRealtime(
      formulirId: formulirId,
      onNewTracking: (newTracking) {
        // Cegah duplikasi jika tracking sudah ada di list
        final exists = _riwayatTracking.any(
          (t) => t.trackingId == newTracking.trackingId,
        );
        if (!exists) {
          _riwayatTracking.add(newTracking);
          notifyListeners();
        }
      },
    );
  }

  /// Hentikan listener realtime (dipanggil saat screen di-dispose).
  void stopRealtimeListener() {
    _trackingService.unsubscribe();
    _currentFormulirId = null;
  }

  // ─── COMBINED: Catat tracking baru lalu refresh list ──────────────────────
  /// Digunakan oleh UI untuk menambah catatan baru + langsung refresh list.
  Future<bool> catatTrackingDanRefresh({
    required String formulirId,
    String? aktorId,
    required String statusLaporan,
    required String pesanNarasi,
  }) async {
    try {
      await _trackingService.catatTracking(
        formulirId: formulirId,
        aktorId: aktorId,
        statusLaporan: statusLaporan,
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
