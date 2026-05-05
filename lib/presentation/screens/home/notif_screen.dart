// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: notif_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../logic/providers/home_provider.dart';

class NotifScreen extends StatelessWidget {
  const NotifScreen({super.key});

  static const Color _blue = Color(0xFF0D47A1);
  static const Color _bg = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HomeProvider>();

    // saat masuk halaman notif → clear badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.clearNotification();
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _blue,
      ),
      body: ValueListenableBuilder(
        valueListenable:
            Hive.box<LaporanLokal>(AppConstants.boxLaporan).listenable(),
        builder: (context, box, _) {
          final laporanList = box.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (laporanList.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: laporanList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final laporan = laporanList[index];
              return _NotifItem(laporan: laporan);
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// ITEM NOTIF
// =======================================================

class _NotifItem extends StatelessWidget {
  final LaporanLokal laporan;

  const _NotifItem({required this.laporan});

  @override
  Widget build(BuildContext context) {
    final isNew = !laporan.isSynced;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(isNew),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildTitle(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  laporan.namaSarana,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(laporan.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          if (isNew) _buildDot(),
        ],
      ),
    );
  }

  Widget _buildIcon(bool isNew) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isNew
            ? const Color(0xFFEEF2FF)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isNew ? Icons.notifications_active_outlined : Icons.history,
        color: isNew ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
        size: 18,
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF3B82F6),
        shape: BoxShape.circle,
      ),
    );
  }

  String _buildTitle() {
    switch (laporan.status) {
      case 'selesai':
        return 'Laporan Selesai';
      case 'diproses':
        return 'Laporan Diproses';
      default:
        return 'Laporan Baru';
    }
  }

  // =======================================================
  // FORMAT TIME AGO
  // =======================================================

  String _timeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return '${time.day}/${time.month}/${time.year}';
  }
}

// =======================================================
// EMPTY STATE
// =======================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}