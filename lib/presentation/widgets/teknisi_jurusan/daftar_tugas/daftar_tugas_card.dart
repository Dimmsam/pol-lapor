import 'package:flutter/material.dart';
import '../../../../../data/models/laporan_lokal.dart';
import '../../../../../data/models/penanganan.dart';
import '../../../../../data/models/user_session.dart';
import '../../common/status_badge.dart';
import '../../../../../presentation/screens/teknisi_jurusan/detail_laporan_teknisi_screen.dart';

class DaftarTugasCard extends StatelessWidget {
  final LaporanLokal laporan;
  final Penanganan? penanganan;
  final UserSession userSession;
  final Color accentColor;

  const DaftarTugasCard({
    super.key,
    required this.laporan,
    required this.penanganan,
    required this.userSession,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Foto + Info Utama ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto kerusakan
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: laporan.fotoKerusakanUrl != null
                    ? Image.network(
                        laporan.fotoKerusakanUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fotoPlaceholder(),
                      )
                    : _fotoPlaceholder(),
              ),

              // Info laporan
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul + badge prioritas
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              laporan.namaSarana,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PrioritasBadge(laporanStatus: laporan.status),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Lokasi
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              laporan.lokasiPerbaikan,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Divider ────────────────────────────────────────────────────
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Footer: Status + Tombol Detail ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge status penanganan
                PenangananStatusBadge.fromPenanganan(penanganan, laporan: laporan),

                // Tombol Detail →
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailLaporanTeknisiScreen(
                          laporan: laporan,
                          userSession: userSession,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Detail'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fotoPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    );
  }
}
