// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/home_provider.dart';
import '../../../logic/providers/login_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _primaryBlue = Color(0xFF0D47A1);
  static const Color _bgColor = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. BACKGROUND BIRU DENGAN LENGKUNGAN
                Container(
                  width: double.infinity,
                  height: 240,
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildTopNav(),
                        _buildUserInfo(home),
                      ],
                    ),
                  ),
                ),

                // 2. CARD STATISTIK (FLOATING)
                Positioned(
                  bottom: -50,
                  child: _buildStatCard(home),
                ),
              ],
            ),

            const SizedBox(height: 70), // Memberi ruang untuk card floating

            // 3. DAFTAR MENU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("AKUN"),
                  _buildMenuContainer([
                    _ProfileMenuItem(
                      icon: Icons.person_outline_rounded,
                      iconColor: Colors.blue,
                      iconBg: Colors.blue.shade50,
                      title: 'Edit Profil',
                      subtitle: 'Nama, foto, dan info pribadi',
                      onTap: () => _showEditProfile(context, home),
                    ),
                    const Divider(height: 1, indent: 60),
                    _ProfileMenuItem(
                      icon: Icons.lock_outline_rounded,
                      iconColor: Colors.orange,
                      iconBg: Colors.orange.shade50,
                      title: 'Ubah Password',
                      subtitle: 'Perbarui kata sandi akun',
                      onTap: () => _showChangePassword(context),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildSectionTitle("LAINNYA"),
                  _buildMenuContainer([
                    _ProfileMenuItem(
                      icon: Icons.access_time_rounded,
                      iconColor: Colors.green,
                      iconBg: Colors.green.shade50,
                      title: 'Tentang Aplikasi',
                      subtitle: 'Versi, lisensi, dan developer',
                      onTap: () => _showAboutApp(context),
                    ),
                    const Divider(height: 1, indent: 60),
                    _ProfileMenuItem(
                      icon: Icons.bar_chart_rounded,
                      iconColor: Colors.indigo,
                      iconBg: Colors.indigo.shade50,
                      title: 'Versi Aplikasi',
                      subtitle: 'v1.0.0 · Build 2026',
                      onTap: () {},
                      showArrow: false,
                    ),
                  ]),

                  const SizedBox(height: 25),

                  // 4. TOMBOL KELUAR
                  _buildLogoutButton(context),
                  
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "PolLapor © 2026 · Politeknik Negeri Bandung",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Profil",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
          )
        ],
      ),
    );
  }

  Widget _buildUserInfo(HomeProvider home) {
    return Column(
      children: [
        const SizedBox(height: 15),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              alignment: Alignment.center,
              child: const Text(
                "BS",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.edit, color: Colors.white, size: 14),
            )
          ],
        ),
        const SizedBox(height: 12),
        Text(home.namaUser, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(home.emailUser, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(home.roleUser, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }

  Widget _buildStatCard(HomeProvider home) {
    final int selesai = home.totalLaporan - home.totalUnsynced;
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(home.totalLaporan.toString(), "Total"),
          const VerticalDivider(width: 1),
          _statItem(home.totalUnsynced.toString(), "Diproses"),
          const VerticalDivider(width: 1),
          _statItem(selesai.toString(), "Selesai"),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryBlue)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        await context.read<LoginProvider>().logout();
        if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Keluar dari Akun", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // --- MODAL FUNCTIONS ---

  void _showEditProfile(BuildContext context, HomeProvider home) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Edit Profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 15),
            TextField(decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context), child: const Text("Simpan", style: TextStyle(color: Colors.white)))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text("Ubah Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(obscureText: true, decoration: InputDecoration(labelText: "Password Sekarang", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 15),
            TextField(obscureText: true, decoration: InputDecoration(labelText: "Password Baru", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(context), child: const Text("Perbarui Password", style: TextStyle(color: Colors.white)))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }