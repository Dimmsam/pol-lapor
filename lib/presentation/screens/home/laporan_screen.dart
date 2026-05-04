// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: laporan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../services/hive_service.dart';
import '../../../data/models/laporan_lokal.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          const Text(
            'Daftar Laporan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1B3E),
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF374151),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ───────────────────────────────────────────────────────────

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

  // ─── FILTER CHIPS ─────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final filters = ['semua', 'menunggu', 'diproses', 'selesai'];
    final labels = {
      'semua': 'Semua',
      'menunggu': 'Menunggu',
      'diproses': 'Diproses',
      'selesai': 'Selesai',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 10),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: filters.map((f) {
            final isActive = _filterStatus == f;
            return GestureDetector(
              onTap: () => setState(() => _filterStatus = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0D47A1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF0D47A1)
                        : const Color(0xFFE9ECEF),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  labels[f]!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── LIST ─────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return FutureBuilder<ValueListenable<Box<LaporanLokal>>>(
      future: HiveService().listenLaporan(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF0D47A1),
            ),
          );
        }

        return ValueListenableBuilder<Box<LaporanLokal>>(
          valueListenable: snapshot.data!,
          builder: (context, box, _) {
            var data = box.values.toList().reversed.toList();

            // Filter status
            if (_filterStatus != 'semua') {
              data = data
                  .where((l) => l.status.toLowerCase() == _filterStatus)
                  .toList();
            }

            // Filter search
            if (_searchQuery.isNotEmpty) {
              data = data
                  .where((l) =>
                      l.namaSarana
                          .toLowerCase()
                          .contains(_searchQuery) ||
                      l.keteranganKerusakan
                          .toLowerCase()
                          .contains(_searchQuery))
                  .toList();
            }

            if (data.isEmpty) return _buildEmpty();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: data.length,
              itemBuilder: (context, index) =>
                  _LaporanCard(laporan: data[index]),
            );
          },
        );
      },
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmpty() {
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
          const Text(
            'Belum ada laporan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Laporan yang dibuat akan muncul di sini',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ─── LAPORAN CARD ─────────────────────────────────────────────────────────

class _LaporanCard extends StatelessWidget {
  final LaporanLokal laporan;
  const _LaporanCard({required this.laporan});

  IconData get _icon {
    final nama = laporan.namaSarana.toLowerCase();
    if (nama.contains('ac') || nama.contains('kipas')) {
      return Icons.air_outlined;
    } else if (nama.contains('lampu') || nama.contains('listrik')) {
      return Icons.lightbulb_outline_rounded;
    } else if (nama.contains('pintu') || nama.contains('jendela')) {
      return Icons.door_back_door_outlined;
    } else if (nama.contains('proyektor') || nama.contains('komputer')) {
      return Icons.monitor_outlined;
    } else if (nama.contains('toilet') || nama.contains('wc')) {
      return Icons.wc_outlined;
    }
    return Icons.construction_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            // Header
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
                  child: Icon(_icon,
                      color: const Color(0xFF0D47A1), size: 19),
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
                        laporan.keteranganKerusakan,
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
                _StatusBadge(status: laporan.status),
              ],
            ),

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 11),
              child: Divider(height: 0, thickness: 0.5, color: Color(0xFFF3F4F6)),
            ),

            // Deskripsi
            Text(
              laporan.keteranganKerusakan,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 10),

            // Footer
            Row(
              children: [
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
                if (!laporan.isSynced) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Belum tersinkron',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STATUS BADGE ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'selesai':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        label = 'Selesai';
        break;
      case 'diproses':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Diproses';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}