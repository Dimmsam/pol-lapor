import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../logic/providers/laporan_provider.dart';
import 'dashboard_report_item.dart';

class DashboardRecentSection extends StatelessWidget {
  const DashboardRecentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<LaporanProvider>().recentLaporan();

    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Belum ada laporan'),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Laporan Terbaru',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B3E),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: data.map((laporan) {
              return Column(
                children: [
                  DashboardReportItem(
                    icon: Icons.report_problem_outlined,
                    title: laporan.namaSarana,
                    location: laporan.lokasiPerbaikan,
                    status: laporan.status,
                  ),
                  const SizedBox(height: 9),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
