import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/tracking.dart';

class TrackingService {
  final _supabase = Supabase.instance.client;

  RealtimeChannel? _realtimeChannel;

  // ─── 1. INSERT: Catat tracking baru ──────────────────────────────────────
  /// Fungsi universal untuk mencatat tracking dari mana saja
  Future<void> catatTracking({
    required String formulirId,
    String? aktorId, // Bisa ID Pelapor, Teknisi, atau Admin
    required String statusLaporan,
    required String pesanNarasi,
  }) async {
    try {
      await _supabase.from('tracking').insert({
        'tracking_id': const Uuid().v4(),
        'formulir_id': formulirId,
        'aktor_id': aktorId,
        'pesan_narasi': pesanNarasi,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Tracking berhasil dicatat: $pesanNarasi');
    } catch (e) {
      debugPrint('❌ Gagal mencatat tracking: $e');
      rethrow;
    }
  }

  // ─── 2. FETCH: Ambil riwayat tracking untuk 1 laporan ───────────────────
  /// Mengembalikan list [Tracking] diurutkan dari yang terlama (ascending).
  Future<List<Tracking>> fetchRiwayatTracking(String formulirId) async {
    try {
      final response = await _supabase
          .from('tracking')
          .select()
          .eq('formulir_id', formulirId)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((item) => Tracking.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Gagal fetch riwayat tracking: $e');
      rethrow;
    }
  }

  // ─── 3. REALTIME: Subscribe ke perubahan tracking ───────────────────────
  /// Membuka channel realtime Supabase untuk mendengarkan INSERT baru
  /// pada tabel tracking yang sesuai [formulirId].
  /// [onNewTracking] dipanggil setiap ada record baru.
  void subscribeRealtime({
    required String formulirId,
    required void Function(Tracking newTracking) onNewTracking,
  }) {
    // Tutup channel lama jika ada
    unsubscribe();

    final channelName = 'tracking:$formulirId';
    _realtimeChannel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tracking',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'formulir_id',
            value: formulirId,
          ),
          callback: (payload) {
            try {
              final newRecord = payload.newRecord;
              final tracking = Tracking.fromJson(newRecord);
              onNewTracking(tracking);
              debugPrint('🔔 Realtime tracking baru: ${tracking.pesanNarasi}');
            } catch (e) {
              debugPrint('❌ Error parse realtime tracking: $e');
            }
          },
        )
        .subscribe();

    debugPrint('📡 Subscribed realtime tracking untuk formulir: $formulirId');
  }

  // ─── 4. UNSUBSCRIBE: Tutup channel realtime ─────────────────────────────
  void unsubscribe() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
      debugPrint('📡 Unsubscribed dari realtime tracking');
    }
  }
}
