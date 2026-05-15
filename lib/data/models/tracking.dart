class Tracking {
  final String trackingId;
  final String formulirId;
  final String? aktorId; // Bisa null jika yang melakukan adalah by system
  final String status;
  final String pesanNarasi;
  final DateTime createdAt;

  const Tracking({
    required this.trackingId,
    required this.formulirId,
    this.aktorId,
    required this.status,
    required this.pesanNarasi,
    required this.createdAt,
  });

  factory Tracking.fromJson(Map<String, dynamic> json) {
    return Tracking(
      trackingId: json['tracking_id'] as String,
      formulirId: json['formulir_id'] as String,
      aktorId: json['aktor_id'] as String?,
      status: json['status'] as String,
      pesanNarasi: json['pesan_narasi'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'tracking_id': trackingId,
        'formulir_id': formulirId,
        'aktor_id': aktorId,
        'status': status,
        'pesan_narasi': pesanNarasi,
        'created_at': createdAt.toIso8601String(),
      };
}