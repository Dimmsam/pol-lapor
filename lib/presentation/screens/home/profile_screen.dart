// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/home_provider.dart';
import '../../../logic/providers/login_provider.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';
import '../../../data/models/user_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _initials(String nama) {
    final parts = nama.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
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

  Widget _buildHeader(HomeProvider home) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0D47A1),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
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

  Widget _buildMenuSection(BuildContext context, HomeProvider home) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AKUN
          _sectionLabel('AKUN'),
          _menuGroup([
            _MenuItem(
              icon: Icons.person_outline_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              label: 'Edit Profil',
              sub: 'Ubah nama dan info akun',
              onTap: () => _showEditProfil(context, home),
            ),
            _MenuItem(
              icon: Icons.lock_outline_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              label: 'Ubah Password',
              sub: 'Perbarui kata sandi akun',
              onTap: () => _showUbahPassword(context),
            ),
          ]),

          const SizedBox(height: 16),

          // LAINNYA
          _sectionLabel('LAINNYA'),
          _menuGroup([
            _MenuItem(
              icon: Icons.info_outline_rounded,
              iconBg: const Color(0xFFD1FAE5),
              iconColor: const Color(0xFF059669),
              label: 'Tentang Aplikasi',
              sub: 'Versi, lisensi, dan developer',
              onTap: () => _showTentangAplikasi(context),
            ),
          ]),

          const SizedBox(height: 24),

          // LOGOUT
          _LogoutButton(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _menuGroup(List<Widget> items) {
    return Container(
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

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
}

// ─── MENU ITEM ────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String sub;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFFD1D5DB),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LOGOUT BUTTON ────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF7ED),
          foregroundColor: const Color(0xFFEA580C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFED7AA), width: 0.8),
          ),
        ),
        onPressed: () => _showLogoutDialog(context),
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