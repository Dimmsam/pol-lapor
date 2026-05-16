import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class TrackingService {
  final _supabase = Supabase.instance.client;

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
        'status': statusLaporan,
        'pesan_narasi': pesanNarasi,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Tracking berhasil dicatat: $pesanNarasi');
    } catch (e) {
      print('❌ Gagal mencatat tracking: $e');
      // Kamu bisa tambahkan logic simpan ke Hive sementara di sini 
      // kalau mau tracking-nya mendukung offline sepenuhnya
    }
  }
}