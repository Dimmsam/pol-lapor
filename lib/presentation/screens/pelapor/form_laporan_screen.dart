import '../../screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../data/datasources/local/hive_local_datasource.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../core/constants/app_constants.dart';
import '../../../logic/providers/home_provider.dart';
import '../../../services/sync_service.dart';
import '../../widgets/pelapor/laporan_photo_field.dart';
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
    'Gedung A',
    'Gedung B',
    'Gedung C',
    'Gedung D',
    'Gedung E',
    'Gedung F',
    'Gedung G',
    'Gedung H',
    'Gedung Lab Teknik Refrigerasi dan Tata Udara',
    'Gedung Lab Teknik Mesin',
    'Gedung Lab Teknik Kimia',
    'Gedung Lab Teknik Sipil',
    'Hanggar Aero',
    'Student Center',
    'Gedung Serba Guna AN',
    'Gedung Direktorat',
    'Pendopo Tony Soewandito',
    'Gedung P2T',
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
    return DropdownButtonFormField<String>(
      value: _lokasiPerbaikan,
      isExpanded: true,
      menuMaxHeight: 340,
      icon: const SizedBox.shrink(),
      decoration: _fieldDecoration(hintText: 'Pilih Gedung & Ruangan').copyWith(
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: Color(0xFF6B7280),
        ),
        suffixIcon: const Icon(
          Icons.expand_more_rounded,
          color: Color(0xFF0D47A1),
        ),
        suffixIconColor: const Color(0xFF0D47A1),
      ),
      hint: Text(
        'Pilih Gedung & Ruangan',
        style: TextStyle(color: Colors.grey.shade600),
      ),
      items: _lokasiPerbaikanOptions
          .map(
            (lokasi) => DropdownMenuItem<String>(
              value: lokasi,
              child: Text(lokasi, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Lokasi harus diisi';
        }
        return null;
      },
      onChanged: _isSubmitting
          ? null
          : (value) {
              setState(() => _lokasiPerbaikan = value);
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
