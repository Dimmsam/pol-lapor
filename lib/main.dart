import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'data/models/laporan_lokal.dart';
import 'data/models/user_session.dart';
import 'presentation/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: '.env');

  // Init Hive
  await Hive.initFlutter();

  // Register adapter (akan dibuat di Step 6)
  Hive.registerAdapter(LaporanLokalAdapter());
  Hive.registerAdapter(UserSessionAdapter());

  // Buka box
  await Hive.openBox<LaporanLokal>(AppConstants.boxLaporan);
  await Hive.openBox<UserSession>(AppConstants.boxUser);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        home: const SplashScreen(),
      ),
    );
  }
}