// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/laporan_provider.dart';
import '../../../logic/providers/notifikasi_provider.dart';
import '../../../presentation/widgets/common/status_badge.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color _bg = Color(0xFFF4F6FA);

  @override
Widget build(BuildContext context) {
  final provider = context.watch<LaporanProvider>();

  return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(namaUser: provider.namaUser),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GreetingSection(namaUser: provider.namaUser),
                    const SizedBox(height: 16),
                    _StatSection(provider: provider),
                    const SizedBox(height: 16),

                    const _NotifSection(),

                    const SizedBox(height: 20),
                    const _RecentSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TOP BAR ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String namaUser;
  const _TopBar({required this.namaUser});

  String get _initials {
    final parts = namaUser.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final notifCount  = context.watch<NotifikasiProvider>().unreadCount;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          // ─── AVATAR ─────────────────────────────
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ─── TITLE ─────────────────────────────
          const Text(
            'PolLapor',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D47A1),
              letterSpacing: -0.3,
            ),
          ),

          const Spacer(),

          // ─── NOTIFICATION ──────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF374151),
                  size: 24,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notif');
                },
              ),

              // BADGE REALTIME dari NotifikasiProvider
              if (notifCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        notifCount > 9 ? '9+' : notifCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


// ─── GREETING ──────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  final String namaUser;
  const _GreetingSection({required this.namaUser});

  String get _firstName => namaUser.trim().split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Halo, $_firstName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1B3E),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 6),
              const Text('👋', style: TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Laporkan kerusakan fasilitas dengan cepat dan mudah',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STAT CARDS ─────────────────────────────────────────────────────────────

class _StatSection extends StatelessWidget {
  final LaporanProvider provider;
  const _StatSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF4F46E5),
              iconBg: const Color(0xFFEEF2FF),
              value: provider.totalLaporan.toString(),
              label: 'Total',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.schedule_outlined,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              value: provider.totalDiproses.toString(),
              label: 'Diproses',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF059669),
              iconBg: const Color(0xFFD1FAE5),
              value: provider.totalSelesai.toString(),
              label: 'Selesai',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: iconColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── NOTIFIKASI ────────────────────────────────────────────────────────────

class _NotifSection extends StatelessWidget {
  const _NotifSection();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotifikasiProvider>().unreadCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B3E),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (count == 0)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Tidak ada notifikasi baru'),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$count notifikasi belum dibaca'),
          ),
      ],
    );
  }
}

class NotifSectionDynamic extends StatelessWidget {
  const NotifSectionDynamic({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotifikasiProvider>();
    final count = provider.unreadCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B3E),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (count == 0)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("Tidak ada notifikasi"),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("$count notifikasi baru"),
          ),
      ],
    );
  }
}

// ======================
// NOTIFICATION BADGE EXTENSION
// ======================

extension TopBarNotifExtension on BuildContext {
  Widget buildNotifBadge(Widget icon) {
    final provider = watch<NotifikasiProvider>();
    final count = provider.unreadCount;

    return Stack(
      children: [
        icon,

        if (count > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ======================
// TRIGGER NOTIF GLOBAL
// ======================

void clearDashboardNotif(BuildContext context) {
  try {
    context.read<NotifikasiProvider>().markAllAsRead();
  } catch (_) {}
}

// ─── LAPORAN TERBARU ───────────────────────────────────────────────────────

class _RecentSection extends StatelessWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<LaporanProvider>().recentLaporan();

    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Belum ada laporan'),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Laporan Terbaru',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B3E),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: data.map((laporan) {
              return Column(
                children: [
                  _ReportItem(
                    icon: Icons.report_problem_outlined,
                    title: laporan.namaSarana,
                    location: laporan.lokasiPerbaikan,
                    status: laporan.status,
                  ),
                  const SizedBox(height: 9),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ReportItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String location;
  final String status;

  const _ReportItem({
    required this.icon,
    required this.title,
    required this.location,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF0D47A1), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: status),
        ],
      ),
    );
  }
}
