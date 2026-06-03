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
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/string_extension.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/penanganan.dart';
import '../../../data/models/user_session.dart';
import '../../widgets/teknisi_jurusan/daftar_tugas/daftar_tugas_card.dart';
import '../../widgets/teknisi_jurusan/daftar_tugas/daftar_tugas_filter.dart';
import '../../widgets/teknisi_jurusan/daftar_tugas/daftar_tugas_empty.dart';

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

  // ─── Tab Filter ──────────────────────────────────────────────────────────
  final List<_TabFilter> _tabs = const [
    _TabFilter(label: 'Semua', filterStatus: null),
    _TabFilter(
      label: 'Menunggu',
      filterStatus: StatusPenanganan.mulaiDikerjakan,
    ),
    _TabFilter(
      label: 'Dikerjakan',
      filterStatus: StatusPenanganan.mulaiDikerjakan,
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
            DaftarTugasFilter(
              tabController: _tabController,
              tabs: _tabs.map((t) {
                return Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(t.label),
                  ),
                );
              }).toList(),
              primaryColor: _primaryColor,
            ),

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
              widget.userSession.nama.toInitials(),
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



  /// List tugas berdasarkan filter tab
  Widget _buildListTugas(
    List<LaporanLokal> laporan,
    PenangananProvider provider,
  ) {
    final listToShow = laporan;

    if (listToShow.isEmpty) return const DaftarTugasEmpty();

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
    return DaftarTugasCard(
      laporan: laporan,
      penanganan: penanganan,
      userSession: widget.userSession,
      accentColor: _accentColor,
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
}

// ─── Model Tab Filter ─────────────────────────────────────────────────────────
class _TabFilter {
  final String label;
  final String? filterStatus;
  const _TabFilter({required this.label, this.filterStatus});
}
