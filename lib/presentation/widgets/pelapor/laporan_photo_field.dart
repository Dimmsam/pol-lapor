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

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled
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
      child: Container(
        height: 126,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(imagePath!), fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.black.withValues(alpha: 0.42),
                        child: const Center(
                          child: Text(
                            'Tap untuk ambil ulang (kamera live)',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 30,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap untuk ambil foto live',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }
}
