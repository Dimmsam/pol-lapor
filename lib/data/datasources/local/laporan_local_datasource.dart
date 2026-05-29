import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/laporan_lokal.dart';

class LaporanLocalDatasource {
  Box<LaporanLokal> get _box =>
      Hive.box<LaporanLokal>(AppConstants.boxLaporan);

  Future<void> saveLaporan(LaporanLokal laporan) async {
    await _box.put(laporan.formulirId, laporan);
  }

  List<LaporanLokal> getAllLaporan() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<LaporanLokal> getUnsyncedLaporan() {
    return _box.values.where((l) => !l.isSynced).toList();
  }

  LaporanLokal? getLaporanById(String formulirId) {
    return _box.get(formulirId);
  }

  Future<void> updateLaporan(LaporanLokal laporan) async {
    await _box.put(laporan.formulirId, laporan);
  }

  Future<void> deleteLaporan(String formulirId) async {
    await _box.delete(formulirId);
  }

  Future<void> markSynced(String formulirId) async {
    final laporan = _box.get(formulirId);
    if (laporan == null) return;

    laporan.isSynced = true;
    laporan.updatedAt = DateTime.now();
    await laporan.save();
  }

  Future<void> markAsSynced(String formulirId, String fotoCloudUrl) async {
    final laporan = _box.get(formulirId);
    if (laporan == null) return;

    laporan.isSynced = true;
    laporan.fotoKerusakanUrl = fotoCloudUrl;
    laporan.updatedAt = DateTime.now();
    await laporan.save();
  }

  Future<void> updateStatus(String formulirId, String statusBaru) async {
    final laporan = _box.get(formulirId);
    if (laporan == null) return;

    laporan.status = statusBaru;
    laporan.updatedAt = DateTime.now();
    await laporan.save();
  }

  int countAll() => _box.length;

  int countUnsynced() => _box.values.where((l) => !l.isSynced).length;

  ValueListenable<Box<LaporanLokal>> listenable() => _box.listenable();

  List<LaporanLokal> getLaporanAktifByLokasi(String lokasi) {
    return _box.values.where((l) {
      final sameLokasi = l.lokasiPerbaikan.trim().toLowerCase() ==
          lokasi.trim().toLowerCase();
      final masihAktif = l.status != StatusLaporan.selesai;
      return sameLokasi && masihAktif;
    }).toList();
  }

  /// Sinkronkan laporan dari remote ke lokal (merge/update).
  Future<void> syncFromRemote(List<Map<String, dynamic>> remoteLaporan) async {
    for (final json in remoteLaporan) {
      try {
        final formulirId = json['formulir_id'] as String;
        final existing = _box.get(formulirId);

        // Parse lokasi dari nested object dengan fallback
        String lokasiNama = 'Lokasi tidak diketahui';
        if (json['lokasi'] != null) {
          if (json['lokasi'] is Map) {
            lokasiNama = json['lokasi']['nama_ruangan'] as String? ?? 
                         json['lokasi']['lokasi_id'] as String? ?? 
                         'Lokasi tidak diketahui';
          } else if (json['lokasi'] is String) {
            lokasiNama = json['lokasi'] as String;
          }
        }

        final laporan = LaporanLokal(
          formulirId: formulirId,
          pelaporId: json['pelapor_id'] as String,
          namaSarana: json['nama_sarana'] as String,
          keteranganKerusakan: json['keterangan_kerusakan'] as String,
          lokasiPerbaikan: lokasiNama,
          fotoKerusakanUrl: json['foto_kerusakan_url'] as String?,
          status: json['status'] as String,
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
          isSynced: true,
        );

        // Hanya update jika belum ada atau versi remote lebih baru
        if (existing == null ||
            laporan.updatedAt.isAfter(existing.updatedAt)) {
          await _box.put(formulirId, laporan);
        }
      } catch (e) {
        debugPrint('syncFromRemote error untuk item: $e');
      }
    }
  }
}
