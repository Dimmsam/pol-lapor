import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/notifikasi_provider.dart';

class NotifBadge extends StatelessWidget {
  const NotifBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final notifCount = context.watch<NotifikasiProvider>().unreadCount;

    return Stack(
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
    );
  }
}
