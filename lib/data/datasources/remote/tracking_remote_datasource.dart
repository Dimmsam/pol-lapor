import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../models/tracking.dart';

class TrackingRemoteDatasource {
  final _supabase = SupabaseService.db;

  RealtimeChannel? _realtimeChannel;

  /// Catat satu baris tracking ke tabel `public.tracking`.
  ///
  /// [jenisEvent] — nilai enum `jenis_event_enum` di Supabase (NOT NULL).
  /// Wajib diisi setelah enum values dikonfirmasi (lihat check_schema.sql).
  /// TODO(B10): jadikan required setelah enum dikonfirmasi.
  Future<void> catatTracking({
    required String formulirId,
    String? aktorId,
    required String jenisEvent,
    required String pesanNarasi,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('tracking').insert({
        'tracking_id': const Uuid().v4(),
        'formulir_id': formulirId,
        'aktor_id': aktorId,
        'jenis_event': jenisEvent,
        'pesan_narasi': pesanNarasi,
        if (metadata != null) 'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('TrackingRemote: berhasil dicatat — "$pesanNarasi"');
    } catch (e) {
      debugPrint('TrackingRemote: gagal mencatat tracking: $e');
      rethrow;
    }
  }

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
      debugPrint('TrackingRemote: gagal fetch riwayat tracking: $e');
      rethrow;
    }
  }

  void subscribeRealtime({
    required String formulirId,
    required void Function(Tracking newTracking) onNewTracking,
  }) {
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
              final tracking = Tracking.fromJson(payload.newRecord);
              onNewTracking(tracking);
              debugPrint(
                'TrackingRemote: realtime baru — "${tracking.pesanNarasi}"',
              );
            } catch (e) {
              debugPrint('TrackingRemote: error parse realtime tracking: $e');
            }
          },
        )
        .subscribe();

    debugPrint(
      'TrackingRemote: subscribed realtime untuk formulir $formulirId',
    );
  }

  void unsubscribe() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
      debugPrint('TrackingRemote: unsubscribed dari realtime tracking');
    }
  }
}
