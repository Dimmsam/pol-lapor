import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../logic/providers/teknisi_upt_provider.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'tugas_list_screen.dart';

class TeknisiUptHomeScreen extends StatefulWidget {
  const TeknisiUptHomeScreen({super.key});

  @override
  State<TeknisiUptHomeScreen> createState() => _TeknisiUptHomeScreenState();
}

class _TeknisiUptHomeScreenState extends State<TeknisiUptHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TeknisiUptDashboardScreen(),
    TeknisiUptTugasListScreen(),
    TeknisiUptProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiUptProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0D47A1),
        unselectedItemColor: const Color(0xFF6B7280),
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
