// Nama Pembuat File: Rina Permata Dewi
// NIM: 241511061
// File: login_text_field.dart

import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1565C0);

    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}