import 'dart:io';

import 'package:flutter/material.dart';

import '../../screens/pelapor/camera_picker_screen.dart';

class LaporanPhotoField extends StatelessWidget {
  const LaporanPhotoField({
    super.key,
    required this.imagePath,
    required this.onChanged,
    this.enabled = true,
  });

  final String? imagePath;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(imagePath!), fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 34,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada foto terpilih',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: enabled
                ? () async {
                    final pickedPath = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) =>
                            CameraPickerScreen(initialImagePath: imagePath),
                      ),
                    );

                    if (pickedPath == null) return;
                    onChanged(pickedPath);
                  }
                : null,
            icon: const Icon(Icons.camera_alt_outlined),
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
        const SizedBox(height: 8),
        const Text(
          'Ambil foto langsung dari lokasi kerusakan untuk akurasi data.',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
