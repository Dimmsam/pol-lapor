import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';

import '../../logic/providers/laporan_provider.dart';
import '../../logic/providers/penanganan_provider.dart';
import '../../presentation/screens/pelapor/detail_laporan_screen.dart';
import '../../presentation/screens/teknisi_jurusan/detail_laporan_teknisi_screen.dart';

class AppRouter {
  static void navigatePostLogin(BuildContext context, String? role, dynamic session) {
    if (role == AppConstants.roleTeknisiJurusan || role == 'teknisi') {
      Navigator.pushReplacementNamed(
        context,
        '/dashboard-teknisi-jurusan',
        arguments: session,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  static void navigateToDetailFromNotif(BuildContext context, String formulirId) {
    final session = context.read<LaporanProvider>().session;
    if (session == null) return;
    
    final role = session.role;
    
    // Jika teknisi
    if (role == 'teknisi_jurusan' || role == 'teknisi') {
      final penangananProvider = context.read<PenangananProvider>();
      try {
        final laporan = penangananProvider.daftarTugas.firstWhere(
          (l) => l.formulirId == formulirId,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLaporanTeknisiScreen(
              laporan: laporan,
              userSession: session,
            ),
          ),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan tidak ditemukan di daftar tugas Anda')),
        );
      }
    } 
    // Jika pelapor
    else {
      final laporanProvider = context.read<LaporanProvider>();
      final laporan = laporanProvider.getLaporanById(formulirId);
      
      if (laporan != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLaporanScreen(laporan: laporan),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan tidak ditemukan')),
        );
      }
    }
  }
}
