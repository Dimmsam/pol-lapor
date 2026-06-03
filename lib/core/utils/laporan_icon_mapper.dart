import 'package:flutter/material.dart';

class LaporanIconMapper {
  static IconData getIconForSarana(String namaSarana) {
    final nama = namaSarana.toLowerCase();
    if (nama.contains('ac') || nama.contains('kipas')) return Icons.air_outlined;
    if (nama.contains('lampu') || nama.contains('listrik')) return Icons.lightbulb_outline_rounded;
    if (nama.contains('meja') || nama.contains('kursi') || nama.contains('papan')) return Icons.desk_outlined;
    if (nama.contains('proyektor') || nama.contains('lcd')) return Icons.videocam_outlined;
    if (nama.contains('pintu') || nama.contains('jendela') || nama.contains('atap') || nama.contains('bocor')) return Icons.home_repair_service_outlined;
    if (nama.contains('komputer') || nama.contains('pc') || nama.contains('keyboard')) return Icons.computer_outlined;
    return Icons.build_circle_outlined;
  }

  static Map<String, String> getEmptyStateData(String statusFilter, bool isPublic) {
    if (statusFilter == 'Menunggu Klasifikasi') {
      return {'message': 'Tidak ada laporan menunggu', 'sub': 'Semua laporan sudah diproses'};
    } else if (statusFilter == 'Diproses') {
      return {'message': 'Tidak ada laporan diproses', 'sub': 'Belum ada laporan yang sedang diproses'};
    } else if (statusFilter == 'Selesai') {
      return {'message': 'Belum ada laporan selesai', 'sub': 'Laporan yang selesai akan muncul di sini'};
    }
    
    return {
      'message': isPublic ? 'Belum ada laporan publik' : 'Belum ada laporan',
      'sub': isPublic ? 'Laporan dari orang lain akan muncul di sini' : 'Laporan yang dibuat akan muncul di sini'
    };
  }
}
