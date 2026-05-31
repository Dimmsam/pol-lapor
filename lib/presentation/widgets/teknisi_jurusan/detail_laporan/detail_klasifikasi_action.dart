import 'package:flutter/material.dart';
import '../../../../../data/models/laporan_lokal.dart';
import '../../../../../data/models/penanganan.dart';
import '../../../../../data/models/user_session.dart';
import '../../../../../logic/providers/penanganan_provider.dart';
import '../../../screens/teknisi_jurusan/form_eskalasi_screen.dart';
import '../../../screens/teknisi_jurusan/update_laporan_screen.dart';

class DetailKlasifikasiAction extends StatefulWidget {
  final LaporanLokal laporan;
  final Penanganan? penanganan;
  final UserSession userSession;
  final PenangananProvider provider;
  final bool sudahMulai;

  const DetailKlasifikasiAction({
    super.key,
    required this.laporan,
    required this.penanganan,
    required this.userSession,
    required this.provider,
    required this.sudahMulai,
  });

  @override
  State<DetailKlasifikasiAction> createState() => _DetailKlasifikasiActionState();
}

class _DetailKlasifikasiActionState extends State<DetailKlasifikasiAction> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Klasifikasi Kerusakan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        _buildOpsiKerusakan(
          borderColor: Colors.green,
          iconColor: Colors.green,
          icon: Icons.check_circle_outline,
          title: 'Rusak Ringan',
          deskripsi:
              'Dapat diperbaiki langsung oleh teknisi piket dengan peralatan standar.',
          tombolLabel: widget.sudahMulai ? 'Update Progres' : 'Perbaiki Sendiri',
          tombolColor: Colors.green,
          isLoading: _isStarting,
          onTap: () async {
            if (!widget.sudahMulai) {
              setState(() => _isStarting = true);
              await widget.provider.mulaiPenangananLangsung(
                formulirId: widget.laporan.formulirId,
                teknisiId: widget.userSession.userId,
              );
              setState(() => _isStarting = false);
            }
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UpdateLaporanScreen(
                  laporan: widget.laporan,
                  userSession: widget.userSession,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildOpsiKerusakan(
          borderColor: Colors.red,
          iconColor: Colors.red,
          icon: Icons.warning_amber_outlined,
          title: 'Rusak Berat',
          deskripsi:
              'Memerlukan penggantian unit atau eskalasi ke bagian pengadaan/admin.',
          tombolLabel: 'Eskalasi ke Admin',
          tombolColor: Colors.red,
          tombolOutline: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FormEskalasiScreen(
                  laporan: widget.laporan,
                  penanganan: widget.penanganan,
                  userSession: widget.userSession,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOpsiKerusakan({
    required Color borderColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String deskripsi,
    required String tombolLabel,
    required Color tombolColor,
    bool tombolOutline = false,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deskripsi,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : tombolOutline
                ? OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tombolColor,
                      side: BorderSide(color: tombolColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      tombolLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tombolColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      tombolLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
