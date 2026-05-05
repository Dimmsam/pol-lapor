import 'package:flutter/material.dart';

class TeknisiUptStatusBadge extends StatelessWidget {
  final String label;

  const TeknisiUptStatusBadge({super.key, required this.label});

  Color _backgroundColor() {
    final value = label.toLowerCase();
    if (value.contains('selesai')) return const Color(0xFFD1FAE5);
    if (value.contains('aktif') || value.contains('dikerjakan')) {
      return const Color(0xFFDBEAFE);
    }
    return const Color(0xFFF3F4F6);
  }

  Color _textColor() {
    final value = label.toLowerCase();
    if (value.contains('selesai')) return const Color(0xFF059669);
    if (value.contains('aktif') || value.contains('dikerjakan')) {
      return const Color(0xFF1D4ED8);
    }
    return const Color(0xFF4B5563);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _textColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
