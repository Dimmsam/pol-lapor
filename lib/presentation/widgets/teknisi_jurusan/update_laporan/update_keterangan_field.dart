import 'package:flutter/material.dart';

class UpdateKeteranganField extends StatelessWidget {
  final TextEditingController controller;
  final Color accentWarn;

  const UpdateKeteranganField({
    super.key,
    required this.controller,
    required this.accentWarn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
            child: TextField(
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Tuliskan detail perbaikan yang telah dilakukan...',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 48,
                decoration: BoxDecoration(
                  color: accentWarn,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'PERINGATAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4B00),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pastikan semua alat kerja telah dirapikan kembali sebelum menutup laporan ini.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
