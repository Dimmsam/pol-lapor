// ============================================================
// Nama Pembuat : Rina Permata Dewi
// NIM          : 241511061
// File         : daftar_tugas_screen.dart
// Deskripsi    : Halaman Daftar Tugas untuk Teknisi Jurusan.
//                Menampilkan semua laporan yang di-assign ke teknisi
//                dengan filter tab: Semua | Menunggu | Dikerjakan.
//                Terhubung langsung ke Supabase via PenangananProvider.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/penanganan_provider.dart';
import '../../widgets/common/status_badge.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/penanganan.dart';
import '../../../data/models/user_session.dart';
import 'widgets/bottom_nav_teknisi.dart';
import 'detail_laporan_teknisi_screen.dart';
import 'profil_teknisi_screen.dart';

class DaftarTugasScreen extends StatefulWidget {
  final UserSession userSession;

  const DaftarTugasScreen({super.key, required this.userSession});

  @override
  State<DaftarTugasScreen> createState() => _DaftarTugasScreenState();
}

class _DaftarTugasScreenState extends State<DaftarTugasScreen>
    with SingleTickerProviderStateMixin {
  // ─── Konstanta Warna ─────────────────────────────────────────────────────
  static const Color _primaryColor = Color(0xFF1A237E);
  static const Color _accentColor = Color(0xFFFF6F00);
  static const Color _bgColor = Color(0xFFF5F6FA);

  // ─── State ───────────────────────────────────────────────────────────────
  late TabController _tabController;
  int _currentNavIndex = 1; // Tab "Tugas" aktif

  // ─── Tab Filter ──────────────────────────────────────────────────────────
  final List<_TabFilter> _tabs = const [
    _TabFilter(label: 'Semua', filterStatus: null),
    _TabFilter(
      label: 'Menunggu',
      filterStatus: StatusPenanganan.mulaiDikerjakan,
    ),
    _TabFilter(
      label: 'Dikerjakan',
      filterStatus: StatusPenanganan.sedangDikerjakan,
    ),
  ];

  // ─── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenangananProvider>().loadDaftarTugas(
        teknisiId: widget.userSession.userId,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Navigation ──────────────────────────────────────────────────────────
  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context,
          '/dashboard-teknisi-jurusan',
          arguments: widget.userSession,
        );
        break;
      case 1:
        // already on Tugas
        break;
      case 2:
        // Navigate to ProfilTeknisiScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilTeknisiScreen()),
        );
        break;
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(),

            // ── Tab Bar ─────────────────────────────────────────────────────
            _buildTabBar(),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: Consumer<PenangananProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return _buildErrorState(provider);
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tab) {
                      final filtered = provider.filterTugasByStatus(
                        tab.filterStatus,
                      );
                      return _buildListTugas(filtered, provider);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
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

  /// Header: logo + judul + avatar
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Logo teks
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Pol',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                TextSpan(
                  text: 'Lapor',
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Avatar teknisi
          CircleAvatar(
            radius: 18,
            backgroundColor: _primaryColor,
            child: Text(
              _getInitial(widget.userSession.nama),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section judul + deskripsi + tab filter
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Tugas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola dan selesaikan tugas pemeliharaan Anda hari ini.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tab filter: Semua | Menunggu | Dikerjakan
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: _primaryColor,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            indicator: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            tabs: _tabs.map((t) {
              return Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(t.label),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// List tugas berdasarkan filter tab
  Widget _buildListTugas(
    List<LaporanLokal> laporan,
    PenangananProvider provider,
  ) {
    // Jika daftar kosong, tampilkan satu laporan dummy lokal untuk pengujian
    final listToShow = laporan.isEmpty
        ? [
            LaporanLokal(
              formulirId: 'DUMMY-0001',
              namaSarana: 'Laboratorium Jaringan',
              keteranganKerusakan: 'Port LAN tidak berfungsi pada meja 3',
              lokasiPerbaikan: 'Gedung A - Lantai 2',
              nomorInventaris: 'INV-12345',
              fotoKerusakanUrl: null,
              status: StatusLaporan.diproses,
              pelaporId: 'pelapor-demo',
            ),
          ]
        : laporan;

    if (listToShow.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () =>
          provider.loadDaftarTugas(teknisiId: widget.userSession.userId),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: listToShow.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = listToShow[index];
          final penanganan = provider.getPenangananByFormulir(item.formulirId);
          return _buildCardTugas(item, penanganan, provider);
        },
      ),
    );
  }

  /// Kartu satu tugas
  Widget _buildCardTugas(
    LaporanLokal laporan,
    Penanganan? penanganan,
    PenangananProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Foto + Info Utama ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto kerusakan
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: laporan.fotoKerusakanUrl != null
                    ? Image.network(
                        laporan.fotoKerusakanUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fotoPlaceholder(),
                      )
                    : _fotoPlaceholder(),
              ),

              // Info laporan
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul + badge prioritas
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              laporan.namaSarana,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PrioritasBadge(laporanStatus: laporan.status),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Lokasi
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              laporan.lokasiPerbaikan,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Divider ────────────────────────────────────────────────────
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Footer: Status + Tombol Detail ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge status penanganan
                PenangananStatusBadge.fromPenanganan(penanganan),

                // Tombol Detail →
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailLaporanTeknisiScreen(
                          laporan: laporan,
                          userSession: widget.userSession,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Detail'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder foto jika tidak tersedia
  Widget _fotoPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tugas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tugas yang di-assign ke kamu\nakan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  /// Error state dengan tombol retry
  Widget _buildErrorState(PenangananProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'Gagal memuat data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                provider.loadDaftarTugas(teknisiId: widget.userSession.userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  /// Ambil inisial nama untuk avatar
  String _getInitial(String nama) {
    if (nama.isEmpty) return '?';
    final parts = nama.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nama[0].toUpperCase();
  }
}

// ─── Model Tab Filter ─────────────────────────────────────────────────────────
class _TabFilter {
  final String label;
  final String? filterStatus;
  const _TabFilter({required this.label, this.filterStatus});
}
