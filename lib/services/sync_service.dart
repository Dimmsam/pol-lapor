import 'dart:io';
import 'package:flutter/foundation.dart';
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
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('Tidak ada internet. Sync ditunda.');
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
        if (laporan.fotoLokalPath != null && laporan.fotoLokalPath!.isNotEmpty) {
          cloudImageUrl = await _uploadFotoToSupabase(
            laporan.fotoLokalPath!,
            laporan.formulirId,
          );
        }

        // Step B: Simpan data teks & URL foto ke tabel 'formulir_laporan'
        await _upsertDataToSupabase(laporan, cloudImageUrl);

        // Step C: Jika sukses tanpa error, tandai laporan lokal sebagai synced
        await _hiveService.markSynced(laporan.formulirId);
        debugPrint('Laporan ${laporan.formulirId} berhasil di-sync.');
      } catch (e) {
        debugPrint('Gagal sync laporan ${laporan.formulirId}: $e');
        // Error di satu laporan tidak akan menghentikan loop laporan lainnya
      }
    }
  }

  // 2. FUNGSI BANTUAN: Upload Foto ke Supabase Storage
  Future<String?> _uploadFotoToSupabase(
    String filePath,
    String formulirId,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final fileExt = filePath.split('.').last;
    final fileName = 'formulir_$formulirId.$fileExt';

    // Asumsi nama bucket di Supabase kamu adalah 'bukti_laporan'
    final pathTujuan = 'foto_kerusakan/$fileName';

    // Upload file (upsert: true untuk menimpa jika kebetulan file sudah ada)
    await supabase.storage
        .from('bukti_laporan')
        .upload(pathTujuan, file, fileOptions: const FileOptions(upsert: true));

    // Ambil URL publik dari foto yang baru diupload
    final publicUrl = supabase.storage
        .from('bukti_laporan')
        .getPublicUrl(pathTujuan);
    return publicUrl;
  }

  // 3. FUNGSI BANTUAN: Insert/Update Data ke Tabel PostgreSQL
  Future<void> _upsertDataToSupabase(
    LaporanLokal laporan,
    String? imageUrl,
  ) async {
    // Menggunakan .upsert() sangat penting untuk Prinsip Idempotensi!
    await supabase.from('formulir_laporan').upsert({
      'formulir_id': laporan.formulirId, // Sesuai kolom primary key di Supabase
      'pelapor_id': laporan.pelaporId,
      'nama_sarana': laporan.namaSarana,
      'keterangan_kerusakan': laporan.keteranganKerusakan,
      'lokasi_perbaikan': laporan.lokasiPerbaikan,
      'nomor_inventaris': laporan.nomorInventaris,
      'foto_kerusakan_url': imageUrl ?? laporan.fotoKerusakanUrl, // Masukkan URL publik
      'status': laporan.status, 
      'tanda_tangan_pelapor': laporan.tandaTanganPelapor,
      'tanggal_tanda_tangan_pelapor': laporan.createdAt.toIso8601String(),
      'is_synced': true, // Di cloud pasti true
      'created_at': laporan.createdAt.toIso8601String(),
      'updated_at': laporan.updatedAt.toIso8601String(),
    });
  }
}