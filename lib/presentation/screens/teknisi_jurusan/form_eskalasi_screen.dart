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

  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();
  String? _kategoriTerpilih;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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

    // Jika belum ada penanganan, mulai dulu
    String penangananId;
    if (widget.penanganan == null) {
      await provider.mulaiPenangananLangsung(
        formulirId: widget.laporan.formulirId,
        teknisiId: widget.userSession.userId,
      );
      final p =
          provider.getPenangananByFormulir(widget.laporan.formulirId);
      if (p == null) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membuat penanganan'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      penangananId = p.penangananId;
    } else {
      penangananId = widget.penanganan!.penangananId;
    }

    await provider.eskalasiKeAdminJurusan(
      penangananId: penangananId,
      formulirId: widget.laporan.formulirId,
      catatanEskalasi: _alasanController.text.trim(),
      kategoriKerusakan: _kategoriTerpilih!,
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
              // ── Info Banner ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Laporan ini akan diteruskan ke Admin Jurusan untuk proses persetujuan lebih lanjut.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── ID Laporan ──────────────────────────────────────────
              _buildReadOnlyField(
                label: 'ID Laporan',
                value:
                    '#${widget.laporan.formulirId.substring(0, 8).toUpperCase()}',
                icon: Icons.tag,
              ),

              const SizedBox(height: 14),

              // ── Lokasi ─────────────────────────────────────────────
              _buildReadOnlyField(
                label: 'Lokasi',
                value: widget.laporan.lokasiPerbaikan,
                icon: Icons.location_on_outlined,
              ),

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
                  return DropdownMenuItem(
                    value: k,
                    child: Text(k.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _kategoriTerpilih = v),
              ),

              const SizedBox(height: 20),

              // ── Alasan Eskalasi ────────────────────────────────────
              const Text(
                'Analisis Teknisi / Alasan Eskalasi *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _alasanController,
                maxLines: 5,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                decoration: InputDecoration(
                  hintText:
                      'Berikan alasan teknis mengapa permasalahan ini perlu dieskalasi ke tingkat jurusan...',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Colors.grey),
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
                ),
              ),

              const SizedBox(height: 20),

              // ── Foto Tambahan (Opsional) ────────────────────────────
              const Text(
                'Tambah Foto Detail Kerusakan (Opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // TODO: Implementasi image picker
                },
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 36, color: _accentColor),
                      const SizedBox(height: 8),
                      const Text(
                        'Klik untuk ambil foto atau pilih dari galeri',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Text(
                        'Maksimal 3 foto. Format JPG/PNG',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style:
                      const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}