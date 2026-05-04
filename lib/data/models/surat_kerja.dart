// lib/data/models/surat_kerja.dart
// Nama Pembuat: Dimas Rizal Ramadhani
// Model data Surat Kerja yang diterima Teknisi UPT-PP dari Supabase
// Sesuai skema DB: nomor_surat_kerja nullable, teknisi_id nullable,
// tanggal_target_selesai nullable.

import 'penanganan.dart';

class SuratKerja {
  final String suratKerjaId;
  final String formulirId;
  final String? suratPengajuanId;
  final String? nomorSuratKerja; // nullable di DB
  final DateTime tanggalTerbit;
  final String jenisPelaksana; // 'internal' | 'vendor'
  final String adminUptId;
  final String? teknisiId; // nullable — vendor tidak punya teknisi
  final String? namaVendor;
  final String? kontakVendor;
  final String instruksiKerja;
  final DateTime? tanggalTargetSelesai; // nullable di DB
  final DateTime createdAt;

  // Join dari formulir_laporan
  final String? namaSarana;
  final String? keteranganKerusakan;
  final String? lokasiPerbaikan;
  final String? nomorInventaris;
  final String? fotoKerusakanUrl;
  final String? statusFormulir;

  // Join dari penanganan (jika sudah ada)
  final PenangananRingkas? penanganan;

  const SuratKerja({
    required this.suratKerjaId,
    required this.formulirId,
    this.suratPengajuanId,
    this.nomorSuratKerja,
    required this.tanggalTerbit,
    required this.jenisPelaksana,
    required this.adminUptId,
    this.teknisiId,
    this.namaVendor,
    this.kontakVendor,
    required this.instruksiKerja,
    this.tanggalTargetSelesai,
    required this.createdAt,
    this.namaSarana,
    this.keteranganKerusakan,
    this.lokasiPerbaikan,
    this.nomorInventaris,
    this.fotoKerusakanUrl,
    this.statusFormulir,
    this.penanganan,
  });

  factory SuratKerja.fromJson(Map<String, dynamic> json) {
    // penanganan bisa berupa list (dari join) atau null
    PenangananRingkas? penanganan;
    final penangananData = json['penanganan'];
    if (penangananData != null) {
      if (penangananData is List && penangananData.isNotEmpty) {
        penanganan = PenangananRingkas.fromJson(
          penangananData.first as Map<String, dynamic>,
        );
      } else if (penangananData is Map<String, dynamic>) {
        penanganan = PenangananRingkas.fromJson(penangananData);
      }
    }

    // Ambil data formulir dari nested join
    final formulirData = json['formulir_laporan'];

    return SuratKerja(
      suratKerjaId: json['surat_kerja_id'] as String,
      formulirId: json['formulir_id'] as String,
      suratPengajuanId: json['surat_pengajuan_id'] as String?,
      nomorSuratKerja: json['nomor_surat_kerja'] as String?,
      tanggalTerbit: DateTime.parse(json['tanggal_terbit'] as String),
      jenisPelaksana: json['jenis_pelaksana'] as String? ?? 'internal',
      adminUptId: json['admin_upt_id'] as String,
      teknisiId: json['teknisi_id'] as String?,
      namaVendor: json['nama_vendor'] as String?,
      kontakVendor: json['kontak_vendor'] as String?,
      instruksiKerja: json['instruksi_kerja'] as String? ?? '',
      tanggalTargetSelesai: json['tanggal_target_selesai'] != null
          ? DateTime.parse(json['tanggal_target_selesai'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      namaSarana: formulirData?['nama_sarana'] as String?,
      keteranganKerusakan: formulirData?['keterangan_kerusakan'] as String?,
      lokasiPerbaikan: formulirData?['lokasi_perbaikan'] as String?,
      nomorInventaris: formulirData?['nomor_inventaris'] as String?,
      fotoKerusakanUrl: formulirData?['foto_kerusakan_url'] as String?,
      statusFormulir: formulirData?['status'] as String?,
      penanganan: penanganan,
    );
  }

  /// Apakah tugas sudah melewati target selesai?
  bool get isOverdue =>
      tanggalTargetSelesai != null &&
      DateTime.now().isAfter(tanggalTargetSelesai!) &&
      !(StatusPenanganan.isSelesai(penanganan?.statusPenanganan ?? ''));

  /// Status tampilan untuk UI berdasarkan enum DB
  String get statusDisplay {
    final s = penanganan?.statusPenanganan;
    if (s == null) return 'Belum Dimulai';
    return StatusPenanganan.toLabel(s);
  }

  /// Apakah penanganan sudah aktif (sudah ada record)?
  bool get sudahDimulai => penanganan != null;

  /// Apakah sudah selesai?
  bool get sudahSelesai =>
      penanganan != null &&
      StatusPenanganan.isSelesai(penanganan!.statusPenanganan);
}

/// Ringkasan data penanganan (subset kolom untuk list & detail view)
class PenangananRingkas {
  final String penangananId;
  final String statusPenanganan; // enum: mulai_dikerjakan | sedang_dikerjakan | selesai
  final String? catatanProgres;
  final List<String> fotoProgresUrl; // ARRAY di DB
  final String? fotoHasilUrl;
  final String? deskripsiHasil;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;

  const PenangananRingkas({
    required this.penangananId,
    required this.statusPenanganan,
    this.catatanProgres,
    this.fotoProgresUrl = const [],
    this.fotoHasilUrl,
    this.deskripsiHasil,
    this.tanggalMulai,
    this.tanggalSelesai,
  });

  factory PenangananRingkas.fromJson(Map<String, dynamic> json) {
    List<String> parseFotoProgres(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return PenangananRingkas(
      penangananId: json['penanganan_id'] as String,
      statusPenanganan:
          json['status_penanganan'] as String? ?? StatusPenanganan.mulaiDikerjakan,
      catatanProgres: json['catatan_progres'] as String?,
      fotoProgresUrl: parseFotoProgres(json['foto_progres_url']),
      fotoHasilUrl: json['foto_hasil_url'] as String?,
      deskripsiHasil: json['deskripsi_hasil'] as String?,
      tanggalMulai: json['tanggal_mulai'] != null
          ? DateTime.parse(json['tanggal_mulai'] as String)
          : null,
      tanggalSelesai: json['tanggal_selesai'] != null
          ? DateTime.parse(json['tanggal_selesai'] as String)
          : null,
    );
  }
}