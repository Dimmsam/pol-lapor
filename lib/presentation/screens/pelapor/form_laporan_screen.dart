import '../../screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/datasources/local/hive_local_datasource.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../core/constants/app_constants.dart';
import '../../../logic/providers/home_provider.dart';
import '../../../services/sync_service.dart';
import '../../widgets/pelapor/laporan_photo_field.dart';
import 'camera_picker_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'dart:async';

class FormLaporanScreen extends StatefulWidget {
  const FormLaporanScreen({super.key});

  @override
  State<FormLaporanScreen> createState() => _FormLaporanScreenState();
}

class _FormLaporanScreenState extends State<FormLaporanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _datasource = HiveLocalDatasource();
  final _syncService = SyncService();
  final _uuid = const Uuid();

  static const List<String> _lokasiPerbaikanOptions = [
    'D101 - Kelas: Ruang kelas Gedung D, Lantai 1',
    'D102 - Lab. MT: Laboratorium Multimedia dan Teknologi, Lantai 1',
    'D105 - Kelas: Ruang kelas Gedung D, Lantai 1',
    'D106 - Lab. SDB: Laboratorium Sistem Database, Lantai 1',
    'D107 - Lab. RPL: LaboratoriuFm Rekayasa Perangkat Lunak, Lantai 1',
    'D108 - Kelas: Ruang kelas Gedung D, Lantai 1',
    'D111 - Kelas: Ruang kelas Gedung D, Lantai 1',
    'D112 - Kelas: Ruang kelas Gedung D, Lantai 1',
    'D115 - Lab. PjBL-1: Laboratorium Project-Based Learning 1, Lantai 1',
    'D116 - Lab. PjBL-2: Laboratorium Project-Based Learning 2, Lantai 1',
    'D217 - Kelas: Ruang kelas Gedung D, Lantai 2',
    'D219 - Kelas: Ruang kelas Gedung D, Lantai 2',
    'D223 - Kelas: Ruang kelas Gedung D, Lantai 2',
    'D224 - Kelas: Ruang kelas Gedung D, Lantai 2',
  ];

  bool _isSubmitting = false;

  // Controller untuk menangkap input
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _nomorInventarisController =
      TextEditingController(); // Sesuai aturan Polban
  String? _lokasiPerbaikan;
  String? _fotoPath;

  // INIT REALTIME

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

  InputDecoration _selectorDecoration({required String hintText}) {
    return _fieldDecoration(hintText: hintText).copyWith(
      suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
      suffixIconColor: const Color(0xFF1565C0),
    );
  }

  Widget _lokasiSelector() {
    return FormField<String>(
      initialValue: _lokasiPerbaikan,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Lokasi harus diisi';
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _isSubmitting
                  ? null
                  : () async {
                      final selected = await _showLocationPicker();
                      if (selected != null) {
                        setState(() => _lokasiPerbaikan = selected);
                        state.didChange(selected);
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
    final floor1 = _lokasiPerbaikanOptions.take(10).toList();
    final floor2 = _lokasiPerbaikanOptions.skip(10).toList();

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

    setState(() => _isSubmitting = true);

    try {
      final laporan = LaporanLokal(
        formulirId: _uuid.v4(),
        namaSarana: _judulController.text.trim(),
        keteranganKerusakan: _deskripsiController.text.trim(),
        lokasiPerbaikan: _lokasiPerbaikan!.trim(),
        fotoLokalPath: _fotoPath!,
        nomorInventaris: _nomorInventarisController.text.trim().isEmpty
            ? null
            : _nomorInventarisController.text.trim(),
        pelaporId: context.read<HomeProvider>().session?.userId ?? '',
        tandaTanganPelapor: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _datasource.saveLaporan(laporan);
      debugPrint('✅ Laporan tersimpan: ${laporan.formulirId}');

      // ✅ Panggil hanya SEKALI di sini
      if (mounted) context.read<HomeProvider>().onReturnFromForm();

      // Sync di background, tidak perlu tunggu
      _syncService.syncUnsyncedData().catchError((_) {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar('Gagal menyimpan laporan lokal.');
      return;
    }

    if (!mounted) return;

    // Reset form
    _formKey.currentState?.reset();
    _judulController.clear();
    _deskripsiController.clear();
    _nomorInventarisController.clear();
    setState(() {
      _isSubmitting = false;
      _lokasiPerbaikan = null;
      _fotoPath = null;
    });

    _showSnackBar('✅ Laporan berhasil dikirim!');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(initialIndex: 1),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Kerusakan'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Form Laporan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Isi data utama lalu kirim laporan.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '* wajib diisi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _sectionLabel('Nama Sarana', required: true),
                  TextFormField(
                    controller: _judulController,
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                    decoration: _fieldDecoration(
                      hintText: 'Contoh: AC Mati di Ruang 201',
                    ).copyWith(counterText: ''),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Nama sarana tidak boleh kosong';
                      if (text.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
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
                  const SizedBox(height: 12),

                  _sectionLabel('Keterangan Kerusakan', required: true),
                  TextFormField(
                    controller: _deskripsiController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: _fieldDecoration(
                      hintText: 'Jelaskan detail kerusakan yang terlihat...',
                    ).copyWith(counterText: ''),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Deskripsi harus diisi';
                      if (text.length < 12) return 'Minimal 12 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _sectionLabel('Foto Bukti Kerusakan', required: true),
                  LaporanPhotoField(
                    imagePath: _fotoPath,
                    enabled: !_isSubmitting,
                    onChanged: (value) {
                      setState(() => _fotoPath = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Wajib: ambil foto live dari kamera.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _isSubmitting
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Kirim Laporan',
                                key: ValueKey('idle'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
    );
  }

  Future<void> _openCamera() async {
    final pickedPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CameraPickerScreen(initialImagePath: _fotoPath),
      ),
    );
    if (pickedPath == null) return;
    setState(() => _fotoPath = pickedPath);
  }
}
