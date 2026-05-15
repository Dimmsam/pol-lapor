// lib/logic/providers/tracking_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/tracking.dart';

class TrackingProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Tracking> _riwayatTracking = [];
  List<Tracking> get riwayatTracking => _riwayatTracking;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Dipanggil saat Pelapor membuka halaman Detail Laporan
  Future<void> fetchRiwayat(String formulirId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('tracking')
          .select()
          .eq('formulir_id', formulirId)
          .order('created_at', ascending: false);

      _riwayatTracking = (response as List<dynamic>)
          .map((item) => Tracking.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetch tracking: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}