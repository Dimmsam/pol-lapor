import 'package:flutter/material.dart';
import '../../common/notif_badge.dart';
import '../../../../core/utils/string_extension.dart';

class DashboardTopBar extends StatelessWidget {
  final String namaUser;
  const DashboardTopBar({super.key, required this.namaUser});

  @override
  Widget build(BuildContext context) {
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
              namaUser.toInitials(),
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
          const NotifBadge(),
        ],
      ),
    );
  }
}
