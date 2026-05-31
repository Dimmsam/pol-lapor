import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/penanganan.dart';
import '../../../data/models/tracking.dart';
import '../../../logic/providers/penanganan_provider.dart';
import '../../../logic/providers/tracking_provider.dart';
import '../../../core/utils/status_mapper.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/status_badge.dart';
import '../../../core/utils/date_extension.dart';

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
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        final tp = context.read<TrackingProvider>();
        tp.fetchRiwayat(widget.laporan.formulirId);
        tp.startRealtimeListener(widget.laporan.formulirId);

        // Fetch penanganan untuk mendapatkan fotoHasilUrl
        context.read<PenangananProvider>().fetchPenangananForFormulir(widget.laporan.formulirId);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (mounted) {
      try {
        context.read<TrackingProvider>().stopRealtimeListener();
      } catch (e) {
        debugPrint('Error stopping listener: $e');
      }
    }
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final laporan = widget.laporan;
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
