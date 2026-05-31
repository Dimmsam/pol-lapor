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
import '../../widgets/common/status_badge.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/penanganan.dart';
import '../../../data/models/tracking.dart';
import '../../../data/models/user_session.dart';
import '../../../core/utils/status_mapper.dart';
import '../../../core/constants/app_constants.dart';
import 'form_eskalasi_screen.dart';
import 'update_laporan_screen.dart';

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

  bool _isStarting = false;
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
            _buildFotoKerusakan(),
            const SizedBox(height: 16),
            _buildIdDanStatus(penanganan),
            const SizedBox(height: 16),
            _buildInfoLaporan(penanganan),
            const SizedBox(height: 16),
            _buildDeskripsi(),
            const SizedBox(height: 16),
            _buildTrackingCard(),
            const SizedBox(height: 20),
            _buildKlasifikasiKerusakan(sudahMulai, penanganan, provider),
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

  // =========================================================================
  // WIDGET BUILDERS
  // =========================================================================

  Widget _buildFotoKerusakan() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: widget.laporan.fotoKerusakanUrl != null
          ? Image.network(
              widget.laporan.fotoKerusakanUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fotoPlaceholder(),
            )
          : _fotoPlaceholder(),
    );
  }

  Widget _fotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
    );
  }

  Widget _buildIdDanStatus(Penanganan? penanganan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.tag, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '#${widget.laporan.formulirId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        PenangananStatusBadge.fromPenanganan(penanganan),
      ],
    );
  }

  Widget _buildInfoLaporan(Penanganan? penanganan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.laporan.namaSarana,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.laporan.lokasiPerbaikan,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 15, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Pelapor: ${widget.laporan.pelaporId}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          if (widget.laporan.nomorInventaris != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 15,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Inventaris: ${widget.laporan.nomorInventaris}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
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
                  size: 15,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Kategori: ${penanganan.kategoriKerusakan}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeskripsi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi Kerusakan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.laporan.keteranganKerusakan,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKlasifikasiKerusakan(
    bool sudahMulai,
    Penanganan? penanganan,
    PenangananProvider provider,
  ) {
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

        // ── Opsi 1: Rusak Ringan → Perbaiki Sendiri ───────────────────
        _buildOpsiKerusakan(
          borderColor: Colors.green,
          iconColor: Colors.green,
          icon: Icons.check_circle_outline,
          title: 'Rusak Ringan',
          deskripsi:
              'Dapat diperbaiki langsung oleh teknisi piket dengan peralatan standar.',
          tombolLabel: sudahMulai ? 'Update Progres' : 'Perbaiki Sendiri',
          tombolColor: Colors.green,
          isLoading: _isStarting,
          onTap: () async {
            if (!sudahMulai) {
              setState(() => _isStarting = true);
              await provider.mulaiPenangananLangsung(
                formulirId: widget.laporan.formulirId,
                teknisiId: widget.userSession.userId,
              );
              setState(() => _isStarting = false);
            }
            if (!mounted) return;
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

        // ── Opsi 2: Rusak Berat → Eskalasi ke Admin ───────────────────
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
                  penanganan: penanganan,
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

  // =========================================================================
  // HELPERS
  // =========================================================================

  // ─── TRACKING TIMELINE CARD ──────────────────────────────────────────────
  Widget _buildTrackingCard() {
    return Consumer<TrackingProvider>(
      builder: (context, tp, _) {
        final riwayat = tp.riwayatTracking;
        
        final stepsData = AppConstants.trackingStepsData;
        final currentStep = tp.currentStep;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Laporan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              if (tp.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: List.generate(stepsData.length, (index) {
                    final data = stepsData[index];
                    final isCompleted = index < currentStep;
                    final isActive = index == currentStep;
                    final isWaiting = index > currentStep;
                    final isLast = index == stepsData.length - 1;

                    // Find the date
                    DateTime? stepDate;
                    final events = data['events'] as List<String>;
                    try {
                      final found = riwayat.firstWhere(
                          (r) => r.jenisEvent != null && events.contains(r.jenisEvent));
                      stepDate = found.createdAt;
                    } catch (_) {}

                    // Fallback using laporan creation for step 0 if not found
                    if (index == 0 && stepDate == null) {
                       stepDate = widget.laporan.createdAt;
                    }

                    return _buildStepItem(
                      title: data['title'] as String,
                      date: stepDate,
                      isCompleted: isCompleted,
                      isActive: isActive,
                      isWaiting: isWaiting,
                      isLast: isLast,
                    );
                  }),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepItem({
    required String title,
    DateTime? date,
    required bool isCompleted,
    required bool isActive,
    required bool isWaiting,
    required bool isLast,
  }) {
    Color titleColor = isWaiting ? const Color(0xFF9CA3AF) : (isActive ? const Color(0xFF2563EB) : const Color(0xFF1F2937));
    Color subtitleColor = isWaiting ? const Color(0xFFD1D5DB) : const Color(0xFF9CA3AF);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicator column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _buildIndicator(isCompleted: isCompleted, isActive: isActive, isWaiting: isWaiting),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      // Sangat samar atau transparan agar terlihat rapi tanpa garis tebal
                      color: const Color(0xFFF3F4F6), 
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0), // Spacing between steps
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isWaiting ? 'Menunggu...' : _formatTrackingDate(date),
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required bool isCompleted, required bool isActive, required bool isWaiting}) {
    if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF2563EB),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    } else if (isActive) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1F2937), width: 2),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        ),
      );
    }
  }

  String _formatTrackingDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dateTime.day;
    final month = monthNames[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month, $hour:$minute';
  }
}
