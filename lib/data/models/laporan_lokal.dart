import 'package:hive/hive.dart';

part 'laporan_lokal.g.dart';

class StatusLaporan {
  static const String menungguKlasifikasi = 'menunggu_klasifikasi';
  static const String diproses = 'diproses';
  static const String selesai = 'selesai';
  static const String ditolakEskalasi = 'ditolak_eskalasi';
  static const String diteruskanKePusat = 'diteruskan_ke_pusat';
  static const String menungguPersetujuanKajur = 'menunggu_persetujuan_kajur';
  static const String ditolak = 'ditolak';

  /// Label tampilan UI
  static String toLabel(String status) {
    switch (status) {
      case menungguKlasifikasi:
        return 'Menunggu Klasifikasi';
      case diproses:
        return 'Sedang Dikerjakan';
      case ditolakEskalasi:
        return 'Eskalasi Ditolak';
      case diteruskanKePusat:
        return 'Diteruskan ke Pusat';
      case menungguPersetujuanKajur:
        return 'Menunggu Persetujuan Kajur';
      case selesai:
        return 'Selesai';
      case ditolak:
        return 'Ditolak';
      default:
        return status;
    }
  }

  /// Judul notifikasi berdasarkan status laporan
  static String notifTitle(String status) {
    switch (status) {
      case selesai:
        return 'Laporan Selesai';
      case diproses:
        return 'Laporan Diproses';
      case menungguPersetujuanKajur:
        return 'Laporan Menunggu Kajur';
      case diteruskanKePusat:
        return 'Laporan Diteruskan ke Pusat';
      case ditolak:
        return 'Laporan Ditolak';
      case menungguKlasifikasi:
        return 'Laporan Baru Masuk';
      default:
        return 'Laporan Baru';
    }
  }

  /// Label untuk konteks teknisi (status laporan di dashboard tugas)
  static String toLabelTeknisi(String status) {
    switch (status) {
      case diproses:
        return 'Dikerjakan';
      case selesai:
        return 'Selesai';
      case menungguPersetujuanKajur:
      case diteruskanKePusat:
        return 'Eskalasi';
      case menungguKlasifikasi:
      default:
        return 'Menunggu';
    }
  }
}

@HiveType(typeId: 0)
class LaporanLokal extends HiveObject {
  @HiveField(0)
  final String formulirId;

  @HiveField(1)
  final String namaSarana;

  @HiveField(2)
  final String keteranganKerusakan;

  @HiveField(3)
  final String lokasiPerbaikan;

  @HiveField(4)
  final String? nomorInventaris;

  @HiveField(5)
  String? fotoLokalPath;

  @HiveField(6)
  String? fotoKerusakanUrl;

  @HiveField(7)
  String status;

  @HiveField(8)
  final String pelaporId;

  @HiveField(13) // New field for prioritas
  String prioritas;

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  // ignore: deprecated_member_use_from_same_package
  @Deprecated(
    'Kolom ini tidak ada di schema Supabase (formulir_laporan). '
    'HiveField(10) dipertahankan untuk backward-compatibility data lama. '
    'Jangan dipakai di logic/UI baru.',
  )
  bool tandaTanganPelapor;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  factory LaporanLokal.fromSupabaseJson(Map<String, dynamic> json) {
    String lokasiNama = json['lokasi_id'] as String? ?? '-';
    if (json['lokasi'] != null) {
      if (json['lokasi'] is Map) {
        lokasiNama = json['lokasi']['nama_ruangan'] as String? ?? 
                     json['lokasi']['lokasi_id'] as String? ?? 
                     lokasiNama;
      } else if (json['lokasi'] is String) {
        lokasiNama = json['lokasi'] as String;
      }
    }

    return LaporanLokal(
      formulirId: json['formulir_id'] as String,
      namaSarana: json['nama_sarana'] as String? ?? '-',
      keteranganKerusakan: json['keterangan_kerusakan'] as String? ?? '-',
      lokasiPerbaikan: lokasiNama,
      nomorInventaris: json['nomor_inventaris'] as String?,
      fotoKerusakanUrl: json['foto_kerusakan_url'] as String?,
      status: json['status'] as String? ?? StatusLaporan.menungguKlasifikasi,
      prioritas: json['prioritas'] as String? ?? 'biasa',
      pelaporId: (json['pengguna'] != null && json['pengguna'] is Map && json['pengguna']['nama_lengkap'] != null)
          ? json['pengguna']['nama_lengkap'] as String
          : json['pelapor_id'] as String? ?? '',
      isSynced: true,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  LaporanLokal({
    required this.formulirId,
    required this.namaSarana,
    required this.keteranganKerusakan,
    required this.lokasiPerbaikan,
    this.nomorInventaris,
    this.fotoLokalPath,
    this.fotoKerusakanUrl,
    String? status,
    String? prioritas,
    required this.pelaporId,
    this.isSynced = false,
    this.tandaTanganPelapor = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : status = status ?? StatusLaporan.menungguKlasifikasi,
        prioritas = prioritas ?? 'biasa',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  // HELPER
  bool get isBelumSync => !isSynced;

  String get statusDisplay => StatusLaporan.toLabel(status);

  // COPY WITH
  LaporanLokal copyWith({
    String? namaSarana,
    String? keteranganKerusakan,
    String? lokasiPerbaikan,
    String? nomorInventaris,
    bool clearNomorInventaris = false,
    String? fotoLokalPath,
    String? fotoKerusakanUrl,
    String? status,
    String? prioritas,
    bool? isSynced,
    bool? tandaTanganPelapor,
    DateTime? updatedAt,
  }) {
    return LaporanLokal(
      formulirId: formulirId,
      namaSarana: namaSarana ?? this.namaSarana,
      keteranganKerusakan:
          keteranganKerusakan ?? this.keteranganKerusakan,
      lokasiPerbaikan: lokasiPerbaikan ?? this.lokasiPerbaikan,
      nomorInventaris: clearNomorInventaris ? null : (nomorInventaris ?? this.nomorInventaris),
      fotoLokalPath: fotoLokalPath ?? this.fotoLokalPath,
      fotoKerusakanUrl: fotoKerusakanUrl ?? this.fotoKerusakanUrl,
      status: status ?? this.status,
      prioritas: prioritas ?? this.prioritas,
      pelaporId: pelaporId,
      isSynced: isSynced ?? this.isSynced,
      tandaTanganPelapor:
          tandaTanganPelapor ?? this.tandaTanganPelapor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// ENUM STATUS (SAFE TYPE)
enum StatusLaporanEnum {
  menunggu,
  diproses,
  selesai,
}

// EXTENSION STATUS PARSER
extension StatusLaporanExtension on String {
  StatusLaporanEnum toStatusEnum() {
    switch (this) {
      case StatusLaporan.menungguKlasifikasi:
        return StatusLaporanEnum.menunggu;
      case StatusLaporan.diproses:
        return StatusLaporanEnum.diproses;
      case StatusLaporan.selesai:
        return StatusLaporanEnum.selesai;
      default:
        return StatusLaporanEnum.menunggu;
    }
  }
}

// HELPER STATUS (UNTUK UI & PROVIDER)
extension LaporanStatusHelper on LaporanLokal {
  bool get isMenunggu =>
      status == StatusLaporan.menungguKlasifikasi;

  bool get isDiproses =>
      status == StatusLaporan.diproses;

  bool get isSelesai =>
      status == StatusLaporan.selesai;
}

