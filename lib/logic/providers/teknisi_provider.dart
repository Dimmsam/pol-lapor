import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/models/tugas_teknisi_lokal.dart';

class TeknisiProvider extends ChangeNotifier {
  // Buka kotak (box) khusus tugas teknisi
  Box<TugasTeknisiLokal> get _box => Hive.box<TugasTeknisiLokal>('tugasTeknisiBox');

  // Ambil data tugas khusus untuk ditampilkan di layar (hanya yang masih dikerjakan)
  List<TugasTeknisiLokal> get daftarTugasAktif {
    return _box.values
        .where((tugas) => tugas.status == 'sedang_dikerjakan')
        .toList();
  }

  // ── AKSI 1: SELESAIKAN PEKERJAAN ──────────────────────────────────────────
  Future<void> selesaikanPekerjaan({
    required String penangananId,
    required String fotoPath, 
  }) async {
    final tugas = _box.get(penangananId);
    
    if (tugas != null) {
      tugas.status = 'selesai';
      tugas.fotoHasilLokalPath = fotoPath;
      tugas.isSynced = false; // TANDAI FALSE agar dicomot oleh Backend Service
      tugas.updatedAt = DateTime.now();

      await tugas.save(); // Simpan perubahan ke Hive (Offline)
      
      notifyListeners(); // Refresh UI (otomatis tugas hilang dari daftar layar)
    }
  }

  // ── AKSI 2: AJUKAN ESKALASI ───────────────────────────────────────────────
  Future<void> ajukanEskalasi({
    required String penangananId,
    required String alasanEskalasi, 
  }) async {
    final tugas = _box.get(penangananId);
    
    if (tugas != null) {
      tugas.status = 'menunggu_eskalasi_jurusan'; 
      tugas.catatanTeknisi = alasanEskalasi;
      tugas.isSynced = false; // TANDAI FALSE agar dicomot oleh Backend Service
      tugas.updatedAt = DateTime.now();

      await tugas.save(); // Simpan ke memori HP
      
      notifyListeners(); // Refresh UI
    }
  }
}