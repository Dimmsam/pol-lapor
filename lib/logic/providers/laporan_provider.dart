import 'dart:io';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '/data/models/laporan_lokal.dart';

class LaporanController {
  static const String boxName = 'laporanBox';
  final _uuid = const Uuid();
  final _supabase = Supabase.instance.client;
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

  // ... (getAllLaporan tetap sama) ...

  // SESUAIKAN PARAMETER DENGAN MODEL BARU
  Future<void> tambahLaporan({
    required String namaSarana,
    required String keteranganKerusakan,
    required String lokasiPerbaikan,
    required String pelaporId,
    String? fotoLokalPath,
    String? nomorInventaris,
  }) async {
    final box = await Hive.openBox<LaporanLokal>(boxName);

    final baru = LaporanLokal(
      formulirId: _uuid.v4(), // Generate UUID
      namaSarana: namaSarana,
      keteranganKerusakan: keteranganKerusakan,
      lokasiPerbaikan: lokasiPerbaikan,
      nomorInventaris: nomorInventaris,
      fotoLokalPath: fotoLokalPath,
      pelaporId: pelaporId,
      isSynced: false,
    );

    // 1. Simpan ke Hive (Offline)
    await box.put(baru.formulirId, baru);

    // 2. Coba Sync ke Cloud
    await _syncSingleToCloud(baru, box);
  }

  // FUNGSI SINKRONISASI 1 LAPORAN
  Future<void> _syncSingleToCloud(
    LaporanLokal laporan,
    Box<LaporanLokal> box,
  ) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) return;

      String? imageUrl;

      // A. Upload Foto (Jika ada)
      if (laporan.fotoLokalPath != null && laporan.fotoLokalPath!.isNotEmpty) {
        final file = File(laporan.fotoLokalPath!);
        if (await file.exists()) {
          final fileExt = laporan.fotoLokalPath!.split('.').last;
          final fileName = 'formulir_${laporan.formulirId}.$fileExt';
          final pathTujuan = 'foto_kerusakan/$fileName';

          await _supabase.storage
              .from('bukti_laporan')
              .upload(
                pathTujuan,
                file,
                fileOptions: const FileOptions(upsert: true),
              );

          imageUrl = _supabase.storage
              .from('bukti_laporan')
              .getPublicUrl(pathTujuan);

          // Update URL di Hive agar kita punya link cloud-nya
          laporan.fotoKerusakanUrl = imageUrl;
        }
      }

      // B. Upsert Data ke Supabase (Sesuaikan dengan ERD baru)
      await _supabase.from('formulir_laporan').upsert({
        'formulir_id': laporan.formulirId,
        'nama_sarana': laporan.namaSarana,
        'keterangan_kerusakan': laporan.keteranganKerusakan,
        'lokasi_perbaikan': _mapLokasiPerbaikanForSupabase(
          laporan.lokasiPerbaikan,
        ),
        'nomor_inventaris': laporan.nomorInventaris,
        'foto_kerusakan_url': imageUrl ?? laporan.fotoKerusakanUrl,
        'status': laporan.status,
        'pelapor_id': laporan.pelaporId,
        'tanda_tangan_pelapor': laporan.tandaTanganPelapor,
        'tanggal_tanda_tangan_pelapor': laporan.createdAt
            .toIso8601String(), // Samakan dgn created_at
        'is_synced': true,
        'created_at': laporan.createdAt.toIso8601String(),
        'updated_at': laporan.updatedAt.toIso8601String(),
      });

      // C. Update status sinkronisasi di Hive
      laporan.isSynced = true;
      await laporan.save();
      print('✅ Sukses sync Formulir ${laporan.formulirId}');
    } catch (e) {
      print('❌ Gagal sync Formulir ${laporan.formulirId}: $e');
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

    return null;
  }
}
