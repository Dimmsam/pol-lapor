// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/laporan_provider.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../core/utils/auth_validator.dart';
import '../../../core/utils/string_extension.dart';

import '../../widgets/pelapor/profile/profile_info_card.dart';
import '../../widgets/pelapor/profile/profile_menu_item.dart';
import '../../widgets/pelapor/profile/profile_logout_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<LaporanProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        // Menghilangkan botom padding agar tidak bentrok ganda dengan BottomNavBar SafeArea
        bottom: false, 
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), // Menambah efek scrolling halus
                child: Column(
                  children: [
                    ProfileInfoCard(home: home),
                    const SizedBox(height: 20),
                    _buildMenuSection(context, home),
                    // Memberikan jarak aman dinamis di paling bawah agar tidak mepet navbar
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 30), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: const Row(
        children: [
          Text(
            'Profil',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1B3E),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMenuSection(BuildContext context, LaporanProvider home) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AKUN
          _sectionLabel('AKUN'),
          _menuGroup([
            ProfileMenuItem(
              icon: Icons.person_outline_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              label: 'Edit Profil',
              sub: 'Ubah nama dan info akun',
              onTap: () => _showEditProfil(context, home),
            ),
            ProfileMenuItem(
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
            ProfileMenuItem(
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
          const ProfileLogoutButton(),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(children: items),
    );
  }

  // ─── EDIT PROFIL ──────────────────────────────────────────────────────────

  void _showEditProfil(BuildContext context, LaporanProvider home) {
    final namaCtrl = TextEditingController(text: home.namaUser);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: 'Edit Profil',
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama Lengkap',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: namaCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                  filled: true,
                  fillColor: const Color(0xFFF4F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${home.emailUser}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final nama = namaCtrl.text.trim();
                    if (nama.isEmpty) return;

                    await context.read<AuthProvider>().updateNama(nama);
                    home.refreshSession();

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profil berhasil diperbarui'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UBAH PASSWORD ────────────────────────────────────────────────────────

  void _showUbahPassword(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => _BottomSheetWrapper(
          title: 'Ubah Password',
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField(
                  controller: oldCtrl,
                  label: 'Password Lama',
                  obscure: obscureOld,
                  onToggle: () => setModalState(() => obscureOld = !obscureOld),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  controller: newCtrl,
                  label: 'Password Baru',
                  obscure: obscureNew,
                  onToggle: () => setModalState(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 12),
                _passwordField(
                  controller: confirmCtrl,
                  label: 'Konfirmasi Password Baru',
                  obscure: obscureConfirm,
                  onToggle: () =>
                      setModalState(() => obscureConfirm = !obscureConfirm),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final err = AuthValidator.validatePassword(newCtrl.text) ?? 
                                  AuthValidator.validateConfirmPassword(confirmCtrl.text, newCtrl.text);
                      
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err)),
                        );
                        return;
                      }

                      // Pakai backend auth yang sudah ada untuk ubah password
                      try {
                        await context.read<AuthProvider>().updatePassword(
                          oldCtrl.text,
                          newCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password berhasil diubah'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                        }
                      }
                    },
                    child: const Text(
                      'Simpan Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF4F6FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  // ─── TENTANG APLIKASI ─────────────────────────────────────────────────────

  void _showTentangAplikasi(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: 'Tentang Aplikasi',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'PolLapor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D1B3E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Versi 1.0.0',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 0.5),
            const SizedBox(height: 12),
            _aboutRow('Developer', 'Kelompok B6'),
            _aboutRow('Prodi', 'D3 Teknik Informatika'),
            _aboutRow('Institusi', 'Politeknik Negeri Bandung'),
            _aboutRow('Tahun', '2026'),
            const SizedBox(height: 12),
            const Text(
              'Aplikasi pelaporan kerusakan fasilitas kampus berbasis mobile dengan sinkronisasi cloud.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MENU ITEM ────────────────────────────────────────────────────────────





// ─── BOTTOM SHEET WRAPPER ─────────────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
