// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: laporan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../logic/providers/laporan_provider.dart';
import '../../widgets/pelapor/laporan/laporan_card.dart';
import '../../widgets/pelapor/laporan/laporan_empty_state.dart';
import 'form_laporan_screen.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  String _filterStatus = 'semua';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Fetch laporan publik dari server agar status selalu akurat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LaporanProvider>().fetchLaporanPublik();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Hapus laporan dengan konfirmasi ──────────────────────────────────────
  Future<void> _confirmDelete(
    BuildContext context,
    LaporanLokal laporan,
  ) async {
    final laporanProvider = context.read<LaporanProvider>();
    if (!laporanProvider.canDelete(laporan)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamu hanya bisa menghapus laporan milikmu sendiri'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Laporan?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Laporan "${laporan.namaSarana}" akan dihapus permanen dan tidak dapat dipulihkan.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(color: Color(0xFFE9ECEF)),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await laporanProvider.deleteLaporan(laporan);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Laporan berhasil dihapus'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus laporan: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  // ── Navigasi ke form edit ─────────────────────────────────────────────────
  void _navigateToEdit(BuildContext context, LaporanLokal laporan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormLaporanScreen(laporanEdit: laporan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildTabBar(),
              _buildSearchBar(),
              _buildFilterChips(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildList(isPublic: false),
                    _buildList(isPublic: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: const Row(
        children: [
          Text(
            'Daftar Laporan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1B3E),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: const TabBar(
        labelColor: Color(0xFF0D47A1),
        unselectedLabelColor: Color(0xFF6B7280),
        indicatorColor: Color(0xFF0D47A1),
        indicatorWeight: 3,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: 'Laporanku'),
          Tab(text: 'Laporan Publik'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF), width: 0.5),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          decoration: const InputDecoration(
            hintText: 'Cari laporan...',
            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = <Map<String, String>>[
      {'key': 'semua', 'label': 'Semua'},
      {'key': StatusLaporan.menungguKlasifikasi, 'label': 'Menunggu'},
      {'key': StatusLaporan.diproses, 'label': 'Diproses'},
      {'key': StatusLaporan.selesai, 'label': 'Selesai'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 10),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: filters.map((f) {
            final isActive = _filterStatus == f['key'];
            return GestureDetector(
              onTap: () => setState(() => _filterStatus = f['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF0D47A1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF0D47A1)
                        : const Color(0xFFE9ECEF),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList({required bool isPublic}) {
    final laporanProvider = context.watch<LaporanProvider>();
    List<LaporanLokal> data;
    if (isPublic) {
      // Tab Publik: gunakan data langsung dari server agar status akurat
      data = laporanProvider.laporanPublik;

      // SINKRONISASI FILTER UNTUK TAB "LAPORAN PUBLIK"
      // Gunakan pemfilteran mandiri yang aman terhadap Case-Sensitive & Search Query
      data = data.where((l) {
        final statusLaporan = l.status.toLowerCase();
        final targetFilter = _filterStatus.toLowerCase();
        
        // Pencocokan status filter cerdas
        bool matchStatus = false;
        if (targetFilter == 'semua') {
          matchStatus = true;
        } else if (targetFilter == 'menunggu' || targetFilter == 'menungguklasifikasi') {
          matchStatus = statusLaporan == 'menunggu' || statusLaporan == 'menungguklasifikasi';
        } else {
          matchStatus = statusLaporan == targetFilter;
        }

        // Pencocokan kolom pencarian text field
        final query = _searchQuery.trim().toLowerCase();
        final matchSearch = query.isEmpty ||
                            l.namaSarana.toLowerCase().contains(query) ||
                            l.lokasiPerbaikan.toLowerCase().contains(query) ||
                            l.keteranganKerusakan.toLowerCase().contains(query);

        return matchStatus && matchSearch;
      }).toList();
    } else {
      // Tab Laporanku: data dari Hive lokal (milik sendiri)
      data = laporanProvider.filterLaporan(
        filterStatus: _filterStatus,
        searchQuery: _searchQuery,
      ).where((l) => laporanProvider.isOwner(l)).toList();
    }

    if (data.isEmpty) {
      return LaporanEmptyState(
        filterStatus: _filterStatus,
        isPublic: isPublic,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (isPublic) {
          await context.read<LaporanProvider>().fetchLaporanPublik();
        } else {
          await context.read<LaporanProvider>().syncFromRemote();
        }
      },
      color: const Color(0xFF0D47A1),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final laporan = data[index];
          return LaporanCard(
            laporan: laporan,
            canDelete: laporanProvider.canDelete(laporan),
            onDelete: laporanProvider.canDelete(laporan)
                ? () => _confirmDelete(context, laporan)
                : null,
            onEdit: laporanProvider.canEdit(laporan)
                ? () => _navigateToEdit(context, laporan)
                : null,
          );
        },
      ),
    );
  }
}