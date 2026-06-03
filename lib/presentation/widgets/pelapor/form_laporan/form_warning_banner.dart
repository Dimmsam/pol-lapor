import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../logic/providers/form_laporan_provider.dart';

class FormWarningBanner extends StatelessWidget {
  const FormWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final form = context.watch<FormLaporanProvider>();

    if (form.isCheckingSerupa) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Memeriksa laporan serupa...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (form.jumlahLaporanSerupa <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFC107), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan serupa sudah ada!',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF78350F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Terdapat ${form.jumlahLaporanSerupa} laporan aktif '
                    'di lokasi ini. Pastikan belum dilaporkan '
                    'sebelum mengirim laporan baru.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
