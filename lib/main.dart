import 'package:flutter/material.dart';
// Import file view yang sudah dibuat sebelumnya
import 'ui/pelapor/form_laporan_view.dart'; 

void main() {
  // Nantinya di sini kamu akan melakukan inisialisasi Hive
  // sebelum runApp() dipanggil.
  runApp(const PolLaporApp());
}

class PolLaporApp extends StatelessWidget {
  const PolLaporApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pol Lapor',
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Konfigurasi warna biru gelap khas Polban
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Blue 800
          primary: const Color(0xFF1565C0),
        ),
      ),
      // Langsung memanggil View Form Laporan sebagai halaman utama
      home: const FormLaporanView(),
    );
  }
}