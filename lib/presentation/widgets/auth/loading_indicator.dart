// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: loading_indicator.dart

import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1565C0);

    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ),
    );
  }
}