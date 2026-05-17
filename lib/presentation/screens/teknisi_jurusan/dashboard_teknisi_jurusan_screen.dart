// ============================================================
// Nama Pembuat : Rina Permata Dewi
// NIM          : 241511061
// File         : dashboard_teknisi_jurusan_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/teknisi_jurusan_provider.dart';
import '../../../data/models/user_session.dart';
import '../../../data/models/laporan_lokal.dart';
import 'widgets/bottom_nav_teknisi.dart'; // ← pakai navbar baru

class DashboardTeknisiJurusanScreen extends StatefulWidget {
  final UserSession userSession;

  const DashboardTeknisiJurusanScreen({
    super.key,
    required this.userSession,
  });

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
      context
          .read<TeknisiJurusanProvider>()
          .loadDashboard(teknisiId: widget.userSession.userId);
    });
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        // Sudah di Beranda, tidak perlu navigate
        break;
      case 1:
        // Navigate ke Daftar Tugas
        Navigator.pushReplacementNamed(
          context,
          '/daftar-tugas-teknisi-jurusan',
          arguments: widget.userSession,
        );
        break;
      case 2:
        // TODO: Navigate ke ProfilScreen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Consumer<TeknisiJurusanProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: _primaryColor),
              );
            }

            return RefreshIndicator(
              color: _primaryColor,
              onRefresh: () => provider.loadDashboard(
                teknisiId: widget.userSession.userId,
              ),
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 16),
                        _buildIkhtisarTugas(provider),
                        const SizedBox(height: 20),
                        _buildHeaderLaporanTerbaru(),
                        const SizedBox(height: 12),
                        if (provider.laporanTerbaru.isEmpty)
                          _buildEmptyState()
                        else
                          ...provider.laporanTerbaru
                              .take(5)
                              .map((laporan) => _buildCardLaporan(laporan)),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavTeknisi(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
        primaryColor: _primaryColor,
        accentColor: _accentColor,
      ),
    );
  }

  // =========================================================================
  // WIDGET BUILDERS
  // =========================================================================

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _accentColor,
                        child: Text(
                          _getInitial(widget.userSession.nama),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${_getRoleLabel(widget.userSession.role)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            widget.userSession.nama,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Navigate ke NotifikasiScreen
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIkhtisarTugas(TeknisiJurusanProvider provider) {
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
                  valueColor: _accentColor,
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

  /// Header "Laporan Terbaru" + tombol "Lihat Semua" → navigate ke daftar tugas
  Widget _buildHeaderLaporanTerbaru() {
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
          onPressed: () {
            // ✅ Navigate ke Daftar Tugas
            Navigator.pushReplacementNamed(
              context,
              '/daftar-tugas-teknisi-jurusan',
              arguments: widget.userSession,
            );
          },
          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardLaporan(LaporanLokal laporan) {
    final statusInfo = _getStatusInfo(laporan.status);

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
                _buildBadgeStatus(
                  label: statusInfo['label'] as String,
                  color: statusInfo['color'] as Color,
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate ke DetailLaporanScreen
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

  Widget _buildBadgeStatus({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
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

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  String _getInitial(String nama) {
    if (nama.isEmpty) return '?';
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nama[0].toUpperCase();
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'teknisi_jurusan':
      case 'teknisi':
        return 'Teknisi JTK';
      default:
        return role;
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case StatusLaporan.menungguKlasifikasi:
        return {'label': 'Menunggu', 'color': _accentColor};
      case StatusLaporan.diproses:
        return {'label': 'Dikerjakan', 'color': const Color(0xFF1565C0)};
      case StatusLaporan.selesai:
        return {'label': 'Selesai', 'color': const Color(0xFF2E7D32)};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }
}