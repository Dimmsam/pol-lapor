// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: laporan_screen.dart

import 'package:flutter/material.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color accentOrange = const Color(0xFFFF8F00);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D47A1),
                Color(0xD90D47A1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Text(
            'Daftar Laporan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // List laporan
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 10,
            itemBuilder: (context, index) {
              return const _LaporanCard();
            },
          ),
        ),
      ],
    );
  }
}

class _LaporanCard extends StatelessWidget {
  const _LaporanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul laporan
          const Text(
            'Kerusakan AC di Ruang Kelas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          // Deskripsi singkat
          const Text(
            'AC tidak dingin dan mengeluarkan suara berisik.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 10),

          // Footer (status + tanggal)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _StatusBadge(status: 'Proses'),
              Text(
                '12 Mei 2025',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Selesai':
        bgColor = const Color(0x1A4CAF50);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'Proses':
        bgColor = const Color(0x1AFF8F00);
        textColor = const Color(0xFFFF8F00);
        break;
      default:
        bgColor = const Color(0x1A9E9E9E);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}