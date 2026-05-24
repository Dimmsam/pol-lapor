// lib/logic/providers/tracking_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/tracking.dart';

class TrackingProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

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
      _setLoading(false);
    }
  }

  /// Buat entry tracking baru dan simpan ke Supabase
  Future<void> createTracking({
    required String formulirId,
    String? aktorId,
    required String status,
    required String pesanNarasi,
  }) async {
    _setLoading(true);

    final tracking = Tracking(
      trackingId: _uuid.v4(),
      formulirId: formulirId,
      aktorId: aktorId,
      status: status,
      pesanNarasi: pesanNarasi,
      createdAt: DateTime.now(),
    );

    try {
      await _supabase.from('tracking').insert(tracking.toJson());
      _riwayatTracking.insert(0, tracking);
      notifyListeners();
    } catch (e) {
      debugPrint('Error create tracking: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}