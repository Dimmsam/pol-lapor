import 'package:flutter/material.dart';
import '../../../../logic/providers/laporan_provider.dart';

class DashboardStatSection extends StatelessWidget {
  final LaporanProvider provider;
  const DashboardStatSection({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Menggunakan GridView agar susunan kartu 2x2 tetap rapi dan responsive
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2, // Tetap 2 kolom
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // Agar scroll menyatu dengan halaman induk
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4, // Mengatur rasio lebar-tinggi kartu agar proporsional
        children: [
          _StatCard(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF4F46E5),
            iconBg: const Color(0xFFEEF2FF),
            value: provider.totalLaporan.toString(),
            label: 'Total',
          ),
          _StatCard(
            icon: Icons.hourglass_empty_rounded,
            iconColor: const Color(0xFF1E40AF),
            iconBg: const Color(0xFFEFF6FF),
            value: provider.totalMenunggu.toString(),
            label: 'Menunggu',
          ),
          _StatCard(
            icon: Icons.schedule_outlined,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            value: provider.totalDiproses.toString(),
            label: 'Diproses',
          ),
          _StatCard(
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFF0369A1),
            iconBg: const Color(0xFFE0F2FE),
            value: provider.totalEskalasi.toString(),
            label: 'Eskalasi',
          ),
          _StatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            value: provider.totalSelesai.toString(),
            label: 'Selesai',
          ),
          _StatCard(
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFDC2626), // Warna Merah tegas
            iconBg: const Color(0xFFFEE2E2),    // Background Merah pudar
            value: provider.totalDitolak.toString(), 
            label: 'Ditolak',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Memastikan konten vertikal di tengah
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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