import 'package:flutter/material.dart';
import '../../../../core/utils/laporan_icon_mapper.dart';

class LaporanEmptyState extends StatelessWidget {
  final String filterStatus;
  final bool isPublic;

  const LaporanEmptyState({
    super.key,
    required this.filterStatus,
    required this.isPublic,
  });

  @override
  Widget build(BuildContext context) {
    final emptyData = LaporanIconMapper.getEmptyStateData(filterStatus, isPublic);
    final message = emptyData['message']!;
    final sub = emptyData['sub']!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: Color(0xFF4F46E5),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
