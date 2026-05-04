import 'package:hive/hive.dart';

part 'laporan_lokal.g.dart';

// ======================
// STATUS CONSTANT 
// ======================
class StatusLaporan {
  static const String menungguKlasifikasi = 'menunggu_klasifikasi';
  static const String diproses = 'diproses';
  static const String selesai = 'selesai';
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

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  bool tandaTanganPelapor;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  LaporanLokal({
    required this.formulirId,
    required this.namaSarana,
    required this.keteranganKerusakan,
    required this.lokasiPerbaikan,
    this.nomorInventaris,
    this.fotoLokalPath,
    this.fotoKerusakanUrl,
    String? status,
    required this.pelaporId,
    this.isSynced = false,
    this.tandaTanganPelapor = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : status = status ?? StatusLaporan.menungguKlasifikasi,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  // ======================
  // HELPER
  // ======================
  bool get isBelumSync => !isSynced;

  String get statusDisplay {
    switch (status) {
      case StatusLaporan.menungguKlasifikasi:
        return 'Menunggu';
      case StatusLaporan.diproses:
        return 'Proses';
      case StatusLaporan.selesai:
        return 'Selesai';
      default:
        return status;
    }
  }

  // ======================
  // COPY WITH
  // ======================
  LaporanLokal copyWith({
    String? namaSarana,
    String? keteranganKerusakan,
    String? lokasiPerbaikan,
    String? nomorInventaris,
    String? fotoLokalPath,
    String? fotoKerusakanUrl,
    String? status,
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
      nomorInventaris: nomorInventaris ?? this.nomorInventaris,
      fotoLokalPath: fotoLokalPath ?? this.fotoLokalPath,
      fotoKerusakanUrl: fotoKerusakanUrl ?? this.fotoKerusakanUrl,
      status: status ?? this.status,
      pelaporId: pelaporId,
      isSynced: isSynced ?? this.isSynced,
      tandaTanganPelapor:
          tandaTanganPelapor ?? this.tandaTanganPelapor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}