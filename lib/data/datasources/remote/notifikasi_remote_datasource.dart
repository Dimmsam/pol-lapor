import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../models/notifikasi.dart';

class NotifikasiRemoteDatasource {
  final _db = SupabaseService.db;

  static const _select = '''
    notifikasi_id,
    penerima_id,
    formulir_id,
    judul,
    pesan,
    tipe,
    is_read,
    created_at
  ''';

  // ── Fetch notifikasi milik user, terbaru dulu, limit 50 ──────────────────
  Future<List<Notifikasi>> fetchNotifikasiUser(String penerimaId) async {
    final response = await _db
        .from('notifikasi')
        .select(_select)
        .eq('penerima_id', penerimaId)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((e) => Notifikasi.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Ambil jumlah notifikasi yang belum dibaca ────────────────────────────
  Future<int> fetchUnreadCount(String penerimaId) async {
    final response = await _db
        .from('notifikasi')
        .select('notifikasi_id')
        .eq('penerima_id', penerimaId)
        .eq('is_read', false);

    return (response as List).length;
  }

  // ── Insert satu notifikasi ───────────────────────────────────────────────
  Future<void> insertNotifikasi({
    required String penerimaId,
    required String judul,
    required String pesan,
    required String tipe,
    String? formulirId,
  }) async {
    await _db.from('notifikasi').insert({
      'penerima_id': penerimaId,
      'formulir_id': formulirId,
      'judul':       judul,
      'pesan':       pesan,
      'tipe':        tipe,
      'is_read':     false,
    });
  }

  // ── Tandai satu notifikasi sebagai sudah dibaca ──────────────────────────
  Future<void> markAsRead(String notifikasiId) async {
    await _db
        .from('notifikasi')
        .update({'is_read': true})
        .eq('notifikasi_id', notifikasiId);
  }

  // ── Tandai SEMUA notifikasi user sebagai sudah dibaca ───────────────────
  Future<void> markAllAsRead(String penerimaId) async {
    await _db
        .from('notifikasi')
        .update({'is_read': true})
        .eq('penerima_id', penerimaId)
        .eq('is_read', false);
  }

  // ── Subscribe realtime untuk notifikasi user tertentu ───────────────────
  /// Mengembalikan RealtimeChannel yang bisa di-cancel via removeChannel.
  /// [onNew] dipanggil setiap ada notifikasi INSERT baru untuk user ini.
  RealtimeChannel subscribeToUserNotifikasi({
    required String penerimaId,
    required void Function(Notifikasi notif) onNew,
  }) {
    return _db
        .channel('notifikasi_$penerimaId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifikasi',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'penerima_id',
            value: penerimaId,
          ),
          callback: (payload) {
            try {
              final notif = Notifikasi.fromJson(
                payload.newRecord,
              );
              onNew(notif);
            } catch (e) {
              // ignore malformed payload
            }
          },
        )
        .subscribe();
  }
}
