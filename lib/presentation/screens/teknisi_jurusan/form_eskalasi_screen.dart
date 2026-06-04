// ============================================================
// File         : form_eskalasi_screen.dart
// Deskripsi    : Form pengajuan eskalasi ke Admin Jurusan.
//                Teknisi mengisi kategori kerusakan + alasan eskalasi.
// ============================================================


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../logic/providers/penanganan_provider.dart';
import '../../../core/constants/app_constants.dart';

import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/penanganan.dart';
import '../../../data/models/user_session.dart';
import '../pelapor/camera_picker_screen.dart';
import '../../widgets/teknisi_jurusan/form_eskalasi/eskalasi_info_card.dart';
import '../../widgets/teknisi_jurusan/form_eskalasi/eskalasi_alasan_field.dart';
import '../../widgets/teknisi_jurusan/form_eskalasi/eskalasi_foto_picker.dart';

class FormEskalasiScreen extends StatefulWidget {
  final LaporanLokal laporan;
  final Penanganan? penanganan;
  final UserSession userSession;

  const FormEskalasiScreen({
    super.key,
    required this.laporan,
    required this.penanganan,
    required this.userSession,
  });

  @override
  State<FormEskalasiScreen> createState() => _FormEskalasiScreenState();
}

class _FormEskalasiScreenState extends State<FormEskalasiScreen> {
  static const Color _primaryColor = Color(0xFF1A237E);
  static const Color _accentColor = Color(0xFFFF6F00);
  static const int _maxFoto = 3;

  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();
  String? _kategoriTerpilih;
  bool _isSubmitting = false;
  /// Path foto lokal yang dipilih teknisi (maks 3).
  final List<String> _fotoTambahanPaths = [];

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  // ─── PICK FOTO ─────────────────────────────────────────────────────────────
  Future<void> _pickFoto() async {
    if (_fotoTambahanPaths.length >= _maxFoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 3 foto sudah dipilih'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final path = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const CameraPickerScreen()),
    );

    if (path != null && mounted) {
      setState(() => _fotoTambahanPaths.add(path));
    }
  }

  void _removeFoto(int index) {
    setState(() => _fotoTambahanPaths.removeAt(index));
  }

  // ─── SUBMIT ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    // Tutup keyboard terlebih dahulu untuk menghindari error didChangeMetrics saat widget di-dispose
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_kategoriTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori kerusakan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<PenangananProvider>();

    await provider.eskalasiKeAdminJurusan(
      formulirId: widget.laporan.formulirId,
      teknisiId: widget.userSession.userId,
      catatanEskalasi: _alasanController.text.trim(),
      kategoriKerusakan: _kategoriTerpilih!,
      fotoTambahanPaths: _fotoTambahanPaths,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (provider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pengajuan eskalasi berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.popUntil(
        context,
        (route) => route.settings.name == '/daftar-tugas-teknisi-jurusan',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pengajuan Eskalasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info Card (Banner, ID Laporan, Lokasi) ─────────────
              EskalasiInfoCard(laporan: widget.laporan),
              const SizedBox(height: 20),

              // ── Kategori Kerusakan ─────────────────────────────────
              const Text(
                'Kategori Kerusakan Khusus *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _kategoriTerpilih,
                hint: const Text('Pilih Kategori',
                    style: TextStyle(fontSize: 13)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                items: AppConstants.kategoriList.map((k) {
                  return DropdownMenuItem<String>(
                    value: k,
                    child: Text(k.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _kategoriTerpilih = v),
              ),

              const SizedBox(height: 20),

              // ── Alasan Eskalasi ────────────────────────────────────
              EskalasiAlasanField(
                controller: _alasanController,
                primaryColor: _primaryColor,
              ),

              const SizedBox(height: 20),

              // ── Foto Tambahan (Opsional) ────────────────────────────
              EskalasiFotoPicker(
                fotoPaths: _fotoTambahanPaths,
                maxFoto: _maxFoto,
                onPickFoto: _pickFoto,
                onRemoveFoto: _removeFoto,
                accentColor: _accentColor,
              ),

              const SizedBox(height: 32),

              // ── Tombol Submit ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _isSubmitting
                        ? 'Mengirim...'
                        : 'Kirim Pengajuan ke Admin ▶',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }


}