import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/models/laporan_lokal.dart'; // Sesuaikan path
import 'hive_service.dart'; // Sesuaikan path

class SyncService {
  final HiveService _hiveService = HiveService();
  
  // Ambil instance Supabase yang sudah diinisialisasi di main.dart
  final supabase = Supabase.instance.client;

  // 1. FUNGSI UTAMA: Pemicu Sinkronisasi
  Future<void> syncUnsyncedData() async {
    // Cek koneksi internet
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('Tidak ada internet. Sync ditunda.');
      return;
    }

    // Ambil data yang isSynced == false dari Hive
    final semuaLaporan = await _hiveService.getAllLaporan();
    final unsyncedLaporan = semuaLaporan.where((lap) => !lap.isSynced).toList();

    if (unsyncedLaporan.isEmpty) return;

    for (var laporan in unsyncedLaporan) {
      try {
        // Step A: Upload foto fisik ke Supabase Storage dulu (jika ada)
        String? cloudImageUrl;
        if (laporan.fotoPath != null && laporan.fotoPath!.isNotEmpty) {
          cloudImageUrl = await _uploadFotoToSupabase(
            laporan.fotoPath!, 
            laporan.laporanId,
          );
        }

        // Step B: Simpan data teks & URL foto ke tabel 'laporans'
        await _upsertDataToSupabase(laporan, cloudImageUrl);

        // Step C: Jika sukses tanpa error, tandai laporan lokal sebagai synced
        await _hiveService.markSynced(laporan.laporanId);
        print('✅ Laporan ${laporan.laporanId} berhasil di-sync.');

      } catch (e) {
        print('❌ Gagal sync laporan ${laporan.laporanId}: $e');
        // Error di satu laporan tidak akan menghentikan loop laporan lainnya
      }
    }
  }

  // 2. FUNGSI BANTUAN: Upload Foto ke Supabase Storage
  Future<String?> _uploadFotoToSupabase(String filePath, String laporanId) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final fileExt = filePath.split('.').last;
    final fileName = 'laporan_$laporanId.$fileExt';
    
    // Asumsi nama bucket di Supabase kamu adalah 'bukti_laporan'
    final pathTujuan = 'laporan_kerusakan/$fileName';

    // Upload file (upsert: true untuk menimpa jika kebetulan file sudah ada)
    await supabase.storage.from('bukti_laporan').upload(
      pathTujuan,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    // Ambil URL publik dari foto yang baru diupload
    final publicUrl = supabase.storage.from('bukti_laporan').getPublicUrl(pathTujuan);
    return publicUrl;
  }

  // 3. FUNGSI BANTUAN: Insert/Update Data ke Tabel PostgreSQL
  Future<void> _upsertDataToSupabase(LaporanLokal laporan, String? imageUrl) async {
    // Menggunakan .upsert() sangat penting untuk Prinsip Idempotensi!
    // Jika laporanId sudah ada di database, data akan di-update (bukan diduplikat).
    await supabase.from('laporans').upsert({
      'id': laporan.laporanId, // Sesuai kolom primary key di Supabase
      'pelapor_id': laporan.pelaporId,
      'judul': laporan.judul,
      'deskripsi': laporan.deskripsi,
      'kategori_kerusakan': laporan.kategori,
      'lokasi': laporan.lokasi,
      'tingkat_kerusakan': laporan.tingkatKerusakan,
      'nomor_inventaris': laporan.nomorInventaris,
      'foto_bukti': imageUrl, // Masukkan URL publik dari Storage
      'is_synced': true, // Di cloud pasti true
      'status': laporan.status, // Kirim status terkini (menunggu)
      'created_at': laporan.createdAt.toIso8601String(),
    });
  }
}