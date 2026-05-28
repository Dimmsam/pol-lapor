import 'package:flutter/material.dart';
import 'dart:io';

import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/user_session.dart';
import '../../../logic/providers/penanganan_provider.dart';
import 'profil_teknisi_screen.dart';
import '../pelapor/camera_picker_screen.dart';

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

  // Nilai harus lowercase agar match dengan logika di updateProgresLaporan
  String _status = 'Diproses';
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
      String? fotoUrl;

      // Upload foto ke Supabase Storage jika ada
      if (_pickedImagePath != null && _pickedImagePath!.isNotEmpty) {
        final file = File(_pickedImagePath!);
        if (await file.exists()) {
          final storage = SupabaseService.storage;
          final ext = _pickedImagePath!.split('.').last;
          final fileName =
              'progres_${widget.laporan.formulirId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          final path = 'foto_progres/$fileName';

          await storage
              .from('bukti_laporan')
              .upload(path, file, fileOptions: const FileOptions(upsert: true));

          fotoUrl = storage.from('bukti_laporan').getPublicUrl(path);
        }
      }

      // Update via provider
      if (!mounted) return;
      final provider = context.read<PenangananProvider>();
      final success = await provider.updateProgresLaporan(
        formulirId: widget.laporan.formulirId,
        statusBaru: _status,
        catatanProgres: catatan.isNotEmpty ? catatan : null,
        fotoProgresUrl: fotoUrl,
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
                  _buildStatusDropdown(),
                  const SizedBox(height: 18),

                  // Ambil Foto
                  const Text(
                    'Ambil Foto Bukti Perbaikan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildImagePicker(),
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
                  _buildCatatanField(),
                  const SizedBox(height: 18),

                  // Warning box
                  _buildWarningBox(),
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

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: const [
            DropdownMenuItem(
              value: 'Diproses',
              child: Text('Masih Dikerjakan'),
            ),
            DropdownMenuItem(
              value: 'Selesai',
              child: Text('Selesai Diperbaiki'),
            ),
          ],
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () async {
        final path = await Navigator.push<String?>(
          context,
          MaterialPageRoute(builder: (_) => const CameraPickerScreen()),
        );
        if (path != null && mounted) {
          setState(() => _pickedImagePath = path);
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: DottedBorderPlaceholder(
          child: _pickedImagePath == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6CF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Klik untuk membuka kamera',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Format JPG atau PNG (Maks 5MB)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pickedImagePath!),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _pickedImagePath!.split(RegExp(r'[\\/]')).last,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCatatanField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
        child: TextField(
          controller: _catatanCtrl,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Tuliskan detail perbaikan yang telah dilakukan...',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 48,
            decoration: BoxDecoration(
              color: accentWarn,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PERINGATAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4B00),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Pastikan semua alat kerja telah dirapikan kembali sebelum menutup laporan ini.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
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
                MaterialPageRoute(builder: (_) => const ProfilTeknisiScreen()),
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

// Simple dashed border placeholder (visual only)
class DottedBorderPlaceholder extends StatelessWidget {
  final Widget child;
  const DottedBorderPlaceholder({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}
