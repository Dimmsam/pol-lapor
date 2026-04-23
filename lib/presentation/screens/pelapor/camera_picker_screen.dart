import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPickerScreen extends StatefulWidget {
  const CameraPickerScreen({super.key, this.initialImagePath});

  final String? initialImagePath;

  @override
  State<CameraPickerScreen> createState() => _CameraPickerScreenState();
}

class _CameraPickerScreenState extends State<CameraPickerScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null &&
        widget.initialImagePath!.isNotEmpty) {
      _selectedImage = XFile(widget.initialImagePath!);
    }
  }

  Future<bool> _requestCameraPermission() async {
    final cameraStatus = await Permission.camera.request();
    return cameraStatus.isGranted;
  }

  Future<void> _pickImageFromCamera() async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin kamera belum diberikan.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1800,
      );

      if (!mounted) return;
      setState(() => _selectedImage = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil foto. Coba lagi.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedImage != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Foto Laporan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 46,
                              color: Color(0xFF6B7280),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Belum ada foto dipilih',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    hasImage ? 'Ambil Ulang Foto' : 'Ambil Foto Live',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!hasImage)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Ambil foto live dulu, lalu tekan tombol gunakan foto.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing || !hasImage
                      ? null
                      : () => Navigator.pop(context, _selectedImage!.path),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          hasImage
                              ? 'Gunakan Foto Ini'
                              : 'Ambil Foto Terlebih Dahulu',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
