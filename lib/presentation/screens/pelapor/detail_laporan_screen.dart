import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/penanganan.dart';
import '../../../data/models/tracking.dart';
import '../../../logic/providers/penanganan_provider.dart';
import '../../../logic/providers/tracking_provider.dart';
import '../../../core/utils/status_mapper.dart';
import '../../widgets/common/status_badge.dart';

class DetailLaporanScreen extends StatefulWidget {
  final LaporanLokal laporan;

  const DetailLaporanScreen({super.key, required this.laporan});
  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  bool _showTracking = true;

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
    context.read<TrackingProvider>().stopRealtimeListener();
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
          _buildInfoCard(laporan, penanganan),
          const SizedBox(height: 16),
          _buildPhotoCard(laporan),
          const SizedBox(height: 16),
          _buildTrackingCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard(LaporanLokal laporan, Penanganan? penanganan) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laporan.namaSarana,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      laporan.keteranganKerusakan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: laporan.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Lokasi: ${laporan.lokasiPerbaikan}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (laporan.nomorInventaris != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No. Inventaris: ${laporan.nomorInventaris}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (penanganan != null && penanganan.kategoriKerusakan != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Kategori: ${penanganan.kategoriKerusakan}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoCard(LaporanLokal laporan) {
    final photoUrl = laporan.fotoKerusakanUrl?.trim();
    final localPath = laporan.fotoLokalPath?.trim();

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 240,
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${laporan.formulirId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 240,
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FOTO LOKAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Color(0xFFD1D5DB),
        ),
      ),
    );
  }

  Widget _buildTrackingCard() {
    return Consumer<TrackingProvider>(
      builder: (context, tp, _) {
        final timelineItems = tp.riwayatTracking.reversed.toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tracking ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showTracking = !_showTracking;
                      });
                    },
                    icon: Icon(
                      _showTracking
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                    label: Text(_showTracking ? 'Sembunyikan' : 'Lihat'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Seperti tracking paket, update ditampilkan berdasarkan riwayat asli yang masuk ke sistem.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              if (tp.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (timelineItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Belum ada update tracking. Timeline akan terisi saat teknisi atau sistem mengirim progres baru.',
                    style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                  ),
                )
              else if (_showTracking)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: timelineItems.asMap().entries.map((entry) {
                      final isLast = entry.key == timelineItems.length - 1;
                      return _TrackingTimelineTile(
                        tracking: entry.value,
                        isLast: isLast,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }


}

class _TrackingTimelineTile extends StatelessWidget {
  const _TrackingTimelineTile({required this.tracking, required this.isLast});

  final Tracking tracking;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getTimelineColor(tracking.jenisEvent ?? ''),
              ),
              child: Icon(
                _getTimelineIcon(tracking.jenisEvent ?? ''),
                color: Colors.white,
                size: 18,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 54, color: const Color(0xFFE5E7EB)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tracking.jenisEvent != null 
                            ? StatusMapper.formatJenisEvent(tracking.jenisEvent!)
                            : tracking.pesanNarasi,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    Text(
                      _formatDateTime(tracking.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tracking.pesanNarasi,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF4B5563),
                  ),
                ),
                if (tracking.aktorId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Aktor: ${tracking.aktorNama ?? (tracking.aktorId != null ? 'User ID: ${tracking.aktorId}' : 'Sistem')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getTimelineColor(String jenisEvent) {
    switch (jenisEvent.toLowerCase()) {
      case 'penanganan_selesai':
        return const Color(0xFF2E7D32); // hijau — selesai
      case 'penanganan_dimulai':
      case 'teknisi_mulai_periksa':
        return const Color(0xFF1565C0); // biru — sedang dikerjakan
      case 'diteruskan_ke_pusat':
        return const Color(0xFFE65100); // oranye — eskalasi
      case 'teknisi_ditugaskan':
        return const Color(0xFF6A1B9A); // ungu — ditugaskan
      case 'laporan_diterima_admin':
        return const Color(0xFF00838F); // teal — diterima admin
      case 'laporan_dibuat':
        return const Color(0xFF455A64); // abu tua — laporan baru
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTimelineIcon(String jenisEvent) {
    switch (jenisEvent.toLowerCase()) {
      case 'penanganan_selesai':
        return Icons.check_circle_outline;
      case 'penanganan_dimulai':
        return Icons.build_outlined;
      case 'teknisi_mulai_periksa':
        return Icons.search;
      case 'diteruskan_ke_pusat':
        return Icons.forward_outlined;
      case 'teknisi_ditugaskan':
        return Icons.person_add_outlined;
      case 'laporan_diterima_admin':
        return Icons.assignment_turned_in_outlined;
      case 'laporan_dibuat':
        return Icons.note_add_outlined;
      default:
        return Icons.schedule;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
