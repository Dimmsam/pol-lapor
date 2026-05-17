// ============================================================
// File         : detail_laporan_teknisi_screen.dart
// Deskripsi    : Halaman Detail Laporan untuk Teknisi Jurusan.
//                2 tombol aksi:
//                - Perbaiki Sendiri → coming soon
//                - Eskalasi ke Admin → FormEskalasiScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/providers/teknisi_jurusan_provider.dart';
import '../../../data/models/laporan_lokal.dart';
import '../../../data/models/penanganan.dart';
import '../../../data/models/user_session.dart';
import 'form_eskalasi_screen.dart';

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
  static const Color _accentColor = Color(0xFFFF6F00);
  static const Color _bgColor = Color(0xFFF5F6FA);

  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeknisiJurusanProvider>();
    final penanganan =
        provider.getPenangananByFormulir(widget.laporan.formulirId);
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
            _buildInfoLaporan(),
            const SizedBox(height: 16),
            _buildDeskripsi(),
            const SizedBox(height: 20),
            _buildKlasifikasiKerusakan(sudahMulai, penanganan, provider),
            const SizedBox(height: 32),
          ],
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
    final statusLabel = penanganan == null
        ? 'Pending'
        : StatusPenanganan.toLabel(penanganan.statusPenanganan);
    final statusColor = _getStatusColor(penanganan);

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.4)),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLaporan() {
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
              const Icon(Icons.location_on_outlined,
                  size: 15, color: Colors.grey),
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
                'Pelapor: ${widget.laporan.pelaporId.substring(0, 8)}...',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          if (widget.laporan.nomorInventaris != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Inventaris: ${widget.laporan.nomorInventaris}',
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
    TeknisiJurusanProvider provider,
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
            // TODO: Navigate ke FormPerbaikiSendiriScreen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Form perbaiki sendiri — coming soon!'),
                backgroundColor: Colors.green,
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
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
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
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
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
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
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

  Color _getStatusColor(Penanganan? penanganan) {
    if (penanganan == null) return _accentColor;
    switch (penanganan.statusPenanganan) {
      case StatusPenanganan.sedangDikerjakan:
        return const Color(0xFF1565C0);
      case StatusPenanganan.selesai:
        return const Color(0xFF2E7D32);
      case StatusPenanganan.menungguEskalasi:
        return Colors.red;
      default:
        return _accentColor;
    }
  }
}