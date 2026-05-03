import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/models/laporan_lokal.dart'; // Sesuaikan path
import 'hive_service.dart'; // Sesuaikan path

class SyncService {
  final HiveService _hiveService = HiveService();

  static const List<String> _allowedLokasiPerbaikan = [
    'Gedung A',
    'Gedung B',
    'Gedung C',
    'Gedung D',
    'Gedung E',
    'Gedung F',
    'Gedung G',
    'Gedung H',
    'Gedung Lab Teknik Refrigerasi dan Tata Udara',
    'Gedung Lab Teknik Mesin',
    'Gedung Lab Teknik Kimia',
    'Gedung Lab Teknik Sipil',
    'Hanggar Aero',
    'Student Center',
    'Gedung Serba Guna AN',
    'Gedung Direktorat',
    'Pendopo Tony Soewandito',
    'Gedung P2T',
  ];

  // Ambil instance Supabase yang sudah diinisialisasi di main.dart
  final supabase = Supabase.instance.client;

  // 1. FUNGSI UTAMA: Pemicu Sinkronisasi
  Future<void> syncUnsyncedData() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      debugPrint('Sync dibatalkan: user belum login di Supabase Auth.');
      return;
    }

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
        if (laporan.fotoLokalPath != null &&
            laporan.fotoLokalPath!.isNotEmpty) {
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
      } on StorageException catch (e) {
        debugPrint(
          'Gagal upload storage laporan ${laporan.formulirId}: ${e.message} '
          '(status: ${e.statusCode}, error: ${e.error}).',
        );
        debugPrint(
          'Pastikan policy INSERT/UPDATE storage.objects untuk bucket '
          'bukti_laporan sudah dibuat.',
        );
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
    // Pastikan kita punya pelapor_id (user_id dari tabel pengguna)
    String pelaporId = laporan.pelaporId;
    if (pelaporId.isEmpty) {
      pelaporId = await _getMyUserId();
    }

    final statusCloud = _mapStatusForSupabase(laporan.status);

    await supabase.from('formulir_laporan').upsert({
      'formulir_id': laporan.formulirId, // Sesuai kolom primary key di Supabase
      'pelapor_id': pelaporId,
      'nama_sarana': laporan.namaSarana,
      'keterangan_kerusakan': laporan.keteranganKerusakan,
      'lokasi_perbaikan': _mapLokasiPerbaikanForSupabase(
        laporan.lokasiPerbaikan,
      ),
      'nomor_inventaris': laporan.nomorInventaris,
      'foto_kerusakan_url':
          imageUrl ?? laporan.fotoKerusakanUrl, // Masukkan URL publik
      'status': statusCloud,
      'tanda_tangan_pelapor': laporan.tandaTanganPelapor,
      'tanggal_tanda_tangan_pelapor': laporan.createdAt.toIso8601String(),
      'is_synced': true, // Di cloud pasti true
      'created_at': laporan.createdAt.toIso8601String(),
      'updated_at': laporan.updatedAt.toIso8601String(),
    });
  }

  String _mapStatusForSupabase(String statusLokal) {
    const valid = <String>{
      'draft',
      'terkirim',
      'dicatat_admin',
      'diketahui_ka_upt',
      'surat_pengajuan_dibuat',
      'surat_kerja_diterbitkan',
      'sedang_ditangani',
      'selesai_ditangani',
      'berita_acara_dibuat',
      'selesai',
    };

    if (valid.contains(statusLokal)) return statusLokal;

    // Mapping status lama aplikasi ke enum status_formulir di Supabase.
    switch (statusLokal) {
      case 'menunggu_klasifikasi':
        return 'draft';
      case 'klasifikasi_selesai':
      case 'pengajuan_dibuat':
      case 'menunggu_persetujuan_kajur':
      case 'diajukan_ke_upt':
      case 'menunggu_disposisi_upt':
        return 'terkirim';
      case 'sedang_ditangani':
        return 'sedang_ditangani';
      case 'selesai':
        return 'selesai';
      default:
        return 'draft';
    }
  }

  String? _mapLokasiPerbaikanForSupabase(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final lokasi in _allowedLokasiPerbaikan) {
      if (normalized == lokasi.toLowerCase()) return lokasi;
    }

    final sortedAllowedLokasiPerbaikan = [..._allowedLokasiPerbaikan]
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final lokasi in sortedAllowedLokasiPerbaikan) {
      if (normalized.contains(lokasi.toLowerCase())) return lokasi;
    }

    debugPrint(
      'Lokasi perbaikan "$input" tidak cocok dengan enum gedung. Nilai akan dikirim sebagai NULL.',
    );
    return null;
  }

  // Helper: ambil user_id (pelapor_id) dari tabel pengguna berdasarkan auth uid
  Future<String> _getMyUserId() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) throw Exception('User tidak terautentikasi');

    final resp = await supabase
        .from('pengguna')
        .select('user_id')
        .eq('auth_id', authUser.id)
        .single();

    if (resp['user_id'] == null) {
      throw Exception('Profil pengguna tidak ditemukan di tabel pengguna');
    }

    return resp['user_id'] as String;
  }
}
