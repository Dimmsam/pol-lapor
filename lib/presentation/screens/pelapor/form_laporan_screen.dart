import '../../screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../data/datasources/local/hive_local_datasource.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../logic/providers/home_provider.dart';
import '../../../services/sync_service.dart';
import '../pelapor/camera_picker_screen.dart';

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

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _nomorInventarisController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
      ),
    );
  }

  Widget _sectionLabel(
    String label, {
    bool required = false,
    bool badge = false,
    bool optional = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF1F2937),
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w600,
            ),
          ),
        if (optional)
          Text(
            ' (Optional)',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        const Spacer(),
        if (badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'PENTING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
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

      try {
        await _syncService.syncUnsyncedData();
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar('Gagal menyimpan laporan lokal.');
      return;
    }

    if (!mounted) return;

    context.read<HomeProvider>().onReturnFromForm();

    _formKey.currentState?.reset();
    _judulController.clear();
    _deskripsiController.clear();
    _nomorInventarisController.clear();

    setState(() {
      _isSubmitting = false;
      _lokasiPerbaikan = null;
      _fotoPath = null;
    });

    _showSnackBar('Laporan berhasil disimpan secara offline.');

    // NAVIGASI
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
    final userSession = context.read<HomeProvider>().session;
    final userName = userSession?.nama ?? 'User';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Laporan',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade700,
              child: Text(
                userInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📸 FOTO KERUSAKAN SECTION
                _sectionLabel('Foto Kerusakan', required: true, badge: true),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _fotoPath == null || _fotoPath!.isEmpty
                        ? Container(
                            height: 160,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 44,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum ada foto terpilih',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Image.file(
                            File(_fotoPath!),
                            fit: BoxFit.cover,
                            height: 160,
                            width: double.infinity,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _openCamera,
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Ambil Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ambil foto langsung dari lokasi kerusakan untuk akurasi data.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),

                // 🏷️ NAMA FASILITAS
                _sectionLabel('Nama Fasilitas', required: true),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _judulController,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  decoration: _fieldDecoration(
                    hintText: 'Contoh: AC, Proyektor, Kursi',
                  ).copyWith(counterText: ''),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty)
                      return 'Nama fasilitas tidak boleh kosong';
                    if (text.length < 3) return 'Minimal 3 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 📍 LOKASI
                _sectionLabel('Lokasi', required: true),
                const SizedBox(height: 10),
                _lokasiSelector(),
                const SizedBox(height: 16),

                // 🔢 NOMOR INVENTARIS
                _sectionLabel(
                  'Nomor Inventaris',
                  required: false,
                  optional: true,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nomorInventarisController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    hintText: 'Masukkan nomor jika ada',
                  ),
                ),
                const SizedBox(height: 16),

                // 📝 DESKRIPSI
                _sectionLabel('Deskripsi Kerusakan', required: true),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _deskripsiController,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: _fieldDecoration(
                    hintText:
                        'Jelaskan kerusakan secara singkat dan jelas agar tim teknis mudah mengidentifikasi masalah.',
                  ).copyWith(counterText: ''),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Deskripsi harus diisi';
                    if (text.length < 12) return 'Minimal 12 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // 🚀 BUTTON KIRIM
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                    label: Text(
                      _isSubmitting ? 'Mengirim...' : 'Kirim Laporan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
