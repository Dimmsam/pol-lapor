// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: laporan_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../services/hive_service.dart';
import '../../../data/models/laporan_lokal.dart';
import 'package:flutter/foundation.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

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
              colors: [Color(0xFF0D47A1), Color(0xD90D47A1)],
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

        // REALTIME LIST
        Expanded(
          child: FutureBuilder<ValueListenable<Box<LaporanLokal>>>(
            future: HiveService().listenLaporan(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final listenable = snapshot.data!;

              return ValueListenableBuilder<Box<LaporanLokal>>(
                valueListenable: listenable,
                builder: (context, box, _) {
                  final data = box.values.toList().reversed.toList();

                  if (data.isEmpty) {
                    return const Center(
                      child: Text('Belum ada laporan'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final laporan = data[index];
                      return _LaporanCard(laporan: laporan);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LaporanCard extends StatelessWidget {
  final LaporanLokal laporan;

  const _LaporanCard({required this.laporan});

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
          // Judul
          Text(
            laporan.namaSarana,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          // Deskripsi
          Text(
            laporan.keteranganKerusakan,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 10),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusBadge(status: laporan.status),
              Text(
                '${laporan.createdAt.day}/${laporan.createdAt.month}/${laporan.createdAt.year}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          // Label unsynced
          if (!laporan.isSynced)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Belum Tersinkron',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                ),
              ),
            )
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
      case 'selesai':
        bgColor = const Color(0x1A4CAF50);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'diproses':
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