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
import '../../../logic/providers/notifikasi_provider.dart';
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

  late TrackingProvider _trackingProvider;

  @override
  void initState() {
    super.initState();
    _trackingProvider = context.read<TrackingProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackingProvider.fetchRiwayat(widget.laporan.formulirId);
      _trackingProvider.startRealtimeListener(widget.laporan.formulirId);
      
      // Refresh tugas dari server agar status selalu terupdate (misal jika ditolak/dieskalasi)
      context.read<PenangananProvider>().loadDaftarTugas(teknisiId: widget.userSession.userId);
    });
  }

  @override
  void dispose() {
    // Gunakan referensi provider yang disimpan di initState
    _trackingProvider.stopRealtimeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PenangananProvider>();
    
    // Cari laporan terbaru dari provider jika ada (agar auto-refresh setelah ada perubahan status dari admin)
    final laporanTerbaru = provider.daftarTugas.firstWhere(
      (l) => l.formulirId == widget.laporan.formulirId,
      orElse: () => widget.laporan,
    );
    
    final penanganan = provider.getPenangananByFormulir(
      laporanTerbaru.formulirId,
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/notif',
                    arguments: widget.userSession,
                  );
                },
                icon: const Icon(Icons.notifications_outlined),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Consumer<NotifikasiProvider>(
                  builder: (context, notifProvider, _) {
                    final notifCount = notifProvider.unreadCount;
                    if (notifCount == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _primaryColor, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          notifCount > 9 ? '9+' : notifCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailFotoKerusakan(fotoKerusakanUrl: laporanTerbaru.fotoKerusakanUrl),
            const SizedBox(height: 16),
            DetailInfoLaporan(laporan: laporanTerbaru, penanganan: penanganan),
            const SizedBox(height: 16),
            DetailTrackingStatus(laporan: laporanTerbaru),
            const SizedBox(height: 20),
            DetailKlasifikasiAction(
              laporan: laporanTerbaru,
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
