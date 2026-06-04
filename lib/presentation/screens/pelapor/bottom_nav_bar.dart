// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: bottom_nav_bar.dart

import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color primaryColor;
  final Color accentColor;

  const BottomNavBar({
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
        color: Colors.white, // Menjaga latar belakang tetap putih bersih
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000), // Diperhalus shadow-nya agar modern
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      // SOLUSI: Dibungkus SafeArea agar sistem navigasi HP (OS) memberikan ruang bar yang pas
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
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
              icon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'Tambah',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}