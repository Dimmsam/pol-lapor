import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../logic/providers/notifikasi_provider.dart';

class DashboardNotifSection extends StatelessWidget {
  const DashboardNotifSection({super.key});

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
