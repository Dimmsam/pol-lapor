import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/datasources/local/hive_local_datasource.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../logic/providers/home_provider.dart';
import '../../../services/sync_service.dart';
import '../../widgets/pelapor/laporan_photo_field.dart';

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
  bool _isSubmitting = false;

  // Controller untuk menangkap input
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _nomorInventarisController =
      TextEditingController(); // Sesuai aturan Polban
  String? _fotoPath;

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _nomorInventarisController.dispose();
    super.dispose();
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
        lokasiPerbaikan: _lokasiController.text.trim(),
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

      // Tetap offline-first: simpan lokal dulu, lalu coba sync ke cloud.
      try {
        await _syncService.syncUnsyncedData();
      } catch (_) {
        // Gagal sync tidak membatalkan simpan lokal.
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar('Gagal menyimpan laporan lokal.');
      return;
    }

    if (!mounted) return;

    // Refresh statistik di HomeProvider
    context.read<HomeProvider>().onReturnFromForm();

    _formKey.currentState?.reset();
    _judulController.clear();
    _deskripsiController.clear();
    _lokasiController.clear();
    _nomorInventarisController.clear();
    setState(() {
      _isSubmitting = false;
      _fotoPath = null;
    });

    _showSnackBar('Laporan berhasil disimpan secara offline.');
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
                  TextFormField(
                    controller: _lokasiController,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(
                      hintText: 'Contoh: Gedung J Lantai 2',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Lokasi harus diisi';
                      return null;
                    },
                  ),
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
}
