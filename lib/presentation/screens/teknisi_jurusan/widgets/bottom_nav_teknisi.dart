// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: bottom_nav_teknisi.dart
// Deskripsi: Bottom Navigation Bar khusus untuk Teknisi Jurusan.
//            3 item: Beranda | Tugas | Profil

import 'package:flutter/material.dart';

class BottomNavTeknisi extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color primaryColor;
  final Color accentColor;

  const BottomNavTeknisi({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}