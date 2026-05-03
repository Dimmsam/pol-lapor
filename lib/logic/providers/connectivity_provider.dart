import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '/services/sync_service.dart'; // Sesuaikan path

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    // Dengarkan perubahan status koneksi secara real-time
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Package connectivity_plus terbaru mengembalikan List
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    bool previousStatus = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    notifyListeners(); // Update UI (misal menghilangkan banner offline)

    // Jika transisi dari Offline menjadi Online, otomatis jalankan Sync!
    if (!previousStatus && _isOnline) {
      print('🌐 Koneksi kembali! Memulai sinkronisasi background...');
      SyncService().syncUnsyncedData();
    }
  }
}