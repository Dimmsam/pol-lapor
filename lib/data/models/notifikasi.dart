/// Tipe notifikasi yang tersimpan di kolom `tipe`
class TipeNotifikasi {
  static const String info        = 'info';
  static const String updateStatus = 'update_status';
  static const String eskalasi    = 'eskalasi';
  static const String selesai     = 'selesai';
  static const String laporanBaru = 'laporan_baru';

  /// Icon data name untuk tiap tipe
  static String iconAsset(String tipe) {
    switch (tipe) {
      case updateStatus: return 'update';
      case eskalasi:     return 'eskalasi';
      case selesai:      return 'selesai';
      case laporanBaru:  return 'baru';
      default:           return 'info';
    }
  }
}

class Notifikasi {
  final String notifikasiId;
  final String penerimaId;
  final String? formulirId;
  final String judul;
  final String pesan;
  final String tipe;
  final bool isRead;
  final DateTime createdAt;

  const Notifikasi({
    required this.notifikasiId,
    required this.penerimaId,
    this.formulirId,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.isRead,
    required this.createdAt,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      notifikasiId: json['notifikasi_id'] as String,
      penerimaId:   json['penerima_id']   as String,
      formulirId:   json['formulir_id']   as String?,
      judul:        json['judul']          as String,
      pesan:        json['pesan']          as String,
      tipe:         json['tipe']           as String? ?? TipeNotifikasi.info,
      isRead:       json['is_read']        as bool? ?? false,
      createdAt:    DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'notifikasi_id': notifikasiId,
    'penerima_id':   penerimaId,
    'formulir_id':   formulirId,
    'judul':         judul,
    'pesan':         pesan,
    'tipe':          tipe,
    'is_read':       isRead,
    'created_at':    createdAt.toIso8601String(),
  };

  Notifikasi copyWith({bool? isRead}) {
    return Notifikasi(
      notifikasiId: notifikasiId,
      penerimaId:   penerimaId,
      formulirId:   formulirId,
      judul:        judul,
      pesan:        pesan,
      tipe:         tipe,
      isRead:       isRead ?? this.isRead,
      createdAt:    createdAt,
    );
  }
}
