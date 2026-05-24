import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/laporan_lokal.dart';
import '../../data/models/penanganan.dart';
import '../../core/supabase/supabase_service.dart';

class TeknisiJurusanProvider extends ChangeNotifier {
  // ─── Supabase Client ─────────────────────────────────────────────────────
  SupabaseClient get _db => SupabaseService.db;

  // ─── State ───────────────────────────────────────────────────────────────
  List<Penanganan> _daftarPenangananLokal = [];
  List<LaporanLokal> _laporanTerbaru = [];
  List<LaporanLokal> _daftarTugas = [];

  /// Map formulirId → Penanganan untuk lookup O(1)
  final Map<String, Penanganan> _mapPenanganan = {};

  Map<String, int> _stats = {
    'belum_dimulai': 0,
    'aktif': 0,
    'selesai': 0,
    'total': 0,
  };

  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ─────────────────────────────────────────────────────────────
  List<Penanganan> get daftarPenangananLokal => _daftarPenangananLokal;
  List<LaporanLokal> get laporanTerbaru => _laporanTerbaru;
  List<LaporanLokal> get daftarTugas => _daftarTugas;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Ambil Penanganan berdasarkan formulirId — O(1) lookup
  Penanganan? getPenangananByFormulir(String formulirId) =>
      _mapPenanganan[formulirId];

  // =========================================================================
  // DASHBOARD — LOAD DATA
  // =========================================================================

  /// Memuat semua data yang dibutuhkan halaman dashboard:
  /// statistik tugas + 5 laporan terbaru yang di-assign ke teknisi ini.
  Future<void> loadDashboard({required String teknisiId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await Future.wait([
        _fetchStats(teknisiId),
        _fetchLaporanTerbaru(teknisiId),
      ]);
    } catch (e) {
      _errorMessage = 'Gagal memuat data. Periksa koneksi internet.';
      debugPrint('loadDashboard error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Ambil statistik ringkasan tugas dari tabel `penanganan`.
  Future<void> _fetchStats(String teknisiId) async {
    try {
      final response = await _db
          .from('penanganan')
          .select('penanganan_id, status_penanganan')
          .eq('teknisi_id', teknisiId);

      int belumDimulai = 0;
      int aktif = 0;
      int selesai = 0;

      for (final row in (response as List)) {
        final status = row['status_penanganan'] as String?;
        if (status == null || status == StatusPenanganan.mulaiDikerjakan) {
          belumDimulai++;
        } else if (status == StatusPenanganan.selesai) {
          selesai++;
        } else {
          aktif++;
        }
      }

      _stats = {
        'belum_dimulai': belumDimulai,
        'aktif': aktif,
        'selesai': selesai,
        'total': response.length,
      };
    } catch (e) {
      debugPrint('_fetchStats error: $e');
      rethrow;
    }
  }

  /// Ambil 5 laporan terbaru yang di-assign ke teknisi ini.
  Future<void> _fetchLaporanTerbaru(String teknisiId) async {
    try {
      final response = await _db
          .from('formulir_laporan')
          .select('''
            formulir_id,
            nama_sarana,
            keterangan_kerusakan,
            lokasi_id,
            nomor_inventaris,
            foto_kerusakan_url,
            status,
            pelapor_id,
            created_at,
            updated_at,
            penanganan!inner (
              teknisi_id
            )
          ''')
          .eq('penanganan.teknisi_id', teknisiId)
          .order('created_at', ascending: false)
          .limit(5);

      _laporanTerbaru = _parseLaporanList(response as List);
    } catch (e) {
      debugPrint('_fetchLaporanTerbaru error: $e');
      rethrow;
    }
  }

  // =========================================================================
  // DAFTAR TUGAS — LOAD DATA
  // =========================================================================

  /// Memuat semua tugas + penanganan untuk halaman Daftar Tugas.
  /// Sekaligus membangun _mapPenanganan untuk lookup cepat per formulirId.
  Future<void> loadDaftarTugas({required String teknisiId}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await Future.wait([
        _fetchDaftarTugas(teknisiId),
        _fetchSemuaPenanganan(teknisiId),
      ]);
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar tugas. Periksa koneksi internet.';
      debugPrint('loadDaftarTugas error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Ambil semua laporan yang di-assign ke teknisi ini (tanpa limit).
  Future<void> _fetchDaftarTugas(String teknisiId) async {
    try {
      final response = await _db
          .from('formulir_laporan')
          .select('''
            formulir_id,
            nama_sarana,
            keterangan_kerusakan,
            lokasi_id,
            nomor_inventaris,
            foto_kerusakan_url,
            status,
            pelapor_id,
            created_at,
            updated_at,
            penanganan!inner (
              teknisi_id
            )
          ''')
          .eq('penanganan.teknisi_id', teknisiId)
          .order('created_at', ascending: false);

      _daftarTugas = _parseLaporanList(response as List);
    } catch (e) {
      debugPrint('_fetchDaftarTugas error: $e');
      rethrow;
    }
  }

  /// Ambil semua penanganan milik teknisi dan build map formulirId → Penanganan.
  Future<void> _fetchSemuaPenanganan(String teknisiId) async {
    try {
      final response = await _db
          .from('penanganan')
          .select('''
            penanganan_id,
            formulir_id,
            teknisi_id,
            status_penanganan,
            catatan_progres,
            deskripsi_hasil,
            foto_progres_url,
            foto_hasil_url,
            tanggal_mulai,
            tanggal_selesai,
            updated_at
          ''')
          .eq('teknisi_id', teknisiId);

      _mapPenanganan.clear();
      _daftarPenangananLokal = (response as List).map((json) {
        final p = Penanganan.fromJson(json as Map<String, dynamic>);
        _mapPenanganan[p.formulirId] = p; // Build lookup map
        return p;
      }).toList();
    } catch (e) {
      debugPrint('_fetchSemuaPenanganan error: $e');
      rethrow;
    }
  }

  // =========================================================================
  // PENANGANAN — MULAI PEKERJAAN
  // =========================================================================

  /// Teknisi memulai penanganan laporan langsung (tanpa surat kerja).
  Future<void> mulaiPenangananLangsung({
    required String formulirId,
    required String teknisiId,
  }) async {
    _setLoading(true);

    try {
      final penangananBaru = Penanganan(
        penangananId: const Uuid().v4(),
        formulirId: formulirId,
        teknisiId: teknisiId,
        statusPenanganan: StatusPenanganan.sedangDikerjakan,
        tanggalMulai: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update state lokal + map
      _daftarPenangananLokal.add(penangananBaru);
      _mapPenanganan[formulirId] = penangananBaru;
      notifyListeners();

      // Kirim ke Supabase
      await _db.from('penanganan').insert({
        'penanganan_id': penangananBaru.penangananId,
        'formulir_id': penangananBaru.formulirId,
        'teknisi_id': penangananBaru.teknisiId,
        'status_penanganan': penangananBaru.statusPenanganan,
        'tanggal_mulai': penangananBaru.tanggalMulai?.toIso8601String(),
        'foto_progres_url': <String>[],
        'updated_at': penangananBaru.updatedAt.toIso8601String(),
      });

      // Update status formulir_laporan ke 'diproses'
      await _db
          .from('formulir_laporan')
          .update({
            'status': StatusLaporan.diproses,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('formulir_id', formulirId);
    } catch (e) {
      _errorMessage = 'Gagal memulai penanganan: $e';
      debugPrint('mulaiPenangananLangsung error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================================
  // PENANGANAN — SELESAIKAN PEKERJAAN
  // =========================================================================

  /// Teknisi menyelesaikan penanganan (perbaiki sendiri).
  Future<void> selesaikanPenanganan({
    required String penangananId,
    required String formulirId,
    required String deskripsiHasil,
    String? fotoHasilUrl,
  }) async {
    _setLoading(true);

    try {
      final now = DateTime.now();

      // Update state lokal + map
      final index = _daftarPenangananLokal
          .indexWhere((p) => p.penangananId == penangananId);
      if (index != -1) {
        final updated = _daftarPenangananLokal[index].copyWith(
          statusPenanganan: StatusPenanganan.selesai,
          deskripsiHasil: deskripsiHasil,
          fotoHasilUrl: fotoHasilUrl,
          tanggalSelesai: now,
        );
        _daftarPenangananLokal[index] = updated;
        _mapPenanganan[formulirId] = updated;
        notifyListeners();
      }

      final nowStr = now.toIso8601String();

      await _db.from('penanganan').update({
        'status_penanganan': StatusPenanganan.selesai,
        'deskripsi_hasil': deskripsiHasil,
        if (fotoHasilUrl != null) 'foto_hasil_url': fotoHasilUrl,
        'tanggal_selesai': nowStr,
        'updated_at': nowStr,
      }).eq('penanganan_id', penangananId);

      await _db
          .from('formulir_laporan')
          .update({'status': StatusLaporan.selesai, 'updated_at': nowStr})
          .eq('formulir_id', formulirId);

      final teknisiId = await _getTeknisiIdByPenanganan(penangananId);
      if (teknisiId != null) {
        await _setTeknisiBusyState(teknisiId: teknisiId, isBusy: false);
      }
    } catch (e) {
      _errorMessage = 'Gagal menyelesaikan penanganan: $e';
      debugPrint('selesaikanPenanganan error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================================
  // PENANGANAN — ESKALASI KE ADMIN JURUSAN
  // =========================================================================

  /// Teknisi mengajukan eskalasi karena kerusakan berat.
  Future<void> eskalasiKeAdminJurusan({
    required String penangananId,
    required String formulirId,
    required String catatanEskalasi,
    required String kategoriKerusakan,
    List<String> fotoTambahan = const [],
  }) async {
    _setLoading(true);

    try {
      final now = DateTime.now();
      final nowStr = now.toIso8601String();

      await _db.from('penanganan').update({
        'status_penanganan': StatusPenanganan.menungguEskalasi,
        'catatan_progres': 'ESKALASI: $catatanEskalasi',
        'tanggal_selesai': nowStr,
        'updated_at': nowStr,
        if (fotoTambahan.isNotEmpty) 'foto_progres_url': fotoTambahan,
      }).eq('penanganan_id', penangananId);

      await _db.from('formulir_laporan').update({
        'status': StatusLaporan.menungguKlasifikasi,
        'updated_at': nowStr,
      }).eq('formulir_id', formulirId);

      await _insertTrackingLog(
        formulirId: formulirId,
        statusSebelumnya: StatusLaporan.diproses,
        statusBaru: StatusLaporan.menungguKlasifikasi,
        keterangan:
            'Teknisi Jurusan mengajukan eskalasi. '
            'Kategori: $kategoriKerusakan. Catatan: $catatanEskalasi',
      );

      final teknisiId = await _getTeknisiIdByPenanganan(penangananId);
      if (teknisiId != null) {
        await _setTeknisiBusyState(teknisiId: teknisiId, isBusy: false);
      }

      // Update state lokal + map
      final index = _daftarPenangananLokal
          .indexWhere((p) => p.penangananId == penangananId);
      if (index != -1) {
        final updated = _daftarPenangananLokal[index].copyWith(
          statusPenanganan: StatusPenanganan.menungguEskalasi,
          catatanProgres: 'ESKALASI: $catatanEskalasi',
          tanggalSelesai: now,
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

  // =========================================================================
  // HELPER PRIVAT
  // =========================================================================

  /// Parse list JSON dari Supabase menjadi List<LaporanLokal>
  List<LaporanLokal> _parseLaporanList(List raw) {
    return raw.map((json) {
      return LaporanLokal(
        formulirId: json['formulir_id'] as String,
        namaSarana: json['nama_sarana'] as String? ?? '-',
        keteranganKerusakan: json['keterangan_kerusakan'] as String? ?? '-',
        lokasiPerbaikan: json['lokasi_id'] as String? ?? '-',
        nomorInventaris: json['nomor_inventaris'] as String?,
        fotoKerusakanUrl: json['foto_kerusakan_url'] as String?,
        status:
            json['status'] as String? ?? StatusLaporan.menungguKlasifikasi,
        pelaporId: json['pelapor_id'] as String? ?? '',
        isSynced: true,
        createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
        ),
        updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );
    }).toList();
  }

  /// Set loading state dan notify listener
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Insert log ke tabel `tracking` untuk audit trail (non-critical)
  Future<void> _insertTrackingLog({
    required String formulirId,
    required String statusSebelumnya,
    required String statusBaru,
    required String keterangan,
  }) async {
    try {
      final user = SupabaseService.auth.currentUser;
      if (user == null) return;

      await _db.from('tracking').insert({
        'formulir_id': formulirId,
        'status_sebelumnya': statusSebelumnya,
        'status_baru': statusBaru,
        'keterangan': keterangan,
        'aktor_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('_insertTrackingLog error (non-critical): $e');
    }
  }

  /// Ambil teknisi_id dari penanganan, gunakan cache lokal jika ada.
  Future<String?> _getTeknisiIdByPenanganan(String penangananId) async {
    final localIndex = _daftarPenangananLokal
        .indexWhere((p) => p.penangananId == penangananId);
    if (localIndex != -1) {
      return _daftarPenangananLokal[localIndex].teknisiId;
    }

    try {
      final response = await _db
          .from('penanganan')
          .select('teknisi_id')
          .eq('penanganan_id', penangananId)
          .maybeSingle();
      if (response == null) return null;
      return response['teknisi_id'] as String?;
    } catch (e) {
      debugPrint('_getTeknisiIdByPenanganan error: $e');
      return null;
    }
  }

  Future<void> _setTeknisiBusyState({
    required String teknisiId,
    required bool isBusy,
  }) async {
    try {
      await _db.from('pengguna').update({'is_busy': isBusy}).eq('user_id', teknisiId);
    } catch (e) {
      debugPrint('_setTeknisiBusyState error: $e');
    }
  }

  /// Reset error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}