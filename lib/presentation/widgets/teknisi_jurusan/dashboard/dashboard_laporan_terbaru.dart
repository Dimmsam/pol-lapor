import 'package:flutter/material.dart';
import '../../../../../data/models/laporan_lokal.dart';
import '../../../../../data/models/user_session.dart';
import '../../../../../core/utils/date_extension.dart';
import '../../common/status_badge.dart';

class DashboardTeknisiLaporanTerbaru extends StatelessWidget {
  final List<LaporanLokal> laporanTerbaru;
  final UserSession userSession;
  final Color primaryColor;
  final VoidCallback? onLihatSemua;

  const DashboardTeknisiLaporanTerbaru({
    super.key,
    required this.laporanTerbaru,
    required this.userSession,
    required this.primaryColor,
    this.onLihatSemua,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 12),
        if (laporanTerbaru.isEmpty)
          _buildEmptyState()
        else
          ...laporanTerbaru.take(5).map((laporan) => _buildCardLaporan(context, laporan)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Laporan Terbaru',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        TextButton(
          onPressed: onLihatSemua,
          child: Text(
            'Lihat Semua',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardLaporan(BuildContext context, LaporanLokal laporan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: laporan.fotoKerusakanUrl != null
              ? Image.network(
                  laporan.fotoKerusakanUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFotoPlaceholder(),
                )
              : _buildFotoPlaceholder(),
        ),
        title: Text(
          laporan.namaSarana,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1A1A2E),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 13, color: Colors.grey),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    laporan.lokasiPerbaikan,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  laporan.createdAt.toFormatted(),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                LaporanTeknisiStatusBadge(status: laporan.status),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/detail-laporan-teknisi',
            arguments: {
              'laporan': laporan,
              'userSession': userSession,
            },
          );
        },
      ),
    );
  }

  Widget _buildFotoPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Belum ada laporan',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
