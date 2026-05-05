import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/surat_kerja.dart';
import '../../../logic/providers/teknisi_upt_provider.dart';
import 'tugas_detail_screen.dart';
import '../../widgets/teknisi_upt/status_badge.dart';

class TeknisiUptTugasListScreen extends StatefulWidget {
  const TeknisiUptTugasListScreen({super.key});

  @override
  State<TeknisiUptTugasListScreen> createState() =>
      _TeknisiUptTugasListScreenState();
}

class _TeknisiUptTugasListScreenState extends State<TeknisiUptTugasListScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const Color _primary = Color(0xFF0D47A1);
  static const Color _background = Color(0xFFF4F6FA);

  final List<_FilterChipData> _filters = const [
    _FilterChipData(label: 'Semua', value: 'semua'),
    _FilterChipData(label: 'Belum', value: 'belum_dimulai'),
    _FilterChipData(label: 'Aktif', value: 'aktif'),
    _FilterChipData(label: 'Selesai', value: 'selesai'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiUptProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Daftar Tugas UPT',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: Consumer<TeknisiUptProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryRow(provider: provider),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: provider.searchTugas,
                          decoration: InputDecoration(
                            hintText: 'Cari nomor SK, sarana, atau lokasi',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: _primary,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final item = _filters[index];
                              final selected =
                                  provider.activeFilter == item.value;
                              return ChoiceChip(
                                label: Text(item.label),
                                selected: selected,
                                onSelected: (_) {
                                  _searchController.clear();
                                  provider.setFilter(item.value);
                                  provider.searchTugas('');
                                },
                                selectedColor: const Color(0xFFDCEAFE),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? _primary
                                      : const Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                                backgroundColor: Colors.white,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.status == TeknisiLoadStatus.error)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: provider.errorMessage ?? 'Gagal memuat data.',
                      onRetry: provider.refresh,
                    ),
                  )
                else if (provider.tugasList.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverList.separated(
                      itemCount: provider.tugasList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tugas = provider.tugasList[index];
                        return _TugasCard(tugas: tugas);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final TeknisiUptProvider provider;

  const _SummaryRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total',
            value: provider.totalTugas.toString(),
            icon: Icons.assignment_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Aktif',
            value: provider.totalAktif.toString(),
            icon: Icons.timelapse_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Selesai',
            value: provider.totalSelesai.toString(),
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TugasCard extends StatelessWidget {
  final SuratKerja tugas;

  const _TugasCard({required this.tugas});

  @override
  Widget build(BuildContext context) {
    final overdue = tugas.isOverdue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
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
                      tugas.nomorSuratKerja?.isNotEmpty == true
                          ? tugas.nomorSuratKerja!
                          : 'Nomor SK belum tersedia',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tugas.namaSarana ?? '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              TeknisiUptStatusBadge(label: tugas.statusDisplay),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.place_outlined,
            text: tugas.lokasiPerbaikan ?? '-',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.event_note_outlined,
            text: tugas.instruksiKerja,
            maxLines: 2,
          ),
          if (tugas.tanggalTargetSelesai != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: overdue
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Target: ${_formatDate(tugas.tanggalTargetSelesai!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: overdue
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (overdue) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Terlambat',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeknisiUptTugasDetailScreen(tugas: tugas),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0D47A1)),
                foregroundColor: const Color(0xFF0D47A1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Lihat Detail'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _InfoRow({required this.icon, required this.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text(
              'Belum ada tugas untuk filter ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Coba ganti filter atau tarik untuk memuat ulang.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipData {
  final String label;
  final String value;

  const _FilterChipData({required this.label, required this.value});
}
