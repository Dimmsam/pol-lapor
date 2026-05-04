import 'dart:async'; // Tambahan untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Tambahan untuk cek sinyal

import 'core/constants/app_constants.dart'; 
import 'data/models/laporan_lokal.dart';
import 'data/models/user_session.dart';
import 'logic/providers/home_provider.dart';
import 'logic/providers/login_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/pelapor/form_laporan_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import '/services/sync_service.dart'; // Pastikan path ini sesuai dengan letak SyncService kamu

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

final supabase = Supabase.instance.client;

// Mengubah PolLaporApp menjadi StatefulWidget
class PolLaporApp extends StatefulWidget {
  const PolLaporApp({super.key});

  @override
  State<PolLaporApp> createState() => _PolLaporAppState();
}

class _PolLaporAppState extends State<PolLaporApp> {
  // Variabel untuk menyimpan "CCTV" sinyal
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    
    // Mengaktifkan CCTV sinyal saat aplikasi pertama kali dijalankan
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Jika hasilnya BUKAN 'none', berarti internet baru saja nyala
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint('🌐 Sinyal terdeteksi secara global! Menjalankan Auto-Sync...');
        
        // Panggil fungsi sync secara otomatis
        _syncService.syncUnsyncedData();
      }
    });
  }

  @override
  void dispose() {
    // Wajib dimatikan saat aplikasinya di-close secara penuh agar tidak membebani memori HP
    _connectivitySubscription.cancel();
    super.dispose();
  }

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