import 'package:flutter/material.dart';

import '../../../data/models/penanganan.dart';
import '../../../data/models/laporan_lokal.dart';
import 'status_display.dart';

/// Badge status laporan untuk pelapor (pill, background penuh).
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final style = StatusDisplay.laporan(status);
    return _FilledBadge(
      label: style.label,
      background: style.background,
      foreground: style.foreground,
    );
  }
}

/// Badge status laporan di layar teknisi (outlined).
class LaporanTeknisiStatusBadge extends StatelessWidget {
  final String status;

  const LaporanTeknisiStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final style = StatusDisplay.laporanTeknisi(status);
    return OutlinedStatusBadge(label: style.label, color: style.color);
  }
}

/// Badge prioritas.
class PrioritasBadge extends StatelessWidget {
  final String prioritas;

  const PrioritasBadge({super.key, required this.prioritas});

  @override
  Widget build(BuildContext context) {
    final style = StatusDisplay.prioritas(prioritas);
    return _FilledBadge(
      label: style.label,
      background: style.color.withValues(alpha: 0.15),
      foreground: style.color,
    );
  }
}

/// Badge status penanganan untuk daftar tugas & detail teknisi.
class PenangananStatusBadge extends StatelessWidget {
  final String? statusPenanganan;
  final LaporanLokal? laporan;

  const PenangananStatusBadge({super.key, this.statusPenanganan, this.laporan});

  @override
  Widget build(BuildContext context) {
    // Prioritaskan status laporan jika sudah selesai atau dieskalasi
    if (laporan != null) {
      if (laporan!.status == StatusLaporan.selesai) {
        return OutlinedStatusBadge(label: 'Selesai', color: StatusDisplay.greenSelesai);
      } else if (laporan!.status == StatusLaporan.diteruskanKePusat || 
                 laporan!.status == StatusLaporan.menungguPersetujuanKajur) {
        return OutlinedStatusBadge(label: 'Eskalasi', color: StatusDisplay.accentOrange);
      }
    }

    final style = StatusDisplay.penanganan(statusPenanganan);
    return OutlinedStatusBadge(label: style.label, color: style.color);
  }

  factory PenangananStatusBadge.fromPenanganan(Penanganan? penanganan, {LaporanLokal? laporan}) {
    // Jika ada penanganan tapi teknisi belum update progres sama sekali,
    // kita override statusnya menjadi null agar UI menampilkan 'Menunggu'.
    String? statusToDisplay = penanganan?.statusPenanganan;
    if (penanganan != null && 
        penanganan.catatanProgres == null && 
        penanganan.fotoProgresUrl.isEmpty && 
        statusToDisplay != StatusPenanganan.selesai) {
      statusToDisplay = null;
    }

    return PenangananStatusBadge(
      statusPenanganan: statusToDisplay,
      laporan: laporan,
    );
  }
}



/// Badge outlined generik (label + warna aksen).
class OutlinedStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;
  final EdgeInsets padding;

  const OutlinedStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FilledBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _FilledBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
