import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../screens/pelapor/camera_picker_screen.dart';

class LaporanPhotoField extends StatelessWidget {
  const LaporanPhotoField({
    super.key,
    required this.imagePath,
    this.imageUrl,
    required this.onChanged,
    this.enabled = true,
  });

  final String? imagePath;
  final String? imageUrl;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasLocalImage = imagePath != null && imagePath!.isNotEmpty;
    final hasNetworkImage = imageUrl != null && imageUrl!.isNotEmpty;
    final hasImage = hasLocalImage || hasNetworkImage;

    Widget imageWidget;
    if (hasLocalImage) {
      imageWidget = Image.file(File(imagePath!), fit: BoxFit.cover);
    } else if (hasNetworkImage) {
      imageWidget = Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey));
    } else {
      imageWidget = const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD6DCE5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: imageWidget,
                        )
                      : CustomPaint(
                          painter: _DashedRoundedBorderPainter(
                            color: const Color(0xFFCBD5E1),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.photo_camera_outlined,
                                      size: 30,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Belum ada foto terpilih',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () async {
                            final pickedPath = await Navigator.of(context)
                                .push<String>(
                              MaterialPageRoute(
                                builder: (_) => CameraPickerScreen(
                                  initialImagePath: imagePath,
                                ),
                              ),
                            );

                            if (pickedPath == null) return;
                            onChanged(pickedPath);
                          }
                        : null,
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    label: const Text(
                      'Ambil Foto',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ambil foto langsung dari lokasi kerusakan untuk akurasi data.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  _DashedRoundedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(18),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dashWidth = 7.0;
      const dashGap = 5.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
