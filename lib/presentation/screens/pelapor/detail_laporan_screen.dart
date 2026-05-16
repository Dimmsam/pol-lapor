import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/laporan_lokal.dart';
import '../../../logic/providers/tracking_provider.dart';
import '../../../services/tracking_service.dart';
import '../../screens/pelapor/camera_picker_screen.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';

class DetailLaporanScreen extends StatefulWidget {
  final LaporanLokal laporan;

  const DetailLaporanScreen({super.key, required this.laporan});

  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  final TextEditingController _catatanCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackingProvider>().fetchRiwayat(widget.laporan.formulirId);
    });
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitCatatan() async {
    final text = _catatanCtrl.text.trim();
    if (text.isEmpty) return;

    final session = AuthLocalDatasource().getSession();
    final aktorId = session?.userId;

    setState(() => _isSubmitting = true);
    try {
      await TrackingService().catatTracking(
        formulirId: widget.laporan.formulirId,
        aktorId: aktorId,
        statusLaporan: widget.laporan.status,
        pesanNarasi: text,
      );

      await context.read<TrackingProvider>().fetchRiwayat(
        widget.laporan.formulirId,
      );
      _catatanCtrl.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final laporan = widget.laporan;
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            laporan.namaSarana,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            laporan.keteranganKerusakan,
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(laporan.status),
                  ],
                ),
                const SizedBox(height: 12),
                if (laporan.fotoKerusakanUrl != null)
                  Image.network(laporan.fotoKerusakanUrl!),
                const SizedBox(height: 12),
                Text(
                  'Lokasi: ${laporan.lokasiPerbaikan}',
                  style: const TextStyle(color: Color(0xFF4B5563)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Riwayat Tracking
          const Text(
            'Riwayat Tracking',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Consumer<TrackingProvider>(
            builder: (context, tp, _) {
              if (tp.isLoading)
                return const Center(child: CircularProgressIndicator());
              if (tp.riwayatTracking.isEmpty)
                return const Text('Belum ada catatan tracking.');

              return Column(
                children: tp.riwayatTracking.map((t) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          child: Text(
                            (t.aktorId ?? 'S').substring(0, 1).toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.pesanNarasi,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    t.status,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 14),

          // Tambah catatan (hanya pelapor yang membuat laporan)
          FutureBuilder(
            future: Future.microtask(() => AuthLocalDatasource().getSession()),
            builder: (context, snap) {
              final session = snap.data;
              final canAdd =
                  session != null && session.userId == laporan.pelaporId;
              if (!canAdd) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tambah Catatan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _catatanCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tulis catatan...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitCatatan,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Kirim'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.of(context)
                                .push<String>(
                                  MaterialPageRoute(
                                    builder: (_) => const CameraPickerScreen(
                                      initialImagePath: null,
                                    ),
                                  ),
                                );
                            if (result != null && result.isNotEmpty) {
                              // TODO: upload image and attach to tracking (future work)
                            }
                          },
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Tambah Foto'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _buildStatusBadge(String status) {
  Color bg;
  Color fg;
  String label;

  switch (status.toLowerCase()) {
    case 'selesai':
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
      label = 'Selesai';
      break;
    case 'diproses':
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      label = 'Diproses';
      break;
    default:
      bg = const Color(0xFFF3F4F6);
      fg = const Color(0xFF6B7280);
      label = 'Menunggu';
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}
