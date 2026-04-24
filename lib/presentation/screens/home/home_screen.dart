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
  const HomeScreen({super.key});

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
      body: SafeArea(child: screens[currentIndex]),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
        primaryColor: primaryBlue,
        accentColor: accentOrange,
      ),
    );
  }
}
