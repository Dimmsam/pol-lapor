class Tracking {
  final String trackingId;
  final String formulirId;
  final String? aktorId;
  final String? aktorNama;

  /// Nilai enum `jenis_event_enum` di Supabase.
  /// Lihat [JenisEvent] di `app_constants.dart` untuk daftar lengkap.
  /// Nullable agar backward-compatible saat fetch data lama yang belum terisi.
  final String? jenisEvent;

  final String pesanNarasi;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const Tracking({
    required this.trackingId,
    required this.formulirId,
    this.aktorId,
    this.aktorNama,
    this.jenisEvent,
    required this.pesanNarasi,
    this.metadata,
    required this.createdAt,
  });

  factory Tracking.fromJson(Map<String, dynamic> json) {
    return Tracking(
      trackingId: json['tracking_id'] as String,
      formulirId: json['formulir_id'] as String,
      aktorId: json['aktor_id'] as String?,
      aktorNama: json['pengguna'] != null ? json['pengguna']['nama_lengkap'] as String? : null,
      jenisEvent: json['jenis_event'] as String?,
      pesanNarasi: json['pesan_narasi'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'tracking_id': trackingId,
    'formulir_id': formulirId,
    'aktor_id': aktorId,
    if (aktorNama != null) 'aktor_nama': aktorNama,
    'jenis_event': jenisEvent,
    'pesan_narasi': pesanNarasi,
    'metadata': metadata,
    'created_at': createdAt.toIso8601String(),
  };
}
