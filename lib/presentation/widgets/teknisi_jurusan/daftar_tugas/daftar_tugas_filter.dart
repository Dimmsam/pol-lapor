import 'package:flutter/material.dart';

class DaftarTugasFilter extends StatelessWidget {
  final TabController tabController;
  final List<Tab> tabs;
  final Color primaryColor;

  const DaftarTugasFilter({
    super.key,
    required this.tabController,
    required this.tabs,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Tugas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola dan selesaikan tugas pemeliharaan Anda hari ini.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tab filter: Semua | Menunggu | Dikerjakan
          TabBar(
            controller: tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: primaryColor,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            indicator: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            tabs: tabs,
          ),
        ],
      ),
    );
  }
}
