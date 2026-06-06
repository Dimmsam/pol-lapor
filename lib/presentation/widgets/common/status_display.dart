import 'package:flutter/material.dart';

import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/penanganan.dart';

/// Warna & label terpusat untuk badge status di seluruh aplikasi.
class StatusDisplay {
  StatusDisplay._();

  static const Color accentOrange = Color(0xFFFF6F00);
  static const Color blueDikerjakan = Color(0xFF1565C0);
  static const Color greenSelesai = Color(0xFF2E7D32);

  // ── Laporan (pelapor) ───────────────────────────────────────────────────

  static ({String label, Color background, Color foreground}) laporan(
    String status,
  ) {
    // Normalisasi string untuk mengantisipasi perbedaan format dari database/server
    final statusLower = status.toLowerCase();

    // 1. CEK STATUS DITOLAK TERLEBIH DAHULU
    if (statusLower == 'ditolak') {
      return (
        label: 'Ditolak',
        background: const Color(0xFFFEE2E2), // Merah pudar
        foreground: const Color(0xFF991B1B), // Merah tegas
      );
    }

    // 2. CEK STATUS ESKALASI / EKSKALASI AGAR SINKRON (Bug 7)
    if (statusLower == 'eskalasi' || statusLower == 'ekskalasi') {
      return (
        label: 'Eskalasi',
        background: const Color(0xFFE0F2FE), // Biru muda langit (Cyan pudar)
        foreground: const Color(0xFF0369A1), // Biru langit tegas (Cyan tua)
      );
    }

    if (statusLower == 'ditolak_eskalasi' || statusLower == 'ditolak eskalasi') {
      return (
        label: 'Eskalasi Ditolak',
        background: const Color(0xFFFEE2E2),
        foreground: const Color(0xFF991B1B),
      );
    }

    // 3. JALANKAN SWITCH CASE ASLI UNTUK STATUS STANDAR LAINNYA
    switch (status) {
      case StatusLaporan.selesai:
        return (
          label: StatusLaporan.toLabel(status),
          background: const Color(0xFFD1FAE5), // Hijau pudar
          foreground: const Color(0xFF065F46), // Hijau tua
        );
      case 'sedang_dikerjakan':
      case StatusLaporan.diproses:
        return (
          label: StatusLaporan.toLabel(status),
          background: const Color(0xFFFEF3C7), // Kuning pudar
          foreground: const Color(0xFFB45309), // Cokelat/Oranye tua
        );
      case 'ditugaskan':
        return (
          label: StatusLaporan.toLabel(status),
          background: const Color(0xFFDBEAFE), // Biru muda (sesuaikan jika perlu)
          foreground: const Color(0xFF1D4ED8), // Biru tua
        );
      case 'menunggu':
      case StatusLaporan.menungguKlasifikasi:
        return (
          label: StatusLaporan.toLabel(status),
          background: const Color(0xFFEFF6FF), // Biru pudar
          foreground: const Color(0xFF1E40AF), // Biru tua
        );
      default:
        return (
          label: StatusLaporan.toLabel(status),
          background: const Color(0xFFF3F4F6), // Abu-abu pudar
          foreground: const Color(0xFF6B7280), // Abu-abu tua
        );
    }
  }

  /// Badge outlined untuk kartu laporan di layar teknisi.
  static ({String label, Color color}) laporanTeknisi(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'eskalasi' || statusLower == 'ekskalasi') {
      return (label: 'Eskalasi', color: Colors.purple);
    }
    if (statusLower == 'ditolak_eskalasi' || statusLower == 'ditolak eskalasi') {
      return (label: 'Eskalasi Ditolak', color: Colors.red);
    }
    if (statusLower == 'ditolak') {
      return (label: 'Ditolak', color: Colors.red);
    }

    switch (status) {
      case 'ditugaskan':
        return (label: StatusLaporan.toLabelTeknisi(status), color: blueDikerjakan);
      case 'sedang_dikerjakan':
      case StatusLaporan.diproses:
        return (label: StatusLaporan.toLabelTeknisi(status), color: blueDikerjakan);
      case StatusLaporan.selesai:
        return (label: StatusLaporan.toLabelTeknisi(status), color: greenSelesai);
      default:
        return (label: StatusLaporan.toLabelTeknisi(status), color: accentOrange);
    }
  }

  // ── Penanganan (teknisi) ─────────────────────────────────────────────────

  static ({String label, Color color}) penanganan(String? status) {
    if (status == null) {
      return (label: 'Menunggu', color: accentOrange);
    }
    switch (status) {
      case StatusPenanganan.ditolakEskalasi:
        return (label: StatusPenanganan.toLabel(status), color: Colors.red);
      case StatusPenanganan.selesai:
        return (label: StatusPenanganan.toLabel(status), color: greenSelesai);
      case StatusPenanganan.mulaiDikerjakan:
      default:
        return (label: StatusPenanganan.toLabel(status), color: blueDikerjakan);
    }
  }

  // ── Prioritas tugas (berdasarkan status laporan) ─────────────────────────

  static ({String label, Color color}) prioritas(String laporanPrioritas) {
    final prioritasLower = laporanPrioritas.toLowerCase();
    
    switch (prioritasLower) {
      case 'sangat_urgent':
      case 'sangat urgent':
        return (label: 'High', color: Colors.red);
      case 'urgent':
        return (label: 'Medium', color: accentOrange);
      case 'biasa':
        return (label: 'Low', color: greenSelesai);
      default:
        return (label: 'Medium', color: accentOrange);
    }
  }
}