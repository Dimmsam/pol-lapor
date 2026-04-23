import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Import sesuai struktur folder proyekmu
import 'core/constants/app_constants.dart';
import 'data/models/laporan_lokal.dart';
import 'data/models/user_session.dart';
import 'ui/pelapor/form_laporan_view.dart';

Future<void> main() async {
  // Pastikan binding Flutter sudah siap sebelum inisialisasi async
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Konfigurasi Environment (.env)
  // Digunakan untuk menyimpan Base URL API dan API Key Cloudinary
  await dotenv.load(fileName: '.env');

  // 2. Inisialisasi Hive untuk Penyimpanan Lokal (Offline-First)
  // Memungkinkan pelaporan kerusakan tanpa koneksi internet
  await Hive.initFlutter();

  // 3. Register Adapter Hive
  // Menghubungkan model data dengan database lokal Hive
  Hive.registerAdapter(LaporanLokalAdapter());
  Hive.registerAdapter(UserSessionAdapter());

  // 4. Buka Box Hive
  // Menyiapkan wadah penyimpanan untuk data laporan dan sesi pengguna
  await Hive.openBox<LaporanLokal>(AppConstants.boxLaporan);
  await Hive.openBox<UserSession>(AppConstants.boxUser);

  // Jalankan aplikasi dengan nama class yang benar
  runApp(const PolLaporApp());
}

class PolLaporApp extends StatelessWidget {
  const PolLaporApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Solusi Error: List providers tidak boleh kosong
        // Provider placeholder ini bisa diganti nanti dengan AuthProvider atau LaporanProvider
        Provider<String>.value(value: "PolLapor Initialized"),

        // Contoh penambahan provider di masa mendatang:
        // ChangeNotifierProvider(create: (_) => LaporanProvider()),
      ],
      child: MaterialApp(
        title: 'PolLapor - Sistem Pelaporan Kerusakan Polban',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Menggunakan skema warna yang sesuai dengan identitas profesional
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A5F)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        // Halaman awal aplikasi untuk input laporan
        home: const FormLaporanView(),
      ),
    );
  }
}
