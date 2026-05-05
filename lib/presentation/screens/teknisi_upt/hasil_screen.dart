import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/penanganan.dart';
import '../../../data/models/surat_kerja.dart';
import '../../../logic/providers/teknisi_upt_provider.dart';
import '../../../logic/providers/tugas_detail_provider.dart';
import '../pelapor/camera_picker_screen.dart';

class TeknisiUptHasilScreen extends StatefulWidget {
  final SuratKerja tugas;

  const TeknisiUptHasilScreen({super.key, required this.tugas});

  @override
  State<TeknisiUptHasilScreen> createState() => _TeknisiUptHasilScreenState();
}

class _TeknisiUptHasilScreenState extends State<TeknisiUptHasilScreen> {
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _hasilController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TugasDetailProvider>().loadDetail(widget.tugas.suratKerjaId);
    });
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _hasilController.dispose();
    super.dispose();
  }

  Future<bool> _ensureStarted(TugasDetailProvider provider) async {
    if (provider.sudahDimulai) return true;
    return provider.mulaiPengerjaan();
  }

  Future<void> _showMessage(BuildContext context, String message) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TugasDetailProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            title: const Text(
              'Update Progres',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w700,
              ),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TaskHeader(tugas: widget.tugas),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Progres',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _catatanController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis progres pekerjaan di sini',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF0D47A1),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text('Mulai Dikerjakan'),
                          selected:
                              provider.selectedStatus ==
                              StatusPenanganan.mulaiDikerjakan,
                          onSelected: (_) => provider.setSelectedStatus(
                            StatusPenanganan.mulaiDikerjakan,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Sedang Dikerjakan'),
                          selected:
                              provider.selectedStatus ==
                              StatusPenanganan.sedangDikerjakan,
                          onSelected: (_) => provider.setSelectedStatus(
                            StatusPenanganan.sedangDikerjakan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isSubmitting
                            ? null
                            : () async {
                                if (!await _ensureStarted(provider)) {
                                  if (!context.mounted) return;
                                  await _showMessage(
                                    context,
                                    provider.errorMessage ??
                                        'Gagal memulai pengerjaan.',
                                  );
                                  return;
                                }

                                final success = await provider.simpanProgress(
                                  catatanProgres: _catatanController.text
                                      .trim(),
                                );
                                if (!context.mounted) return;
                                if (success) {
                                  await context
                                      .read<TeknisiUptProvider>()
                                      .refresh();
                                  await _showMessage(
                                    context,
                                    'Progress berhasil disimpan.',
                                  );
                                  Navigator.pop(context, true);
                                } else if (provider.errorMessage != null) {
                                  await _showMessage(
                                    context,
                                    provider.errorMessage!,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: provider.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Simpan Progres'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selesaikan Pekerjaan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hasilController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis hasil perbaikan dan kondisi akhir',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF0D47A1),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: provider.isSubmitting
                            ? null
                            : () async {
                                final result = await Navigator.of(context)
                                    .push<String>(
                                      MaterialPageRoute(
                                        builder: (_) => CameraPickerScreen(
                                          initialImagePath:
                                              provider.fotoHasilPath,
                                        ),
                                      ),
                                    );
                                if (result != null && result.isNotEmpty) {
                                  provider.setFotoHasil(result);
                                }
                              },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Pilih Foto Hasil'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isSubmitting
                            ? null
                            : () async {
                                if (!await _ensureStarted(provider)) {
                                  if (!context.mounted) return;
                                  await _showMessage(
                                    context,
                                    provider.errorMessage ??
                                        'Gagal memulai pengerjaan.',
                                  );
                                  return;
                                }

                                final success = await provider
                                    .selesaikanPekerjaan(
                                      deskripsiHasil: _hasilController.text
                                          .trim(),
                                    );
                                if (!context.mounted) return;
                                if (success) {
                                  await context
                                      .read<TeknisiUptProvider>()
                                      .refresh();
                                  await _showMessage(
                                    context,
                                    'Pekerjaan berhasil diselesaikan.',
                                  );
                                  Navigator.pop(context, true);
                                } else if (provider.errorMessage != null) {
                                  await _showMessage(
                                    context,
                                    provider.errorMessage!,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: provider.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Selesaikan Pekerjaan'),
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TaskHeader extends StatelessWidget {
  final SuratKerja tugas;

  const _TaskHeader({required this.tugas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tugas Yang Dikerjakan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tugas.nomorSuratKerja?.isNotEmpty == true
                ? tugas.nomorSuratKerja!
                : 'Nomor SK belum tersedia',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tugas.namaSarana ?? '-',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }
}
