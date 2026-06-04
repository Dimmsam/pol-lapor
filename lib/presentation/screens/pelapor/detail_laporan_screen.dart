import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/laporan_lokal.dart';
import '../../../logic/providers/penanganan_provider.dart';
import '../../../logic/providers/tracking_provider.dart';
import '../../../logic/providers/laporan_provider.dart';

import '../../widgets/pelapor/detail_laporan/detail_info_card.dart';
import '../../widgets/pelapor/detail_laporan/detail_photo_card.dart';
import '../../widgets/pelapor/detail_laporan/detail_tracking_card.dart';
import '../../widgets/pelapor/detail_laporan/detail_hasil_perbaikan_card.dart';
import '../../widgets/pelapor/detail_laporan/detail_foto_progres_card.dart';

class DetailLaporanScreen extends StatefulWidget {
  final LaporanLokal laporan;

  const DetailLaporanScreen({super.key, required this.laporan});
  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  bool _showTracking = true;

  late TrackingProvider _trackingProvider;

  @override
  void initState() {
    super.initState();
    _trackingProvider = context.read<TrackingProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _trackingProvider.fetchRiwayat(widget.laporan.formulirId);
        _trackingProvider.startRealtimeListener(widget.laporan.formulirId);

        // Fetch penanganan untuk mendapatkan fotoHasilUrl
        context.read<PenangananProvider>().fetchPenangananForFormulir(widget.laporan.formulirId);

        // Refresh laporan dari server agar status selalu terupdate (misal jika ditolak/dieskalasi)
        context.read<LaporanProvider>().syncFromRemote();
      }
    });
  }

  @override
  void dispose() {
    _trackingProvider.stopRealtimeListener();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    // Ambil laporan terbaru dari provider jika ada (agar auto-refresh setelah edit)
    final provider = context.watch<LaporanProvider>();
    final laporan = provider.getLaporanById(widget.laporan.formulirId) ?? widget.laporan;
    
    final penanganan = context.watch<PenangananProvider>().getPenangananByFormulir(laporan.formulirId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailInfoCard(laporan: laporan, penanganan: penanganan),
          const SizedBox(height: 16),
          DetailPhotoCard(laporan: laporan),
          const SizedBox(height: 16),
          DetailTrackingCard(laporan: laporan),
          if (penanganan != null && penanganan.fotoProgresUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            DetailFotoProgresCard(penanganan: penanganan),
          ],
          if (laporan.status == StatusLaporan.selesai && penanganan != null) ...[
            const SizedBox(height: 16),
            DetailHasilPerbaikanCard(penanganan: penanganan),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}
