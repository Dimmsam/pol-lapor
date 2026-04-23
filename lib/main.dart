import 'package:flutter/material.dart';

// Import yang sudah ada
import 'ui/pelapor/form_laporan_view.dart';

// Tambahan untuk login
import 'presentation/screens/auth/login_screen.dart';

// Tambahan untuk home (BARU)
import 'presentation/screens/home/home_screen.dart';

void main() {
  runApp(const PolLaporApp());
}

class PolLaporApp extends StatelessWidget {
  const PolLaporApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pol Lapor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
        ),
      ),

      routes: {
        '/login': (context) => const LoginScreen(),

        '/home': (context) => const HomeScreen(),

        '/form': (context) => const FormLaporanView(),
      },

      home: const LoginScreen(),
    );
  }
}