import 'package:flutter/material.dart';
import '../../../../data/models/penanganan.dart';

class DetailFotoProgresCard extends StatelessWidget {
  final Penanganan penanganan;

  const DetailFotoProgresCard({super.key, required this.penanganan});

  @override
  Widget build(BuildContext context) {
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
            'Foto Progres Pengerjaan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: penanganan.fotoProgresUrl.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final url = penanganan.fotoProgresUrl[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 140,
                      height: 140,
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.broken_image_outlined, color: Color(0xFFD1D5DB)),
                    ),
                  ),
                );
              },
            ),
          ),
          if (penanganan.catatanProgres != null && penanganan.catatanProgres!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Catatan: ${penanganan.catatanProgres!}',
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
