import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pol_lapor/models/laporan_model.dart';

import 'core/constants/app_constants.dart';
import 'data/models/laporan_lokal.dart';
import 'data/models/user_session.dart';
import 'presentation/screens/splash/splash_screen.dart';

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
    return MultiProvider(
      providers: [
        // Provider akan ditambahkan di sini seiring development
      ],
      child: MaterialApp(
        title: 'PolLapor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A5F)),
          useMaterial3: true,
          fontFamily: 'Roboto',
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
