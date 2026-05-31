import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/models/laporan_lokal.dart';
import '../../../../../logic/providers/penanganan_provider.dart';
import '../../../screens/pelapor/camera_picker_screen.dart';

class UpdateFotoPicker extends StatelessWidget {
  final LaporanLokal laporan;
  final String? pickedImagePath;
  final ValueChanged<String?> onImagePicked;

  const UpdateFotoPicker({
    super.key,
    required this.laporan,
    required this.pickedImagePath,
    required this.onImagePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildExistingPhotos(context),
        const Text(
          'Ambil Foto Bukti Perbaikan',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildImagePicker(context),
      ],
    );
  }

  Widget _buildExistingPhotos(BuildContext context) {
    final provider = context.watch<PenangananProvider>();
    final penanganan = provider.getPenangananByFormulir(
      laporan.formulirId,
    );
    final existingPhotos = penanganan?.fotoProgresUrl ?? [];

    if (existingPhotos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            const Text(
              'Foto Progres Sebelumnya',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              '${existingPhotos.length} foto',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: existingPhotos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showPhotoDialog(context, existingPhotos[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    existingPhotos[index],
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined,
                          color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  void _showPhotoDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54,
                          size: 48),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final path = await Navigator.push<String?>(
          context,
          MaterialPageRoute(builder: (_) => const CameraPickerScreen()),
        );
        if (path != null) {
          onImagePicked(path);
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: _DottedBorderPlaceholder(
          child: pickedImagePath == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6CF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Klik untuk membuka kamera',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Format JPG atau PNG (Maks 5MB)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(pickedImagePath!),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pickedImagePath!.split(RegExp(r'[\\/]')).last,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DottedBorderPlaceholder extends StatelessWidget {
  final Widget child;
  const _DottedBorderPlaceholder({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }
}
