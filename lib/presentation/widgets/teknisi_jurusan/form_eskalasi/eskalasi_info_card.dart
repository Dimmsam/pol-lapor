import 'package:flutter/material.dart';
import '../../../../../data/models/laporan_lokal.dart';

class EskalasiInfoCard extends StatelessWidget {
  final LaporanLokal laporan;

  const EskalasiInfoCard({
    super.key,
    required this.laporan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Laporan ini akan diteruskan ke Admin Jurusan untuk proses persetujuan lebih lanjut.',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildReadOnlyField(
          label: 'ID Laporan',
          value: '#${laporan.formulirId.substring(0, 8).toUpperCase()}',
          icon: Icons.tag,
        ),
        const SizedBox(height: 14),
        _buildReadOnlyField(
          label: 'Lokasi',
          value: laporan.lokasiPerbaikan,
          icon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
