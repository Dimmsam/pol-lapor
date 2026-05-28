import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/constants/app_constants.dart';
import 'data/models/laporan_lokal.dart';
import 'data/models/user_session.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/form_laporan_provider.dart';
import 'logic/providers/laporan_provider.dart';
import 'logic/providers/notifikasi_provider.dart';
import 'logic/providers/penanganan_provider.dart';
import 'logic/providers/teknisi_dashboard_provider.dart';
import 'logic/providers/tracking_provider.dart';
import 'presentation/screens/pelapor/home_screen.dart';
import 'presentation/screens/pelapor/notif_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/pelapor/form_laporan_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/teknisi_jurusan/dashboard_teknisi_jurusan_screen.dart';
import 'presentation/screens/teknisi_jurusan/daftar_tugas_screen.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(LaporanLokalAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(UserSessionAdapter());
  }

  await Hive.openBox<LaporanLokal>(AppConstants.boxLaporan);
  await Hive.openBox<UserSession>(AppConstants.boxUser);

  runApp(const PolLaporApp());
}

class PolLaporApp extends StatefulWidget {
  const PolLaporApp({super.key});

  @override
  State<PolLaporApp> createState() => _PolLaporAppState();
}

class _PolLaporAppState extends State<PolLaporApp> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint('Sinyal terdeteksi! Menjalankan Auto-Sync...');
        _syncService.syncUnsyncedData();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final p = LaporanProvider();
            p.init();
            return p;
          },
        ),
        ChangeNotifierProvider(create: (_) => FormLaporanProvider()),
        ChangeNotifierProvider(create: (_) => TeknisiDashboardProvider()),
        ChangeNotifierProvider(create: (_) => PenangananProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => NotifikasiProvider()),
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
          '/notif': (context) => const NotifScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/dashboard-teknisi-jurusan') {
            final userSession = settings.arguments as UserSession;
            return MaterialPageRoute(
              builder: (_) => DashboardTeknisiJurusanScreen(
                userSession: userSession,
              ),
            );
          }

          if (settings.name == '/daftar-tugas-teknisi-jurusan') {
            final userSession = settings.arguments as UserSession;
            return MaterialPageRoute(
              builder: (_) => DaftarTugasScreen(
                userSession: userSession,
              ),
            );
          }

          return null;
        },
        home: const SplashScreen(),
      ),
    );
  }
}
