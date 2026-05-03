import 'package:flutter/material.dart';
import '../../../data/datasources/remote/auth_remote_datasource.dart';
import '../../../data/datasources/local/auth_local_datasource.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // 1. Cek apakah Supabase masih punya session aktif (JWT belum expired)
    final remoteAuth = AuthRemoteDatasource();
    final supabaseSession = await remoteAuth.getSessionFromSupabase();

    if (supabaseSession != null) {
      // Session Supabase masih valid → update lokal dan lanjut ke home
      final localAuth = AuthLocalDatasource();
      await localAuth.saveSession(supabaseSession);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // 2. Tidak ada session Supabase → ke login
    await AuthLocalDatasource().clearSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xD90D47A1), Color(0xB3FF8F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', width: 100, height: 100),
              const SizedBox(height: 20),
              const Text(
                'PolLapor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sistem Pelaporan Fasilitas Kampus',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
