// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/laporan_provider.dart';
import '../../../logic/providers/notifikasi_provider.dart';
import '../../../presentation/widgets/pelapor/dashboard/dashboard_top_bar.dart';
import '../../../presentation/widgets/pelapor/dashboard/dashboard_greeting_section.dart';
import '../../../presentation/widgets/pelapor/dashboard/dashboard_stat_section.dart';
import '../../../presentation/widgets/pelapor/dashboard/dashboard_notif_section.dart';
import '../../../presentation/widgets/pelapor/dashboard/dashboard_recent_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color _bg = Color(0xFFF4F6FA);

  @override
Widget build(BuildContext context) {
  final provider = context.watch<LaporanProvider>();

  return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            DashboardTopBar(namaUser: provider.namaUser),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardGreetingSection(namaUser: provider.namaUser),
                    const SizedBox(height: 16),
                    DashboardStatSection(provider: provider),
                    const SizedBox(height: 16),

                    const DashboardNotifSection(),

                    const SizedBox(height: 20),
                    const DashboardRecentSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
