import 'package:flutter/material.dart';

class DashboardGreetingSection extends StatelessWidget {
  final String namaUser;
  const DashboardGreetingSection({super.key, required this.namaUser});

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
