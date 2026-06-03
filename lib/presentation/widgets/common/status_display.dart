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
    switch (status) {
      case StatusLaporan.selesai:
        return (
          label: StatusLaporan.toLabel(status),
          background: const Color(0xFFD1FAE5),
          foreground: const Color(0xFF065F46),
        );
      case StatusLaporan.diproses:
        return (
          label: StatusLaporan.toLabel(status),
          background: const Color(0xFFFEF3C7),
          foreground: const Color(0xFFB45309),
        );
      default:
        return (
          label: StatusLaporan.toLabel(status),
          background: const Color(0xFFF3F4F6),
          foreground: const Color(0xFF6B7280),
        );
    }
  }

  /// Badge outlined untuk kartu laporan di layar teknisi.
  static ({String label, Color color}) laporanTeknisi(String status) {
    switch (status) {
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
      case StatusPenanganan.selesai:
        return (label: StatusPenanganan.toLabel(status), color: greenSelesai);
      case StatusPenanganan.mulaiDikerjakan:
      default:
        return (label: StatusPenanganan.toLabel(status), color: blueDikerjakan);
    }
  }

  // ── Prioritas tugas (berdasarkan status laporan) ─────────────────────────

  static ({String label, Color color}) prioritas(String laporanStatus) {
    switch (laporanStatus) {
      case StatusLaporan.menungguKlasifikasi:
        return (label: 'High', color: Colors.red);
      case StatusLaporan.diproses:
        return (label: 'Medium', color: accentOrange);
      case StatusLaporan.selesai:
        return (label: 'Low', color: greenSelesai);
      default:
        return (label: 'Medium', color: accentOrange);
    }
  }
}
