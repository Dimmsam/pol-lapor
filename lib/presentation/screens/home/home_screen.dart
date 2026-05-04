// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import provider
import '../../../logic/providers/home_provider.dart';

// Import screen
import 'dashboard_screen.dart';
import 'laporan_screen.dart';
import 'profile_screen.dart';

// Import form laporan (reuse)
import '../pelapor/form_laporan_screen.dart';

// Import widget
import '../../screens/home/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex; // TAMBAHAN

  const HomeScreen({
    super.key,
    this.initialIndex = 0, // default tetap 0
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    DashboardScreen(),
    LaporanScreen(),
    FormLaporanScreen(),
    ProfileScreen(),
  ];

  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color accentOrange = const Color(0xFFFF8F00);

  @override
  void initState() {
    super.initState();

    // TAMBAHAN: set index awal dari luar (misal dari form)
    currentIndex = widget.initialIndex;

    // Inisialisasi session & statistik laporan saat home pertama dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().init();
    });
  }

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: IndexedStack( // TAMBAHAN: biar state tiap tab tidak reset
          index: currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
        primaryColor: primaryBlue,
        accentColor: accentOrange,
      ),
    );
  }
}