import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/laporan_lokal.dart';
import '../../../../logic/providers/tracking_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_extension.dart';

class DetailTrackingCard extends StatelessWidget {
  final LaporanLokal laporan;

  const DetailTrackingCard({super.key, required this.laporan});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, tp, _) {
        final riwayat = tp.riwayatTracking;
        // Pelapor: hanya tampilkan step eskalasi setelah admin review
        final showEskalasi = tp.hasEskalasiPelapor;
        final stepsData = AppConstants.buildTrackingSteps(showEskalasi: showEskalasi);
        final currentStep = tp.currentStepFor(stepsData);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Laporan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              if (tp.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: List.generate(stepsData.length, (index) {
                    final data = stepsData[index];
                    final events = data['events'] as List<String>;

                    // Cari tanggal dan narasi dari riwayat
                    DateTime? stepDate;
                    String? pesanNarasi;
                    try {
                      final found = riwayat.lastWhere(
                          (r) => r.jenisEvent != null && events.contains(r.jenisEvent));
                      stepDate = found.createdAt;
                      pesanNarasi = found.pesanNarasi;
                    } catch (_) {}

                    // Fallback: step 0 pakai tanggal laporan
                    if (index == 0 && stepDate == null) {
                      stepDate = laporan.createdAt;
                    }

                    // --- State computation ---
                    final isCompleted = index < currentStep;
                    final isActive = index == currentStep;
                    final hasMatchingEvent = riwayat.any((e) => events.contains(e.jenisEvent));
                    // Step yang pernah dikunjungi tapi currentStep sudah mundur
                    final isRolledBack = !isCompleted && !isActive && hasMatchingEvent;
                    final isWaiting = !isCompleted && !isActive && !isRolledBack;

                    // Cek apakah step ini punya event penolakan
                    final hasRejectionEvent = 
                        (events.contains('laporan_ditolak') && riwayat.any((e) => e.jenisEvent == 'laporan_ditolak')) ||
                        (events.contains('eskalasi_ditolak') && riwayat.any((e) => e.jenisEvent == 'eskalasi_ditolak'));
                    // Rejected style: rolled-back step ATAU step aktif yang ditolak
                    final isRejected = isRolledBack || (isActive && hasRejectionEvent);
                    final isLast = index == stepsData.length - 1;

                    // --- Dynamic title ---
                    String title = data['title'] as String;
                    if (events.contains('laporan_ditolak') && riwayat.any((e) => e.jenisEvent == 'laporan_ditolak')) {
                      title = 'Laporan Ditolak';
                    } else if (events.contains('eskalasi_dari_teknisi')) {
                      if (riwayat.any((e) => e.jenisEvent == 'eskalasi_ditolak')) {
                        title = 'Eskalasi Ditolak';
                      } else if (riwayat.any((e) => e.jenisEvent == 'kajur_approve_eskalasi' || e.jenisEvent == 'diteruskan_ke_pusat')) {
                        title = 'Diteruskan ke Pusat';
                      } else if (riwayat.any((e) => e.jenisEvent == 'eskalasi_disetujui')) {
                        title = 'Menunggu Persetujuan Kajur';
                      }
                    }

                    return _buildStepItem(
                      title: title,
                      date: stepDate,
                      pesanNarasi: (isRejected || isRolledBack) ? pesanNarasi : null,
                      isCompleted: isCompleted && !isRejected,
                      isActive: isActive && !isRejected,
                      isWaiting: isWaiting,
                      isRejected: isRejected,
                      isLast: isLast,
                    );
                  }),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepItem({
    required String title,
    DateTime? date,
    String? pesanNarasi,
    required bool isCompleted,
    required bool isActive,
    required bool isWaiting,
    required bool isRejected,
    required bool isLast,
  }) {
    Color titleColor;
    Color subtitleColor;

    if (isRejected) {
      titleColor = const Color(0xFFDC2626);
      subtitleColor = const Color(0xFFEF4444);
    } else if (isWaiting) {
      titleColor = const Color(0xFF9CA3AF);
      subtitleColor = const Color(0xFFD1D5DB);
    } else if (isActive) {
      titleColor = const Color(0xFF2563EB);
      subtitleColor = const Color(0xFF9CA3AF);
    } else {
      titleColor = const Color(0xFF1F2937);
      subtitleColor = const Color(0xFF9CA3AF);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicator column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _buildIndicator(isCompleted: isCompleted, isActive: isActive, isWaiting: isWaiting, isRejected: isRejected),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFF3F4F6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive || isCompleted || isRejected ? FontWeight.w600 : FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isWaiting ? 'Menunggu...' : (date?.toTrackingFormat() ?? ''),
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                  // Tampilkan narasi untuk step yang ditolak/di-rollback
                  if (pesanNarasi != null && pesanNarasi.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        pesanNarasi,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF991B1B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required bool isCompleted,
    required bool isActive,
    required bool isWaiting,
    required bool isRejected,
  }) {
    if (isRejected) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFFDC2626),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 16),
      );
    } else if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF2563EB),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    } else if (isActive) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1F2937), width: 2),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        ),
      );
    }
  }
}
