// ============================================================
// Nama Pembuat : Rina Permata Dewi
// NIM          : 241511061
// File         : dashboard_teknisi_jurusan_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/teknisi_dashboard_provider.dart';
import '../../../data/models/user_session.dart';
import '../../widgets/teknisi_jurusan/bottom_nav/bottom_nav_teknisi.dart'; // ← pakai navbar baru
import 'profil_teknisi_screen.dart';
import 'daftar_tugas_screen.dart';
import '../../widgets/teknisi_jurusan/dashboard/dashboard_header.dart';
import '../../widgets/teknisi_jurusan/dashboard/dashboard_ikhtisar.dart';
import '../../widgets/teknisi_jurusan/dashboard/dashboard_laporan_terbaru.dart';

class DashboardTeknisiJurusanScreen extends StatefulWidget {
  final UserSession userSession;

  const DashboardTeknisiJurusanScreen({super.key, required this.userSession});

  @override
  State<DashboardTeknisiJurusanScreen> createState() =>
      _DashboardTeknisiJurusanScreenState();
}

class _DashboardTeknisiJurusanScreenState
    extends State<DashboardTeknisiJurusanScreen> {
  static const Color _primaryColor = Color(0xFF1A237E);
  static const Color _accentColor = Color(0xFFFF6F00);
  static const Color _bgColor = Color(0xFFF5F6FA);

  int _currentNavIndex = 0; // 0 = Beranda

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiDashboardProvider>().loadDashboard(
        teknisiId: widget.userSession.userId,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildDashboardContent(),
            DaftarTugasScreen(userSession: widget.userSession),
            ProfilTeknisiScreen(userSession: widget.userSession),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavTeknisi(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        primaryColor: _primaryColor,
        accentColor: _accentColor,
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Consumer<TeknisiDashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryColor),
          );
        }

        return RefreshIndicator(
          color: _primaryColor,
          onRefresh: () =>
              provider.loadDashboard(teknisiId: widget.userSession.userId),
          child: CustomScrollView(
            slivers: [
              DashboardTeknisiHeader(
                userSession: widget.userSession,
                primaryColor: _primaryColor,
                accentColor: _accentColor,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    DashboardTeknisiIkhtisar(
                      provider: provider,
                      accentColor: _accentColor,
                    ),
                    const SizedBox(height: 20),
                    DashboardTeknisiLaporanTerbaru(
                      laporanTerbaru: provider.laporanTerbaru,
                      userSession: widget.userSession,
                      primaryColor: _primaryColor,
                      onLihatSemua: () {
                        // Pindah ke tab Daftar Tugas (index 1) tanpa push route baru
                        setState(() => _currentNavIndex = 1);
                      },
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  // =========================================================================
  // HELPER METHODS
  // =========================================================================




}
