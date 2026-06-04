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

// DIUBAH MENJADI STATEFUL WIDGET AGAR BISA MEMACU LIFECYCLE SYNC AUTOMATIS
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _bg = Color(0xFFF4F6FA);

  @override
  void initState() {
    super.initState();
    // Menjalankan sinkronisasi data dari server Supabase di background saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LaporanProvider>().syncFromRemote();
    });
  }

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
              // SISIPAN BARU: Ditambahkan RefreshIndicator agar user bisa pull-to-refresh secara responsif
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<LaporanProvider>().syncFromRemote();
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(), // Memastikan halaman selalu bisa ditarik walau konten sedikit
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}