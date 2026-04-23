import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pol_lapor/models/laporan_model.dart';

import 'presentation/screens/pelapor/form_laporan_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(LaporanLokalAdapter());
  }

  await Hive.openBox<LaporanLokal>('laporanBox');

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

        '/form': (context) => const FormLaporanScreen(),
      },

      home: const LoginScreen(),
    );
  }
}
