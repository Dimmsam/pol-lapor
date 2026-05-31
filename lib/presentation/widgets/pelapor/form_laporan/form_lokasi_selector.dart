import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../logic/providers/form_laporan_provider.dart';
import '../../../../core/constants/app_constants.dart';

class FormLokasiSelector extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const FormLokasiSelector({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<FormLokasiSelector> createState() => _FormLokasiSelectorState();
}

class _FormLokasiSelectorState extends State<FormLokasiSelector> {
  String? _lokasiPerbaikan;

  @override
  void initState() {
    super.initState();
    _lokasiPerbaikan = widget.initialValue;
  }

  void _checkLaporanSerupa(String lokasi) {
    context.read<FormLaporanProvider>().checkLaporanSerupa(lokasi);
  }

  InputDecoration _fieldDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF1565C0), width: 1.6),
      ),
    );
  }

  Future<String?> _showLocationPicker() async {
    final floor1 = AppConstants.lokasiLantai1;
    final floor2 = AppConstants.lokasiLantai2;

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            String query = '';
            List<String> filter(List<String> src) {
              if (query.isEmpty) return src;
              return src
                  .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            }

            return StatefulBuilder(
              builder: (c, setModalState) {
                final f1 = filter(floor1);
                final f2 = filter(floor2);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Cari lokasi...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setModalState(() => query = v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            if (f1.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Lantai 1',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              ...f1.map(
                                (lok) => ListTile(
                                  title: Text(lok),
                                  onTap: () => Navigator.of(context).pop(lok),
                                ),
                              ),
                            ],
                            if (f2.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Lantai 2',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              ...f2.map(
                                (lok) => ListTile(
                                  title: Text(lok),
                                  onTap: () => Navigator.of(context).pop(lok),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: _lokasiPerbaikan,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Lokasi harus diisi';
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: context.watch<FormLaporanProvider>().isSubmitting
                  ? null
                  : () async {
                      final selected = await _showLocationPicker();
                      if (selected != null) {
                        setState(() => _lokasiPerbaikan = selected);
                        state.didChange(selected);
                        widget.onChanged(selected);
                        _checkLaporanSerupa(selected);
                      }
                    },
              child: InputDecorator(
                decoration: _fieldDecoration(hintText: 'Pilih Ruangan')
                    .copyWith(
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF6B7280),
                      ),
                      suffixIcon: const Icon(
                        Icons.expand_more_rounded,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                child: Text(
                  _lokasiPerbaikan ?? 'Pilih Gedung & Ruangan',
                  style: TextStyle(
                    color: _lokasiPerbaikan == null
                        ? Colors.grey.shade600
                        : Colors.black,
                  ),
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  state.errorText ?? '',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
