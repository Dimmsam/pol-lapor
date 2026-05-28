import 'package:flutter/material.dart';

import '../../data/datasources/remote/penanganan_remote_datasource.dart';
import '../../data/models/laporan_lokal.dart';

class TeknisiDashboardProvider extends ChangeNotifier {
  final PenangananRemoteDatasource _remote = PenangananRemoteDatasource();

  List<LaporanLokal> _laporanTerbaru = [];

  Map<String, int> _stats = {
    'belum_dimulai': 0,
    'aktif': 0,
    'selesai': 0,
    'total': 0,
  };

  bool _isLoading = false;
  String? _errorMessage;

  List<LaporanLokal> get laporanTerbaru => _laporanTerbaru;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard({required String teknisiId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final results = await Future.wait([
        _remote.fetchStats(teknisiId),
        _remote.fetchLaporanTerbaru(teknisiId),
      ]);
      _stats = results[0] as Map<String, int>;
      _laporanTerbaru = results[1] as List<LaporanLokal>;
    } catch (e) {
      _errorMessage = 'Gagal memuat data. Periksa koneksi internet.';
      debugPrint('loadDashboard error: $e');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
