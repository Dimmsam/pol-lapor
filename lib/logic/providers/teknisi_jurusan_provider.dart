import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '/data/models/penanganan.dart';
import '/services/teknisi_supabase_service.dart';
// import box hive kalian di sini

class TeknisiJurusanProvider extends ChangeNotifier {
  final TeknisiSupabaseService _apiService = TeknisiSupabaseService();
  
  List<Penanganan> _daftarPenangananLokal = [];
  List<Penanganan> get daftarPenangananLokal => _daftarPenangananLokal;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 1. MULAI PEKERJAAN (Penanganan Langsung Tanpa Surat Kerja)
  Future<void> mulaiPenangananLangsung({
    required String formulirId,
    required String teknisiId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Bikin objek Penanganan baru
      final penangananBaru = Penanganan(
        penangananId: const Uuid().v4(), // Generate UUID baru
        suratKerjaId: null, // KUNCI: Dibiarkan null karena ini Teknisi Jurusan
        formulirId: formulirId,
        teknisiId: teknisiId,
        statusPenanganan: StatusPenanganan.sedangDikerjakan,
        tanggalMulai: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // A. Simpan ke lokal dulu (Hive) biar UI langsung update (Offline-First)
      _daftarPenangananLokal.add(penangananBaru);
      // TODO: Simpan 'penangananBaru' ke Hive Box kalian di sini
      
      // B. Tembak ke Supabase Cloud (Background)
      await _apiService.kirimPenangananBaru(penangananBaru);

    } catch (e) {
      debugPrint('Gagal mulai penanganan: $e');
      // Kasih logic fallback jika gagal
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 2. SELESAIKAN PEKERJAAN (Bisa Diperbaiki Sendiri)
  Future<void> selesaikanPenanganan({
    required String penangananId,
    required String deskripsiHasil,
    required String fotoHasilUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cari data di list lokal
      final index = _daftarPenangananLokal.indexWhere((p) => p.penangananId == penangananId);
      if (index == -1) return;

      // Update datanya pakai copyWith
      final updatedData = _daftarPenangananLokal[index].copyWith(
        statusPenanganan: StatusPenanganan.selesai,
        deskripsiHasil: deskripsiHasil,
        fotoHasilUrl: fotoHasilUrl,
        tanggalSelesai: DateTime.now(),
      );

      // A. Update di lokal (Hive)
      _daftarPenangananLokal[index] = updatedData;
      // TODO: Update data di Hive Box kalian
      
      // B. Tembak ke Supabase Cloud
      await _apiService.updateStatusPenanganan(updatedData);

    } catch (e) {
      debugPrint('Gagal selesaikan penanganan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 3. ESKALASI KE UPT (Kerusakan Berat)
  Future<void> eskalasiKeKajur({
    required String penangananId,
    required String formulirId,
    required String catatanPengecekanAwal,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _daftarPenangananLokal.indexWhere((p) => p.penangananId == penangananId);
      if (index == -1) return;

      // 1. Tutup Penanganan Lokal (Tugas Teknisi Jurusan dianggap selesai sebatas 'mengecek')
      final updatedPenanganan = _daftarPenangananLokal[index].copyWith(
        statusPenanganan: StatusPenanganan.selesai, // Atau bisa buat status baru 'dieskalasi'
        catatanProgres: 'Diteruskan ke Kajur/UPT: $catatanPengecekanAwal',
        tanggalSelesai: DateTime.now(),
      );

      _daftarPenangananLokal[index] = updatedPenanganan;
      
      // 2. Tembak ke Supabase (Mengubah 2 Tabel Sekaligus)
      await _apiService.prosesEskalasi(
        penangananLokal: updatedPenanganan,
        idFormulir: formulirId,
      );

    } catch (e) {
      debugPrint('Gagal eskalasi penanganan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}