import 'package:flutter/material.dart';
import '../../../../../logic/providers/teknisi_dashboard_provider.dart';

class DashboardTeknisiIkhtisar extends StatelessWidget {
  final TeknisiDashboardProvider provider;
  final Color accentColor;

  const DashboardTeknisiIkhtisar({
    super.key,
    required this.provider,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ikhtisar Tugas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Menunggu',
                  value: provider.stats['belum_dimulai'] ?? 0,
                  valueColor: accentColor,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  label: 'Dikerjakan',
                  value: provider.stats['aktif'] ?? 0,
                  valueColor: Colors.red,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  label: 'Selesai',
                  value: provider.stats['selesai'] ?? 0,
                  valueColor: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required int value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 50, color: Colors.grey.shade200);
  }
}
