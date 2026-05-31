import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/laporan_validator.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../logic/providers/form_laporan_provider.dart';
import '../../../logic/providers/laporan_provider.dart';
import '../../widgets/pelapor/laporan_photo_field.dart';

import 'dart:async';

class FormLaporanScreen extends StatefulWidget {
  /// Jika diisi → mode Edit. Jika null → mode Buat Baru.
  final LaporanLokal? laporanEdit;

  const FormLaporanScreen({super.key, this.laporanEdit});

  @override
  State<FormLaporanScreen> createState() => _FormLaporanScreenState();
}

class _FormLaporanScreenState extends State<FormLaporanScreen> {
  // ── Shortcut helper ───────────────────────────────────────────────────────
  bool get _isEditMode => widget.laporanEdit != null;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _nomorInventarisController =
      TextEditingController();
  String? _lokasiPerbaikan;
  String? _fotoPath;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Jika mode edit, prefill semua field dengan data laporan lama
    if (_isEditMode) {
      final l = widget.laporanEdit!;
      _judulController.text = l.namaSarana;
      _deskripsiController.text = l.keteranganKerusakan;
      _nomorInventarisController.text = l.nomorInventaris ?? '';
      _lokasiPerbaikan = l.lokasiPerbaikan;
      _fotoPath = l.fotoLokalPath;
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _nomorInventarisController.dispose();
    super.dispose();
  }

  // ── Cek laporan serupa ────────────────────────────────────────────────────
  void _checkLaporanSerupa(String lokasi) {
    context.read<FormLaporanProvider>().checkLaporanSerupa(lokasi);
  }

  // ── Banner peringatan laporan serupa ──────────────────────────────────────
  Widget _buildWarningBanner() {
    final form = context.watch<FormLaporanProvider>();

    if (form.isCheckingSerupa) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Memeriksa laporan serupa...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (form.jumlahLaporanSerupa <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFC107), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan serupa sudah ada!',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF78350F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Terdapat ${form.jumlahLaporanSerupa} laporan aktif '
                    'di lokasi ini. Pastikan belum dilaporkan '
                    'sebelum mengirim laporan baru.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF1565C0), width: 1.6),
      ),
    );
  }

  Widget _sectionLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
          children: [
            TextSpan(text: label),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Lokasi selector ───────────────────────────────────────────────────────
  Widget _lokasiSelector() {
    return FormField<String>(
      initialValue: _lokasiPerbaikan,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Lokasi harus diisi';
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: context.watch<FormLaporanProvider>().isSubmitting
                  ? null
                  : () async {
                      final selected = await _showLocationPicker();
                      if (selected != null) {
                        setState(() => _lokasiPerbaikan = selected);
                        state.didChange(selected);
                        _checkLaporanSerupa(selected);
                      }
                    },
              child: InputDecorator(
                decoration: _fieldDecoration(hintText: 'Pilih Ruangan')
                    .copyWith(
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF6B7280),
                      ),
                      suffixIcon: const Icon(
                        Icons.expand_more_rounded,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                child: Text(
                  _lokasiPerbaikan ?? 'Pilih Gedung & Ruangan',
                  style: TextStyle(
                    color: _lokasiPerbaikan == null
                        ? Colors.grey.shade600
                        : Colors.black,
                  ),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  state.errorText ?? '',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<String?> _showLocationPicker() async {
    final floor1 = AppConstants.lokasiLantai1;
    final floor2 = AppConstants.lokasiLantai2;

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            String query = '';
            List<String> filter(List<String> src) {
              if (query.isEmpty) return src;
              return src
                  .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            }

            return StatefulBuilder(
              builder: (c, setModalState) {
                final f1 = filter(floor1);
                final f2 = filter(floor2);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Cari lokasi...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setModalState(() => query = v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            if (f1.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Lantai 1',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              ...f1.map(
                                (lok) => ListTile(
                                  title: Text(lok),
                                  onTap: () => Navigator.of(context).pop(lok),
                                ),
                              ),
                            ],
                            if (f2.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Lantai 2',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              ...f2.map(
                                (lok) => ListTile(
                                  title: Text(lok),
                                  onTap: () => Navigator.of(context).pop(lok),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Submit: beda logika untuk create vs edit ──────────────────────────────
  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _showSnackBar('Form belum lengkap. Cek lagi field yang wajib diisi.');
      return;
    }

    if (_fotoPath == null || _fotoPath!.isEmpty) {
      _showSnackBar('Foto bukti wajib diambil langsung dari kamera.');
      return;
    }

    final formProvider = context.read<FormLaporanProvider>();
    final laporanProvider = context.read<LaporanProvider>();
    final nomorInv = _nomorInventarisController.text.trim().isEmpty
        ? null
        : _nomorInventarisController.text.trim();

    final success = await formProvider.submitLaporan(
      laporanEdit: widget.laporanEdit,
      namaSarana: _judulController.text.trim(),
      keteranganKerusakan: _deskripsiController.text.trim(),
      lokasiPerbaikan: _lokasiPerbaikan!.trim(),
      fotoLokalPath: _fotoPath,
      pelaporId: laporanProvider.session?.userId,
      nomorInventaris: nomorInv,
    );

    if (!mounted) return;

    if (success) {
      laporanProvider.onReturnFromForm();
      if (_isEditMode) {
        _showSnackBar('Laporan berhasil diperbarui!');
        Navigator.pop(context);
      } else {
        _formKey.currentState?.reset();
        _judulController.clear();
        _deskripsiController.clear();
        _nomorInventarisController.clear();
        setState(() {
          _lokasiPerbaikan = null;
          _fotoPath = null;
        });
        _showSnackBar('Laporan berhasil dikirim!');
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else {
      _showSnackBar(formProvider.errorMessage ??
          (_isEditMode ? 'Gagal memperbarui laporan.' : 'Gagal menyimpan laporan lokal.'));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      body: Stack(
        children: [
          // Header biru
          Container(
            height: 255,
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar custom
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      // Tombol back hanya di mode edit
                      if (_isEditMode)
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Text(
                        'PolLapor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul berubah sesuai mode
                      Text(
                        _isEditMode
                            ? 'Edit Laporan\nKerusakan'
                            : 'Buat Laporan\nKerusakan',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isEditMode
                            ? 'Perbarui informasi laporan yang sudah dibuat.'
                            : 'Laporkan kerusakan fasilitas kampus dengan cepat dan rapi.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.92),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Form card
          Positioned.fill(
            top: 190,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _isEditMode ? 'Edit Laporan' : 'Form Laporan',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '* wajib diisi',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEditMode
                              ? 'Ubah data yang perlu diperbarui lalu simpan.'
                              : 'Isi data utama lalu kirim laporan.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 18),

                        _sectionLabel('Nama Sarana', required: true),
                        TextFormField(
                          controller: _judulController,
                          textInputAction: TextInputAction.next,
                          maxLength: 80,
                          decoration: _fieldDecoration(
                            hintText: 'Contoh: AC Mati di Ruang 201',
                          ).copyWith(counterText: ''),
                          validator: LaporanValidator.validateNamaSarana,
                        ),
                        const SizedBox(height: 12),

                        _sectionLabel('Nomor Inventaris'),
                        TextFormField(
                          controller: _nomorInventarisController,
                          textInputAction: TextInputAction.next,
                          decoration: _fieldDecoration(
                            hintText: 'Lihat stiker pada barang',
                          ),
                        ),
                        const SizedBox(height: 12),

                        _sectionLabel('Lokasi Perbaikan', required: true),
                        _lokasiSelector(),
                        const SizedBox(height: 10),

                        _buildWarningBanner(),

                        _sectionLabel('Keterangan Kerusakan', required: true),
                        TextFormField(
                          controller: _deskripsiController,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: 500,
                          decoration: _fieldDecoration(
                            hintText:
                                'Jelaskan detail kerusakan yang terlihat...',
                          ).copyWith(counterText: ''),
                          validator: LaporanValidator.validateDeskripsi,
                        ),
                        const SizedBox(height: 16),

                        _sectionLabel('Foto Bukti Kerusakan', required: true),
                        LaporanPhotoField(
                          imagePath: _fotoPath,
                          enabled: !context.watch<FormLaporanProvider>().isSubmitting,
                          onChanged: (value) =>
                              setState(() => _fotoPath = value),
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: context.watch<FormLaporanProvider>().isSubmitting
                                ? null
                                : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: context.watch<FormLaporanProvider>().isSubmitting
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      _isEditMode
                                          ? 'Simpan Perubahan'
                                          : 'Kirim Laporan',
                                      key: ValueKey(
                                        _isEditMode ? 'edit' : 'idle',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Consumer<FormLaporanProvider>(
            builder: (context, provider, child) {
              if (!provider.isSubmitting) return const SizedBox.shrink();
              return Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
