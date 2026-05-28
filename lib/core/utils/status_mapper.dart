import 'package:flutter/foundation.dart';

class StatusMapper {
  StatusMapper._();

  /// Nilai valid enum `status_formulir`
  static const Set<String> _validSupabaseStatus = {
    'menunggu',
    'ditugaskan',
    'sedang_dikerjakan',
    'selesai',
    'diteruskan_ke_pusat',
  };

  /// Jika [statusLokal] sudah berupa nilai Supabase yang valid,
  /// dikembalikan apa adanya. Jika tidak dikenal, fallback ke `'menunggu'`.
  static String toSupabaseStatus(String statusLokal) {
    if (_validSupabaseStatus.contains(statusLokal)) return statusLokal;

    switch (statusLokal) {
      case 'menunggu_klasifikasi':
      case 'draft':
        return 'menunggu';

      case 'klasifikasi_selesai':
      case 'pengajuan_dibuat':
      case 'terkirim':
      case 'dicatat_admin':
      case 'diketahui_ka_upt':
      case 'surat_pengajuan_dibuat':
      case 'surat_kerja_diterbitkan':
      case 'diproses': // status lokal Flutter
        return 'ditugaskan';

      case 'sedang_ditangani':
      case 'selesai_ditangani':
        return 'sedang_dikerjakan';

      case 'berita_acara_dibuat':
        return 'selesai';

      default:
        debugPrint(
          'StatusMapper: status "$statusLokal" tidak dikenal, '
          'fallback ke "menunggu".',
        );
        return 'menunggu';
    }
  }

  /// Format nilai enum jenis_event menjadi teks yang mudah dibaca
  static String formatJenisEvent(String jenisEvent) {
    switch (jenisEvent) {
      case 'laporan_dibuat':
        return 'Laporan Dibuat';
      case 'laporan_diterima_admin':
        return 'Laporan Diterima Admin';
      case 'teknisi_ditugaskan':
        return 'Teknisi Ditugaskan';
      case 'teknisi_mulai_periksa':
        return 'Teknisi Memulai Pemeriksaan';
      case 'penanganan_dimulai':
        return 'Penanganan Dimulai';
      case 'penanganan_selesai':
        return 'Penanganan Selesai';
      case 'diteruskan_ke_pusat':
        return 'Diteruskan ke Pusat';
      default:
        return jenisEvent
            .split('_')
            .map((word) => word.isNotEmpty
                ? '\${word[0].toUpperCase()}\${word.substring(1)}'
                : '')
            .join(' ');
    }
  }
}
