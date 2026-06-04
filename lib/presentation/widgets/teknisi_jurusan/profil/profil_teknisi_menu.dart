import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../logic/providers/auth_provider.dart';
import '../../../../../logic/providers/teknisi_dashboard_provider.dart';

class ProfilTeknisiMenu extends StatelessWidget {
  final VoidCallback onProfileUpdated;

  const ProfilTeknisiMenu({
    super.key,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    final namaAktif = session?.nama ?? 'Ahmad Teknisi';

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
              final namaCtrl = TextEditingController(text: namaAktif);
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
                          onPressed: () async {
                            final namaBaru = namaCtrl.text.trim();
                            if (namaBaru.isEmpty) return;

                            await context.read<AuthProvider>().updateNama(
                              namaBaru,
                            );

                            if (ctx.mounted) Navigator.pop(ctx);
                            onProfileUpdated();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profil berhasil diperbarui'),
                                ),
                              );
                            }
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
                          onPressed: () async {
                            if (newCtrl.text != confirmCtrl.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password tidak cocok'),
                                ),
                              );
                              return;
                            }

                            if (newCtrl.text.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password minimal 6 karakter'),
                                ),
                              );
                              return;
                            }

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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal: $e')),
                                );
                              }
                            }
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
    final screenContext = context;

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
            builder: (dialogContext) => AlertDialog(
              title: const Text('Konfirmasi'),
              content: const Text('Apakah Anda yakin ingin keluar?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await screenContext.read<AuthProvider>().logout();
                    if(screenContext.mounted) {
                        screenContext.read<TeknisiDashboardProvider>().clear();
                        Navigator.pushNamedAndRemoveUntil(
                          screenContext,
                          '/login',
                          (route) => false,
                        );
                    }
                  },
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SimplePlaceholder extends StatelessWidget {
  final String title;
  const _SimplePlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 18))),
    );
  }
}
