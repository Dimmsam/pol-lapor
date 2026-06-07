import 'package:flutter/material.dart';
import '../../data/models/tracking.dart';
import '../../data/datasources/remote/tracking_remote_datasource.dart';
import '../../core/constants/app_constants.dart';

class TrackingProvider extends ChangeNotifier {
  final TrackingRemoteDatasource _trackingRemote = TrackingRemoteDatasource();

  List<Tracking> _riwayatTracking = [];
  List<Tracking> get riwayatTracking => _riwayatTracking;

  /// Apakah ada event eskalasi (untuk teknisi — tampil begitu teknisi submit)
  bool get hasEskalasiTeknisi {
    return _riwayatTracking.any((e) => 
      e.jenisEvent == 'eskalasi_dari_teknisi' || 
      e.jenisEvent == 'eskalasi_disetujui' || 
      e.jenisEvent == 'eskalasi_ditolak' ||
      e.jenisEvent == 'kajur_approve_eskalasi' || 
      e.jenisEvent == 'diteruskan_ke_pusat'
    );
  }

  /// Apakah ada eskalasi yang sudah di-review admin (untuk pelapor)
  /// Catatan: Jika eskalasi ditolak, pelapor tidak perlu tahu.
  /// Pelapor hanya tahu laporan "Dalam Penanganan".
  bool get hasEskalasiPelapor {
    final lastEskalasiEvent = _riwayatTracking.lastWhere(
      (e) => 
          e.jenisEvent == 'eskalasi_dari_teknisi' ||
          e.jenisEvent == 'eskalasi_disetujui' ||
          e.jenisEvent == 'eskalasi_ditolak' ||
          e.jenisEvent == 'kajur_approve_eskalasi' ||
          e.jenisEvent == 'diteruskan_ke_pusat',
      orElse: () => Tracking(trackingId: '', formulirId: '', aktorId: '', pesanNarasi: '', createdAt: DateTime.now()),
    );

    return lastEskalasiEvent.jenisEvent == 'eskalasi_disetujui' || 
           lastEskalasiEvent.jenisEvent == 'kajur_approve_eskalasi' || 
           lastEskalasiEvent.jenisEvent == 'diteruskan_ke_pusat';
  }

  /// Hitung currentStep berdasarkan daftar steps tertentu.
  /// Ini memungkinkan Pelapor dan Teknisi punya step list berbeda
  /// tapi tetap mendapat currentStep yang benar.
  int currentStepFor(List<Map<String, dynamic>> steps) {
    if (_riwayatTracking.isEmpty) return 0;

    // Special: laporan ditolak → tetap di step 1 (Ditinjau Admin)
    if (_riwayatTracking.any((e) => e.jenisEvent == 'laporan_ditolak')) {
      return 1;
    }

    // Special: eskalasi ditolak → kembali ke step 3 (Dalam Penanganan)
    // TAPI pastikan penolakan itu adalah status eskalasi TERAKHIR.
    // Jika ada eskalasi baru diajukan, maka jangan rollback.
    final lastEskalasiEvent = _riwayatTracking.lastWhere(
      (e) => 
          e.jenisEvent == 'eskalasi_dari_teknisi' ||
          e.jenisEvent == 'eskalasi_disetujui' ||
          e.jenisEvent == 'eskalasi_ditolak' ||
          e.jenisEvent == 'kajur_approve_eskalasi' ||
          e.jenisEvent == 'diteruskan_ke_pusat',
      orElse: () => Tracking(trackingId: '', formulirId: '', aktorId: '', pesanNarasi: '', createdAt: DateTime.now()),
    );

    if (lastEskalasiEvent.jenisEvent == 'eskalasi_ditolak') {
      final hasFinished = _riwayatTracking.any((e) => e.jenisEvent == 'penanganan_selesai');
      if (!hasFinished) {
        return 3; // Dalam Penanganan — teknisi harus lanjut kerja
      }
    }

    // Normal: iterasi mundur, cari step terjauh yang punya event
    for (int i = steps.length - 1; i >= 0; i--) {
      final eventsForStep = steps[i]['events'] as List<String>;
      // Cari event apa saja yang masuk di step ini
      final matchingEvents = _riwayatTracking.where((e) => eventsForStep.contains(e.jenisEvent)).toList();
      
      if (matchingEvents.isNotEmpty) {
        final lastEvent = matchingEvents.last.jenisEvent;
        
        if (lastEvent == 'penanganan_dimulai' || 
            lastEvent == 'teknisi_mulai_periksa' || 
            (lastEvent?.startsWith('eskalasi_') ?? false) || 
            lastEvent == 'kajur_approve_eskalasi' || 
            lastEvent == 'diteruskan_ke_pusat') {
          return i; // Fase ini masih berjalan (Active)
        } else if (lastEvent == 'penanganan_selesai' || lastEvent == 'laporan_dikunci') {
          return steps.length; // Semua selesai (Completed all)
        } else {
          // laporan_dibuat, laporan_diterima_admin, teknisi_ditugaskan
          // Event ini menandakan selesainya suatu titik, lanjut ke fase berikutnya
          return i + 1; 
        }
      }
    }
    
    return 0;
  }

  /// Legacy getter (backward compat)
  int get currentStep {
    final steps = AppConstants.buildTrackingSteps(showEskalasi: hasEskalasiTeknisi);
    return currentStepFor(steps);
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
          // Bug 1 FIX: Samakan sort order dengan fetch (ascending)
          _riwayatTracking.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          notifyListeners();
        }
      },
    );
  }


  /// Hentikan listener realtime (dipanggil saat screen di-dispose).
  /// Bug 7 FIX: Tidak lagi menghapus _riwayatTracking.
  void stopRealtimeListener() {
    _trackingRemote.unsubscribe();
    _currentFormulirId = null;
    // JANGAN hapus _riwayatTracking di sini — data masih bisa dibutuhkan
  }

  /// Bersihkan semua data tracking (dipanggil saat benar-benar reset).
  void clearTrackingData() {
    _riwayatTracking = [];
    _currentFormulirId = null;
    notifyListeners();
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
