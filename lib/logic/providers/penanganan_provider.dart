import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/supabase/supabase_service.dart';
import '../../data/datasources/remote/notifikasi_remote_datasource.dart';
import '../../data/datasources/remote/penanganan_remote_datasource.dart';
import '../../data/datasources/remote/tracking_remote_datasource.dart';
import '../../data/datasources/remote/storage_remote_datasource.dart';
import '../../data/models/laporan_lokal.dart';
import '../../data/models/notifikasi.dart';
import '../../data/models/penanganan.dart';

class PenangananProvider extends ChangeNotifier {
  final PenangananRemoteDatasource _remote = PenangananRemoteDatasource();
  final TrackingRemoteDatasource _trackingRemote = TrackingRemoteDatasource();
  final NotifikasiRemoteDatasource _notifRemote = NotifikasiRemoteDatasource();
  final StorageRemoteDatasource _storage = StorageRemoteDatasource();

  List<Penanganan> _daftarPenangananLokal = [];
  List<LaporanLokal> _daftarTugas = [];
  final Map<String, Penanganan> _mapPenanganan = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<Penanganan> get daftarPenangananLokal => _daftarPenangananLokal;
  List<LaporanLokal> get daftarTugas => _daftarTugas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Penanganan? getPenangananByFormulir(String formulirId) =>
      _mapPenanganan[formulirId];

  List<LaporanLokal> filterTugasByStatus(String filterType) {
    if (filterType == 'semua') return _daftarTugas;

    return _daftarTugas.where((laporan) {
      final penanganan = _mapPenanganan[laporan.formulirId];
      
      switch (filterType) {
        case 'menunggu':
          // Belum ada penanganan
          return penanganan == null;
          
        case 'dikerjakan':
          // Sudah ada penanganan & laporan masih diproses
          return penanganan != null && 
                 laporan.status == StatusLaporan.diproses && 
                 penanganan.statusPenanganan != StatusPenanganan.selesai;
                 
        case 'eskalasi':
          // Diteruskan ke pusat atau menunggu persetujuan kajur
          return laporan.status == StatusLaporan.diteruskanKePusat ||
                 laporan.status == StatusLaporan.menungguPersetujuanKajur;
                 
        case 'selesai':
          // Selesai di laporan atau di penanganan
          return laporan.status == StatusLaporan.selesai || 
                 (penanganan != null && penanganan.statusPenanganan == StatusPenanganan.selesai);
                 
        default:
          return true;
      }
    }).toList();
  }

  Future<void> loadDaftarTugas({required String teknisiId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final results = await Future.wait([
        _remote.fetchDaftarTugas(teknisiId),
        _remote.fetchPenangananRows(teknisiId),
      ]);
      _daftarTugas = results[0] as List<LaporanLokal>;
      _buildPenangananMap(results[1] as List<Map<String, dynamic>>);
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar tugas. Periksa koneksi internet.';
      debugPrint('loadDaftarTugas error: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _buildPenangananMap(List<Map<String, dynamic>> rows) {
    _mapPenanganan.clear();
    _daftarPenangananLokal = rows.map((json) {
      final p = Penanganan.fromJson(json);
      _mapPenanganan[p.formulirId] = p;
      return p;
    }).toList();
  }

  Future<void> fetchPenangananForFormulir(String formulirId) async {
    try {
      final data = await _remote.fetchPenangananByFormulir(formulirId);
      if (data != null) {
        final p = Penanganan.fromJson(data);
        _mapPenanganan[formulirId] = p;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal fetch penanganan by formulir: $e');
    }
  }

  Future<void> mulaiPenangananLangsung({
    required String formulirId,
    required String teknisiId,
  }) async {
    _setLoading(true);

    try {
      // Cek dulu apakah sudah ada penanganan untuk formulir ini
      final existing = _mapPenanganan[formulirId];
      if (existing != null) {
        debugPrint('Penanganan sudah ada untuk formulir $formulirId');
        _setLoading(false);
        return; // Skip jika sudah ada
      }

      final penangananBaru = Penanganan(
        penangananId: const Uuid().v4(),
        formulirId: formulirId,
        teknisiId: teknisiId,
        statusPenanganan: StatusPenanganan.mulaiDikerjakan,
        tanggalMulai: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _daftarPenangananLokal.add(penangananBaru);
      _mapPenanganan[formulirId] = penangananBaru;
      notifyListeners();

      await _remote.insertPenanganan({
        'penanganan_id': penangananBaru.penangananId,
        'formulir_id': penangananBaru.formulirId,
        'teknisi_id': penangananBaru.teknisiId,
        'status_penanganan': StatusPenanganan.mulaiDikerjakan, // satu-satunya nilai valid di DB selain 'selesai'
        'tanggal_mulai': penangananBaru.tanggalMulai?.toIso8601String(),
        'foto_progres_url': <String>[],
        'updated_at': penangananBaru.updatedAt.toIso8601String(),
      });

      await _remote.updateStatusFormulir(
        formulirId,
        StatusLaporan.diproses,
      );

      await _trackingRemote.catatTracking(
        formulirId: formulirId,
        aktorId: teknisiId,
        jenisEvent: JenisEvent.penangananDimulai,
        pesanNarasi: 'Teknisi Jurusan memulai penanganan. '
            'Status berubah dari Menunggu → Diproses.',
      );

      // Kirim notifikasi ke pelapor
      await _kirimNotifikasiPelapor(
        formulirId: formulirId,
        judul: 'Laporan sedang dikerjakan 🔧',
        pesan: 'Teknisi jurusan telah mulai menangani laporan kerusakanmu.',
        tipe: TipeNotifikasi.updateStatus,
      );
    } catch (e) {
      _errorMessage = 'Gagal memulai penanganan: $e';
      debugPrint('mulaiPenangananLangsung error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> eskalasiKeAdminJurusan({
    required String formulirId,
    required String teknisiId,
    required String catatanEskalasi,
    required String kategoriKerusakan,
    List<String> fotoTambahanPaths = const [],
  }) async {
    // Validasi input
    if (catatanEskalasi.trim().isEmpty) {
      _errorMessage = 'Catatan eskalasi tidak boleh kosong';
      notifyListeners();
      return;
    }
    
    if (kategoriKerusakan.trim().isEmpty) {
      _errorMessage = 'Kategori kerusakan harus dipilih';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      // Pastikan ada penanganan
      var penanganan = _mapPenanganan[formulirId];
      if (penanganan == null) {
        await mulaiPenangananLangsung(
          formulirId: formulirId,
          teknisiId: teknisiId,
        );
        penanganan = _mapPenanganan[formulirId];
        if (penanganan == null) {
           _errorMessage = 'Gagal membuat penanganan sebelum eskalasi';
           return;
        }
      }
      final penangananId = penanganan.penangananId;

      // Upload foto tambahan jika ada
      final List<String> fotoUrls = [];
      if (fotoTambahanPaths.isNotEmpty) {
        for (final path in fotoTambahanPaths) {
          final url = await _storage.uploadFotoProgres(
            filePath: path,
            formulirId: formulirId,
          );
          if (url != null) {
            fotoUrls.add(url);
          }
        }
      }

      final now = DateTime.now();
      final nowStr = now.toIso8601String();

      // status_penanganan DB hanya punya: mulai_dikerjakan | selesai
      // Saat eskalasi, status penanganan tetap mulai_dikerjakan (bukan nilai lain)
      // Status formulir yang berubah menjadi 'diteruskan_ke_pusat'
      await _remote.updatePenanganan(penangananId, {
        'status_penanganan':  StatusPenanganan.mulaiDikerjakan,
        'kategori_kerusakan': kategoriKerusakan,
        'catatan_progres':    catatanEskalasi,
        'tanggal_selesai':    nowStr,
        'updated_at':         nowStr,
        if (fotoUrls.isNotEmpty) 'foto_progres_url': fotoUrls,
      });

      // Langsung update ke status final yang benar (satu kali, tanpa update redundan)
      await _remote.updateStatusFormulir(
        formulirId,
        StatusLaporan.diteruskanKePusat,
        updatedAt: nowStr,
      );

      await _insertTrackingLog(
        formulirId: formulirId,
        statusBaru: StatusLaporan.diteruskanKePusat,
        jenisEvent: JenisEvent.eskalasiDariTeknisi,
        keterangan:
            'Teknisi Jurusan mengajukan eskalasi ke Admin. '
            'Kategori: $kategoriKerusakan. Catatan: $catatanEskalasi',
      );

      // Kirim notifikasi ke pelapor
      await _kirimNotifikasiPelapor(
        formulirId: formulirId,
        judul: 'Laporan diteruskan ke Admin',
        pesan: 'Laporan kerusakanmu perlu penanganan lebih lanjut '
               '(kategori: $kategoriKerusakan) dan sedang dikaji ulang.',
        tipe: TipeNotifikasi.eskalasi,
      );

      final index = _daftarPenangananLokal
          .indexWhere((p) => p.penangananId == penangananId);
      if (index != -1) {
        final updated = _daftarPenangananLokal[index].copyWith(
          statusPenanganan:  StatusPenanganan.mulaiDikerjakan,
          kategoriKerusakan: kategoriKerusakan,
          catatanProgres:    catatanEskalasi,
          tanggalSelesai:    now,
        );
        _daftarPenangananLokal[index] = updated;
        _mapPenanganan[formulirId] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Gagal mengajukan eskalasi: $e';
      debugPrint('eskalasiKeAdminJurusan error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProgresLaporan({
    required String formulirId,
    required String statusBaru,
    String? catatanProgres,
    String? fotoProgresPath,
  }) async {
    _setLoading(true);

    try {
      final nowStr = DateTime.now().toUtc().toIso8601String();
      final penanganan = _mapPenanganan[formulirId];
      if (penanganan == null) {
        throw Exception('Penanganan tidak ditemukan untuk formulir ini.');
      }

      String? fotoProgresUrl;
      if (fotoProgresPath != null && fotoProgresPath.isNotEmpty) {
        fotoProgresUrl = await _storage.uploadFotoProgres(
          filePath: fotoProgresPath,
          formulirId: formulirId,
        );
      }

      String finalStatusLaporan = StatusLaporan.diproses;
      // status_penanganan_enum DB hanya punya: mulai_dikerjakan | selesai
      String finalStatusPenanganan = StatusPenanganan.mulaiDikerjakan;

      if (statusBaru.toLowerCase() == 'selesai') {
        finalStatusLaporan = StatusLaporan.selesai;
        finalStatusPenanganan = StatusPenanganan.selesai;
      }

      final updateData = <String, dynamic>{
        'status_penanganan': finalStatusPenanganan,
        'updated_at': nowStr,
      };

      if (catatanProgres != null) {
        updateData['catatan_progres'] = catatanProgres;
        if (finalStatusPenanganan == StatusPenanganan.selesai) {
          updateData['deskripsi_hasil'] = catatanProgres;
        }
      }

      if (fotoProgresUrl != null) {
        if (finalStatusPenanganan == StatusPenanganan.selesai) {
          updateData['foto_hasil_url'] = fotoProgresUrl;
        } else {
          // Append ke array yang sudah ada, cek duplikasi
          final existing = penanganan.fotoProgresUrl;
          if (!existing.contains(fotoProgresUrl)) {
            updateData['foto_progres_url'] = [...existing, fotoProgresUrl];
          }
        }
      }

      if (finalStatusPenanganan == StatusPenanganan.selesai) {
        updateData['tanggal_selesai'] = nowStr;

        try {
          await SupabaseService.db
              .from('pengguna')
              .update({'is_busy': false})
              .eq('user_id', penanganan.teknisiId);
        } catch (e) {
          debugPrint('Gagal update is_busy: $e');
        }
      }

      await _remote.updatePenanganan(penanganan.penangananId, updateData);
      await _remote.updateStatusFormulir(
        formulirId,
        finalStatusLaporan,
        updatedAt: nowStr,
      );

      await _insertTrackingLog(
        formulirId: formulirId,
        statusBaru: finalStatusLaporan,
        jenisEvent: finalStatusLaporan == StatusLaporan.selesai
            ? JenisEvent.penangananSelesai
            : JenisEvent.teknisiMulaiPeriksa,
        keterangan:
            'Teknisi memperbarui progres: $statusBaru. ${catatanProgres ?? ""}',
      );

      // Kirim notifikasi ke pelapor
      final notifJudul = finalStatusLaporan == StatusLaporan.selesai
          ? 'Laporan selesai ditangani'
          : 'Ada update pada laporanmu';
      final notifPesan = finalStatusLaporan == StatusLaporan.selesai
          ? 'Laporan kerusakanmu telah selesai diperbaiki.'
          : 'Teknisi memperbarui progres: ${catatanProgres ?? statusBaru}';
      await _kirimNotifikasiPelapor(
        formulirId: formulirId,
        judul: notifJudul,
        pesan: notifPesan,
        tipe: finalStatusLaporan == StatusLaporan.selesai
            ? TipeNotifikasi.selesai
            : TipeNotifikasi.updateStatus,
      );

      final index = _daftarPenangananLokal
          .indexWhere((p) => p.penangananId == penanganan.penangananId);
      if (index != -1) {
        final updated = _daftarPenangananLokal[index].copyWith(
          statusPenanganan: finalStatusPenanganan,
          catatanProgres:
              catatanProgres ?? _daftarPenangananLokal[index].catatanProgres,
          fotoHasilUrl: finalStatusPenanganan == StatusPenanganan.selesai
              ? fotoProgresUrl
              : _daftarPenangananLokal[index].fotoHasilUrl,
          tanggalSelesai: finalStatusPenanganan == StatusPenanganan.selesai
              ? DateTime.now()
              : _daftarPenangananLokal[index].tanggalSelesai,
        );
        _daftarPenangananLokal[index] = updated;
        _mapPenanganan[formulirId] = updated;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui progres: $e';
      debugPrint('updateProgresLaporan error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _insertTrackingLog({
    required String formulirId,
    required String statusBaru,
    required String jenisEvent,
    required String keterangan,
  }) async {
    try {
      final user = SupabaseService.auth.currentUser;
      if (user == null) return;

      await _trackingRemote.catatTracking(
        formulirId: formulirId,
        aktorId: user.id,
        jenisEvent: jenisEvent,
        pesanNarasi: keterangan,
      );
    } catch (e) {
      debugPrint('_insertTrackingLog error (non-critical): $e');
    }
  }

  /// Lookup pelapor_id dari formulir lalu insert notifikasi ke tabel notifikasi.
  Future<void> _kirimNotifikasiPelapor({
    required String formulirId,
    required String judul,
    required String pesan,
    required String tipe,
  }) async {
    try {
      final row = await SupabaseService.db
          .from('formulir_laporan')
          .select('pelapor_id')
          .eq('formulir_id', formulirId)
          .maybeSingle();

      final pelaporId = row?['pelapor_id'] as String?;
      if (pelaporId == null) return;

      await _notifRemote.insertNotifikasi(
        penerimaId: pelaporId,
        judul:      judul,
        pesan:      pesan,
        tipe:       tipe,
        formulirId: formulirId,
      );
    } catch (e) {
      debugPrint('_kirimNotifikasiPelapor error (non-critical): $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
