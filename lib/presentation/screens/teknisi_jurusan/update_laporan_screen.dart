import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/string_extension.dart';

import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/user_session.dart';
import '../../../logic/providers/penanganan_provider.dart';
import 'profil_teknisi_screen.dart';
import '../../widgets/teknisi_jurusan/update_laporan/update_status_dropdown.dart';
import '../../widgets/teknisi_jurusan/update_laporan/update_foto_picker.dart';
import '../../widgets/teknisi_jurusan/update_laporan/update_keterangan_field.dart';

class UpdateLaporanScreen extends StatefulWidget {
  final LaporanLokal laporan;
  final UserSession userSession;

  const UpdateLaporanScreen({
    Key? key,
    required this.laporan,
    required this.userSession,
  }) : super(key: key);

  @override
  State<UpdateLaporanScreen> createState() => _UpdateLaporanScreenState();
}

class _UpdateLaporanScreenState extends State<UpdateLaporanScreen> {
  static const Color primaryNavy = Color(0xFF1A3A8A);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color accentWarn = Color(0xFFD97706);

  // Gunakan konstanta dari AppConstants
  String _status = AppConstants.statusDiproses;
  final TextEditingController _catatanCtrl = TextEditingController();
  String? _pickedImagePath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  // ─── SUBMIT: Upload foto + update penanganan + catat tracking ───────────
  Future<void> _submitUpdate() async {
    final catatan = _catatanCtrl.text.trim();

    setState(() => _isSubmitting = true);

    try {
      // Update via provider
      if (!mounted) return;
      final provider = context.read<PenangananProvider>();
      final success = await provider.updateProgresLaporan(
        formulirId: widget.laporan.formulirId,
        statusBaru: _status,
        catatanProgres: catatan.isNotEmpty ? catatan : null,
        fotoProgresPath: _pickedImagePath,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Laporan berhasil diperbarui'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Gagal memperbarui laporan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'update laporan',
          style: TextStyle(
            color: primaryNavy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status label
                  const Text(
                    'Status Pekerjaan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  UpdateStatusDropdown(
                    status: _status,
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                  const SizedBox(height: 18),

                  // Foto progres
                  UpdateFotoPicker(
                    laporan: widget.laporan,
                    pickedImagePath: _pickedImagePath,
                    onImagePicked: (path) => setState(() => _pickedImagePath = path),
                  ),
                  const SizedBox(height: 18),

                  // Catatan Teknisi
                  const Text(
                    'Catatan Teknisi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  UpdateKeteranganField(
                    controller: _catatanCtrl,
                    accentWarn: accentWarn,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // fixed bottom area: action button + bottom nav
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomArea(),
    );
  }
  Widget _buildBottomArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitUpdate,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text(
                _isSubmitting ? 'Menyimpan...' : 'Update Laporan & Simpan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/dashboard-teknisi-jurusan',
                arguments: widget.userSession,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: _navItem(
              icon: Icons.dashboard_outlined,
              label: 'Beranda',
              active: true,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/daftar-tugas-teknisi-jurusan',
                arguments: widget.userSession,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: _navItem(
              icon: Icons.list_alt_outlined,
              label: 'Tugas',
              active: false,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilTeknisiScreen(userSession: widget.userSession)),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: _navItem(
              icon: Icons.person_outline,
              label: 'Profil',
              active: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? primaryNavy.withOpacity(0.08) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: active ? primaryNavy : Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? primaryNavy : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
