import 'package:flutter/material.dart';
import '../../../../data/models/penanganan.dart';

class DetailHasilPerbaikanCard extends StatelessWidget {
  final Penanganan penanganan;

  const DetailHasilPerbaikanCard({super.key, required this.penanganan});

  @override
  Widget build(BuildContext context) {
    if (penanganan.fotoHasilUrl == null || penanganan.fotoHasilUrl!.isEmpty) {
      return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bukti Penyelesaian',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              penanganan.fotoHasilUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFF3F4F6),
                child: const Icon(Icons.broken_image_outlined, color: Color(0xFFD1D5DB)),
              ),
            ),
          ),
          if (penanganan.deskripsiHasil != null && penanganan.deskripsiHasil!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              penanganan.deskripsiHasil!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
