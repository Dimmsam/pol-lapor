import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/login_provider.dart';
import 'widgets/bottom_nav_teknisi.dart';

class ProfilTeknisiScreen extends StatefulWidget {
  const ProfilTeknisiScreen({Key? key}) : super(key: key);

  @override
  State<ProfilTeknisiScreen> createState() => _ProfilTeknisiScreenState();
}

class _ProfilTeknisiScreenState extends State<ProfilTeknisiScreen> {
  static const navy = Color(0xFF0B3A66);
  static const lightBlue = Color(0xFF7FB6E6);

  int _selectedIndex = 3; // default to Profil tab

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SimplePlaceholder(title: 'Beranda'),
      const SimplePlaceholder(title: 'Tugas'),
      const SimplePlaceholder(title: 'Riwayat'),
      _buildProfileContent(context),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6E9EE), width: 1)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const Spacer(),
          const Text(
            'Profil Saya',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: navy,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileCard(context),
                const SizedBox(height: 16),
                _buildPerformanceCard(context),
                const SizedBox(height: 20),
                const Text(
                  'Pengaturan Akun',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSettingsList(context),
                const SizedBox(height: 16),
                _buildLogoutButton(context),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Versi Aplikasi 2.4.0 (Build 102)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Opacity(
                  opacity: 0.06,
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: Icon(Icons.badge, size: 96, color: Colors.black),
                  ),
                ),
              ),
              Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.blueGrey,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA726),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ahmad Teknisi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Teknisi Jurusan Teknik Informatika',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context) {
    return InkWell(
      onTap: () {
        final login = context.read<LoginProvider>();
        final session = login.getExistingSession() ?? login.session;
        if (session != null) {
          Navigator.pushNamed(
            context,
            '/dashboard-teknisi-jurusan',
            arguments: session,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Harap login terlebih dahulu')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: navy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'PERFORMA KERJA',
                    style: TextStyle(
                      color: Color(0xFF9FD4FF),
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Total Diselesaikan: 45 Laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.show_chart, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: Colors.black54),
            ),
            title: const Text('Edit Profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Tampilkan modal untuk edit profil khusus teknisi
              final namaCtrl = TextEditingController(text: 'Ahmad Teknisi');
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Edit Profil',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: namaCtrl,
                          decoration: const InputDecoration(labelText: 'Nama'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil disimpan (demo)'),
                              ),
                            );
                          },
                          child: const Text('Simpan'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sync, color: Colors.black54),
            ),
            title: const Text('Status Sinkronisasi'),
            subtitle: const Text(
              'Semua data tersinkron',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semua data sudah tersinkron')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications, color: Colors.black54),
            ),
            title: const Text('Pengaturan Notifikasi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Buka pengaturan notifikasi khusus teknisi (placeholder)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SimplePlaceholder(
                    title: 'Pengaturan Notifikasi (Teknisi)',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_outline, color: Colors.black54),
            ),
            title: const Text('Edit Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Modal ubah password (demo)
              final oldCtrl = TextEditingController();
              final newCtrl = TextEditingController();
              final confirmCtrl = TextEditingController();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ubah Password',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: oldCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Password Lama',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: newCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Password Baru',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: confirmCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi Password',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (newCtrl.text != confirmCtrl.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password tidak cocok'),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password diperbarui (demo)'),
                              ),
                            );
                          },
                          child: const Text('Simpan Password'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Keluar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Konfirmasi'),
              content: const Text('Apakah Anda yakin ingin keluar?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final login = context.read<LoginProvider>();
    final session = login.getExistingSession() ?? login.session;

    // Map internal _selectedIndex (0..3) to BottomNavTeknisi indexes (0..2)
    int navIndex;
    if (_selectedIndex == 3) {
      navIndex = 2; // profil
    } else if (_selectedIndex >= 0 && _selectedIndex <= 1) {
      navIndex = _selectedIndex;
    } else {
      navIndex = 0;
    }

    return BottomNavTeknisi(
      currentIndex: navIndex,
      primaryColor: navy,
      accentColor: lightBlue,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/home');
            break;
          case 1:
            if (session != null) {
              Navigator.pushNamed(
                context,
                '/daftar-tugas-teknisi-jurusan',
                arguments: session,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Harap login terlebih dahulu')),
              );
            }
            break;
          case 2:
            // show profil (our internal index 3)
            setState(() => _selectedIndex = 3);
            break;
        }
      },
    );
  }
}

class SimplePlaceholder extends StatelessWidget {
  final String title;
  const SimplePlaceholder({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 18))),
    );
  }
}
