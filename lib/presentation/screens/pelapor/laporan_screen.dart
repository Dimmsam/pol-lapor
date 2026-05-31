// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: laporan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/laporan_icon_mapper.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../logic/providers/laporan_provider.dart';
import '../../../presentation/widgets/common/status_badge.dart';
import 'detail_laporan_screen.dart';
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
        // Sesuaikan dengan nama & parameter form laporan kamu
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
    var data = laporanProvider.filterLaporan(
      filterStatus: _filterStatus,
      searchQuery: _searchQuery,
    );

    if (isPublic) {
      // Menampilkan semua laporan (publik), termasuk milik sendiri agar mudah di-test
      // data = data; (tidak perlu difilter)
    } else {
      // Menampilkan laporan milik sendiri
      data = data.where((l) => laporanProvider.isOwner(l)).toList();
    }

    if (data.isEmpty) return _buildEmpty(isPublic: isPublic);

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<LaporanProvider>().syncFromRemote();
      },
      color: const Color(0xFF0D47A1),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final laporan = data[index];
          return _LaporanCard(
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

  Widget _buildEmpty({required bool isPublic}) {
    final emptyData = LaporanIconMapper.getEmptyStateData(_filterStatus, isPublic);
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

// ─── LAPORAN CARD ───────────────────────────────────────────────────────────

class _LaporanCard extends StatelessWidget {
  final LaporanLokal laporan;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit; // null berarti tombol edit tidak ditampilkan

  const _LaporanCard({
    required this.laporan,
    required this.canDelete,
    required this.onDelete,
    this.onEdit,
  });

  IconData get _icon => LaporanIconMapper.getIconForSarana(laporan.namaSarana);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailLaporanScreen(laporan: laporan),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9ECEF), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris atas: ikon + nama + lokasi + status badge ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _icon,
                      color: const Color(0xFF0D47A1),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          laporan.namaSarana,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          laporan.lokasiPerbaikan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: laporan.status),
                ],
              ),

              // ── Divider ──────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Divider(
                  height: 0,
                  thickness: 0.5,
                  color: Color(0xFFF3F4F6),
                ),
              ),

              // ── Keterangan kerusakan ─────────────────────────────────────
              Text(
                laporan.keteranganKerusakan,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),

              // ── Footer: tanggal + sync + tombol aksi ─────────────────────
              Row(
                children: [
                  // Tanggal
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${laporan.createdAt.day.toString().padLeft(2, '0')}/'
                    '${laporan.createdAt.month.toString().padLeft(2, '0')}/'
                    '${laporan.createdAt.year}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),

                  // Indikator belum sinkron
                  if (!laporan.isSynced) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Belum tersinkron',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // ── Tombol Edit (hanya jika status menunggu) ─────────────
                  if (onEdit != null) ...[
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF0D47A1),
                      bgColor: const Color(0xFFEEF2FF),
                      onTap: onEdit!,
                    ),
                    const SizedBox(width: 8),
                  ],

                  // ── Tombol Hapus (hanya milik sendiri) ────────────────────
                  if (canDelete && onDelete != null)
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Hapus',
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
                      onTap: onDelete!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ACTION BUTTON ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

