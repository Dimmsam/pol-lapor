// ============================================================
// File         : detail_laporan_teknisi_screen.dart
// Deskripsi    : Halaman Detail Laporan untuk Teknisi Jurusan.
//                2 tombol aksi:
//                - Perbaiki Sendiri → coming soon
//                - Eskalasi ke Admin → FormEskalasiScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/penanganan_provider.dart';
import '../../../logic/providers/tracking_provider.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/user_session.dart';
import '../../widgets/teknisi_jurusan/detail_laporan/detail_foto_kerusakan.dart';
import '../../widgets/teknisi_jurusan/detail_laporan/detail_info_laporan.dart';
import '../../widgets/teknisi_jurusan/detail_laporan/detail_tracking_status.dart';
import '../../widgets/teknisi_jurusan/detail_laporan/detail_klasifikasi_action.dart';

class DetailLaporanTeknisiScreen extends StatefulWidget {
  final LaporanLokal laporan;
  final UserSession userSession;

  const DetailLaporanTeknisiScreen({
    super.key,
    required this.laporan,
    required this.userSession,
  });

  @override
  State<DetailLaporanTeknisiScreen> createState() =>
      _DetailLaporanTeknisiScreenState();
}

class _DetailLaporanTeknisiScreenState
    extends State<DetailLaporanTeknisiScreen> {
  static const Color _primaryColor = Color(0xFF1A237E);
  static const Color _bgColor = Color(0xFFF5F6FA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = context.read<TrackingProvider>();
      tp.fetchRiwayat(widget.laporan.formulirId);
      tp.startRealtimeListener(widget.laporan.formulirId);
    });
  }

  @override
  void dispose() {
    // Hanya stop realtime, jangan dispose provider karena dikelola oleh MultiProvider
    context.read<TrackingProvider>().stopRealtimeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PenangananProvider>();
    final penanganan = provider.getPenangananByFormulir(
      widget.laporan.formulirId,
    );
    final sudahMulai = penanganan != null;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detail Laporan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailFotoKerusakan(fotoKerusakanUrl: widget.laporan.fotoKerusakanUrl),
            const SizedBox(height: 16),
            DetailInfoLaporan(laporan: widget.laporan, penanganan: penanganan),
            const SizedBox(height: 16),
            DetailTrackingStatus(laporan: widget.laporan),
            const SizedBox(height: 20),
            DetailKlasifikasiAction(
              laporan: widget.laporan,
              penanganan: penanganan,
              userSession: widget.userSession,
              provider: provider,
              sudahMulai: sudahMulai,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard-teknisi-jurusan',
                  (route) => false,
                  arguments: widget.userSession,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text(
                'Kembali ke Beranda',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }


}
