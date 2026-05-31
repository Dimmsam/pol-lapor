import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../logic/providers/tracking_provider.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../data/models/laporan_lokal.dart';

class DetailTrackingStatus extends StatelessWidget {
  final LaporanLokal laporan;

  const DetailTrackingStatus({
    super.key,
    required this.laporan,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, tp, _) {
        final riwayat = tp.riwayatTracking;
        final stepsData = AppConstants.trackingStepsData;
        final currentStep = tp.currentStep;

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
                    final isCompleted = index < currentStep;
                    final isActive = index == currentStep;
                    final isWaiting = index > currentStep;
                    final isLast = index == stepsData.length - 1;

                    // Find the date
                    DateTime? stepDate;
                    final events = data['events'] as List<String>;
                    try {
                      final found = riwayat.firstWhere(
                          (r) => r.jenisEvent != null && events.contains(r.jenisEvent));
                      stepDate = found.createdAt;
                    } catch (_) {}

                    // Fallback using laporan creation for step 0 if not found
                    if (index == 0 && stepDate == null) {
                       stepDate = laporan.createdAt;
                    }

                    return _buildStepItem(
                      title: data['title'] as String,
                      date: stepDate,
                      isCompleted: isCompleted,
                      isActive: isActive,
                      isWaiting: isWaiting,
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
    required bool isCompleted,
    required bool isActive,
    required bool isWaiting,
    required bool isLast,
  }) {
    Color titleColor = isWaiting ? const Color(0xFF9CA3AF) : (isActive ? const Color(0xFF2563EB) : const Color(0xFF1F2937));
    Color subtitleColor = isWaiting ? const Color(0xFFD1D5DB) : const Color(0xFF9CA3AF);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _buildIndicator(isCompleted: isCompleted, isActive: isActive, isWaiting: isWaiting),
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
                      fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isWaiting ? 'Menunggu...' : _formatTrackingDate(date),
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required bool isCompleted, required bool isActive, required bool isWaiting}) {
    if (isCompleted) {
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

  String _formatTrackingDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dateTime.day;
    final month = monthNames[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month, $hour:$minute';
  }
}
