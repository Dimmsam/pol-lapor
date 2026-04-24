import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'data/models/laporan_lokal.dart';
import 'data/models/user_session.dart';
import 'presentation/screens/home/home_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/login/login_provider.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/pelapor/form_laporan_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(LaporanLokalAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(UserSessionAdapter());
  }

  await Hive.openBox<LaporanLokal>('laporanBox');
  await Hive.openBox<UserSession>('userBox');

  runApp(const PolLaporApp());
}

class PolLaporApp extends StatelessWidget {
  const PolLaporApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: MaterialApp(
        title: 'PolLapor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A5F)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/form': (context) => const FormLaporanScreen(),
        },
        home: const SplashScreen(),
      ),
    );
  }
}
