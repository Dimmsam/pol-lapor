// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: notif_screen.dart
// Refactored: Menampilkan notifikasi nyata dari tabel public.notifikasi (Supabase)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/notifikasi.dart';
import '../../../logic/providers/notifikasi_provider.dart';
import '../../../core/routes/app_router.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({super.key});

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> {
  static const Color _blue = Color(0xFF0D47A1);
  static const Color _bg   = Color(0xFFF4F6FA);

  @override
  void initState() {
    super.initState();
    // Refresh saat masuk halaman + mark all as read
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotifikasiProvider>();
      await provider.fetchNotifikasi();
      await provider.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _blue,
        actions: [
          Consumer<NotifikasiProvider>(
            builder: (_, provider, __) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: provider.markAllAsRead,
                child: const Text(
                  'Tandai semua dibaca',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1)),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotifikasiProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifikasiList.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            color: _blue,
            onRefresh: provider.fetchNotifikasi,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifikasiList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notif = provider.notifikasiList[index];
                return Dismissible(
                  key: Key(notif.notifikasiId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    provider.deleteNotifikasi(notif.notifikasiId);
                  },
                  child: _NotifItem(
                    notif: notif,
                    onTap: () => _handleNotifTap(context, notif),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleNotifTap(BuildContext context, Notifikasi notif) {
    // 1. Tandai sebagai dibaca
    context.read<NotifikasiProvider>().markAsRead(notif.notifikasiId);

    // 2. Navigasi jika ada formulirId
    if (notif.formulirId != null && notif.formulirId!.isNotEmpty) {
      AppRouter.navigateToDetailFromNotif(context, notif.formulirId!);
    }
  }
}

// =======================================================
// ITEM NOTIF
// =======================================================

class _NotifItem extends StatelessWidget {
  final Notifikasi notif;
  final VoidCallback onTap;

  const _NotifItem({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notif.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF0F4FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread
                ? const Color(0xFFBBCCF5)
                : const Color(0xFFE9ECEF),
            width: isUnread ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.judul,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isUnread
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.pesan,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notif.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _iconBgColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_iconData(), color: _iconFgColor(), size: 18),
    );
  }

  IconData _iconData() {
    switch (notif.tipe) {
      case TipeNotifikasi.selesai:     return Icons.check_circle_outline;
      case TipeNotifikasi.eskalasi:    return Icons.warning_amber_rounded;
      case TipeNotifikasi.updateStatus: return Icons.build_outlined;
      case TipeNotifikasi.laporanBaru: return Icons.add_circle_outline;
      default:                         return Icons.notifications_outlined;
    }
  }

  Color _iconBgColor() {
    switch (notif.tipe) {
      case TipeNotifikasi.selesai:      return const Color(0xFFD1FAE5);
      case TipeNotifikasi.eskalasi:     return const Color(0xFFFEF3C7);
      case TipeNotifikasi.updateStatus: return const Color(0xFFEEF2FF);
      case TipeNotifikasi.laporanBaru:  return const Color(0xFFE0F2FE);
      default:                          return const Color(0xFFF3F4F6);
    }
  }

  Color _iconFgColor() {
    switch (notif.tipe) {
      case TipeNotifikasi.selesai:      return const Color(0xFF059669);
      case TipeNotifikasi.eskalasi:     return const Color(0xFFD97706);
      case TipeNotifikasi.updateStatus: return const Color(0xFF4F46E5);
      case TipeNotifikasi.laporanBaru:  return const Color(0xFF0284C7);
      default:                          return const Color(0xFF6B7280);
    }
  }

  String _timeAgo(DateTime time) {
    final now  = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
    if (diff.inDays < 7)     return '${diff.inDays} hari lalu';

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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 36,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Notifikasi akan muncul saat ada\nupdate pada laporan kamu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}