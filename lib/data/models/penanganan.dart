class Penanganan {
  final String penangananId;
  final String formulirId;
  final String teknisiId;
  final String statusPenanganan; // enum: mulai_dikerjakan | sedang_dikerjakan | selesai
  final String? catatanProgres;
  final String? deskripsiHasil;
  final String? kategoriKerusakan; // kolom baru — diisi saat eskalasi
  final List<String> fotoProgresUrl; // ARRAY di DB
  final String? fotoHasilUrl;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final DateTime updatedAt;

  const Penanganan({
    required this.penangananId,
    required this.formulirId,
    required this.teknisiId,
    required this.statusPenanganan,
    this.catatanProgres,
    this.deskripsiHasil,
    this.kategoriKerusakan,
    this.fotoProgresUrl = const [],
    this.fotoHasilUrl,
    this.tanggalMulai,
    this.tanggalSelesai,
    required this.updatedAt,
  });

  factory Penanganan.fromJson(Map<String, dynamic> json) {
    // foto_progres_url adalah ARRAY di Supabase → bisa null atau List
    List<String> parseFotoProgres(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return Penanganan(
      penangananId: json['penanganan_id'] as String,
      formulirId: json['formulir_id'] as String,
      teknisiId: json['teknisi_id'] as String,
      statusPenanganan:
          json['status_penanganan'] as String? ?? StatusPenanganan.mulaiDikerjakan,
      catatanProgres:    json['catatan_progres']    as String?,
      deskripsiHasil:   json['deskripsi_hasil']    as String?,
      kategoriKerusakan: json['kategori_kerusakan'] as String?,
      fotoProgresUrl: parseFotoProgres(json['foto_progres_url']),
      fotoHasilUrl: json['foto_hasil_url'] as String?,
      tanggalMulai: json['tanggal_mulai'] != null
          ? DateTime.parse(json['tanggal_mulai'] as String)
          : null,
      tanggalSelesai: json['tanggal_selesai'] != null
          ? DateTime.parse(json['tanggal_selesai'] as String)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'penanganan_id':     penangananId,
        'formulir_id':       formulirId,
        'teknisi_id':        teknisiId,
        'status_penanganan': statusPenanganan,
        'catatan_progres':   catatanProgres,
        'deskripsi_hasil':   deskripsiHasil,
        'kategori_kerusakan': kategoriKerusakan,
        'foto_progres_url':  fotoProgresUrl,
        'foto_hasil_url':    fotoHasilUrl,
        'tanggal_mulai':     tanggalMulai?.toIso8601String(),
        'tanggal_selesai':   tanggalSelesai?.toIso8601String(),
        'updated_at':        updatedAt.toIso8601String(),
      };

  /// Copy-with untuk update partial state
  Penanganan copyWith({
    String? statusPenanganan,
    String? catatanProgres,
    String? deskripsiHasil,
    String? kategoriKerusakan,
    List<String>? fotoProgresUrl,
    String? fotoHasilUrl,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
  }) {
    return Penanganan(
      penangananId:      penangananId,
      formulirId:        formulirId,
      teknisiId:         teknisiId,
      statusPenanganan:  statusPenanganan  ?? this.statusPenanganan,
      catatanProgres:    catatanProgres    ?? this.catatanProgres,
      deskripsiHasil:   deskripsiHasil   ?? this.deskripsiHasil,
      kategoriKerusakan: kategoriKerusakan ?? this.kategoriKerusakan,
      fotoProgresUrl:    fotoProgresUrl    ?? this.fotoProgresUrl,
      fotoHasilUrl:      fotoHasilUrl      ?? this.fotoHasilUrl,
      tanggalMulai:      tanggalMulai      ?? this.tanggalMulai,
      tanggalSelesai:    tanggalSelesai    ?? this.tanggalSelesai,
      updatedAt:         DateTime.now(),
    );
  }
}

/// Konstanta untuk status_penanganan_enum di DB
/// DB hanya punya: mulai_dikerjakan | selesai
class StatusPenanganan {
  static const String mulaiDikerjakan = 'mulai_dikerjakan';
  // 'sedang_dikerjakan' TIDAK ada di enum DB - gunakan mulaiDikerjakan
  static const String selesai = 'selesai';
  // 'menunggu_eskalasi_jurusan' TIDAK ada di enum DB - gunakan status formulir diteruskan_ke_pusat

  static String toLabel(String status) {
    switch (status) {
      case mulaiDikerjakan:
        return 'Sedang Dikerjakan';
      case selesai:
        return 'Selesai';
      default:
        return 'Dikerjakan';
    }
  }

  /// Apakah status sudah selesai?
  static bool isSelesai(String status) => status == selesai;

  /// Apakah status masih aktif (belum selesai)?
  static bool isAktif(String status) => status == mulaiDikerjakan;
}