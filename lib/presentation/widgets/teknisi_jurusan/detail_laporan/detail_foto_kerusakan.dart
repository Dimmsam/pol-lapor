import 'package:flutter/material.dart';

class DetailFotoKerusakan extends StatelessWidget {
  final String? fotoKerusakanUrl;

  const DetailFotoKerusakan({
    super.key,
    required this.fotoKerusakanUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: fotoKerusakanUrl != null
          ? Image.network(
              fotoKerusakanUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fotoPlaceholder(),
            )
          : _fotoPlaceholder(),
    );
  }

  Widget _fotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
    );
  }
}
