import 'dart:io';
import 'package:flutter/material.dart';

class EskalasiFotoPicker extends StatelessWidget {
  final List<String> fotoPaths;
  final int maxFoto;
  final VoidCallback onPickFoto;
  final ValueChanged<int> onRemoveFoto;
  final Color accentColor;

  const EskalasiFotoPicker({
    super.key,
    required this.fotoPaths,
    required this.maxFoto,
    required this.onPickFoto,
    required this.onRemoveFoto,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tambah Foto Detail Kerusakan (Opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            Text(
              '${fotoPaths.length}/$maxFoto',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fotoPaths.length >= maxFoto ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (fotoPaths.isNotEmpty) ...[
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fotoPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(fotoPaths[index]),
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemoveFoto(index),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (fotoPaths.length < maxFoto)
          GestureDetector(
            onTap: onPickFoto,
            child: Container(
              width: double.infinity,
              height: fotoPaths.isEmpty ? 120 : 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: fotoPaths.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 36, color: accentColor),
                        const SizedBox(height: 8),
                        const Text(
                          'Klik untuk ambil foto atau pilih dari galeri',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Text(
                          'Maksimal 3 foto. Format JPG/PNG',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 22, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Tambah foto lagi (${maxFoto - fotoPaths.length} tersisa)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
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
