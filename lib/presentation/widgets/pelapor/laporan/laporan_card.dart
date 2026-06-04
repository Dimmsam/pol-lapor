import 'package:flutter/material.dart';
import '../../../../data/models/laporan_lokal.dart';
import '../../../../core/utils/laporan_icon_mapper.dart';
import '../../../../core/utils/date_extension.dart';
import '../../../widgets/common/status_badge.dart';
import '../../../screens/pelapor/detail_laporan_screen.dart';
import 'laporan_action_button.dart';

class LaporanCard extends StatelessWidget {
  final LaporanLokal laporan;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit; 

  const LaporanCard({
    super.key,
    required this.laporan,
    required this.canDelete,
    required this.onDelete,
    this.onEdit,
  });

  IconData get _icon => LaporanIconMapper.getIconForSarana(laporan.namaSarana);

  @override
  Widget build(BuildContext context) {
    // Normalisasi status string agar tidak sensitif terhadap huruf kapital/kecil
    final currentStatus = laporan.status.toLowerCase();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailLaporanScreen(laporan: laporan),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9ECEF), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris atas: ikon + nama + lokasi + status badge ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _icon,
                      color: const Color(0xFF0D47A1),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          laporan.namaSarana,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          laporan.lokasiPerbaikan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: laporan.status),
                ],
              ),

              // ── Divider ──────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Divider(
                  height: 0,
                  thickness: 0.5,
                  color: Color(0xFFF3F4F6),
                ),
              ),

              // ── Keterangan kerusakan ─────────────────────────────────────
              Text(
                laporan.keteranganKerusakan,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),

              // ── Footer: tanggal + sync + tombol aksi ─────────────────────
              Row(
                children: [
                  // Tanggal
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    laporan.createdAt.toFormatted(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),

                  // Indikator belum sinkron
                  if (!laporan.isSynced) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Belum tersinkron',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // ── Tombol Edit ──
                  // Dikunci kondisinya agar tetap muncul jika statusnya menunggu klasifikasi atau ditolak
                  if (onEdit != null && 
                      (currentStatus == 'menunggu' || 
                       currentStatus == 'menungguklasifikasi' || 
                       currentStatus == 'ditolak')) ...[
                    LaporanActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: currentStatus == 'ditolak'
                          ? const Color(0xFFDC2626) // Merah tegas jika ditolak
                          : const Color(0xFF0D47A1), // Biru jika menunggu
                      bgColor: currentStatus == 'ditolak'
                          ? const Color(0xFFFEE2E2) // Merah pudar
                          : const Color(0xFFEEF2FF), // Biru pudar
                      onTap: onEdit!,
                    ),
                    const SizedBox(width: 8),
                  ],

                  // ── Tombol Hapus (hanya milik sendiri) ────────────────────
                  if (canDelete && onDelete != null)
                    LaporanActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Hapus',
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
                      onTap: onDelete!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}