// lib/logic/providers/teknisi_upt_provider.dart
// Nama Pembuat: Dimas Rizal Ramadhani
// Provider untuk Dashboard & Daftar Tugas Teknisi UPT-PP
// Disesuaikan: status enum DB (mulai_dikerjakan, sedang_dikerjakan, selesai),
// dashboard stats key: belum_dimulai | aktif | selesai | total.

import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/teknisi_upt_remote_datasource.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/models/surat_kerja.dart';
import '../../data/models/penanganan.dart';

enum TeknisiLoadStatus { idle, loading, loaded, error }

class TeknisiUptProvider extends ChangeNotifier {
  final TeknisiUptRemoteDatasource _remote = TeknisiUptRemoteDatasource();
  final AuthLocalDatasource _localAuth = AuthLocalDatasource();

  // ── State ─────────────────────────────────────────────────────────────────
  TeknisiLoadStatus _status = TeknisiLoadStatus.idle;
  String? _errorMessage;

  List<SuratKerja> _allTugas = [];
  List<SuratKerja> _filteredTugas = [];

  /// Filter aktif: 'semua' | 'belum_dimulai' | 'aktif' | 'selesai'
  String _activeFilter = 'semua';

  Map<String, int> _dashboardStats = {
    'belum_dimulai': 0,
    'aktif': 0,
    'selesai': 0,
    'total': 0,
  };

  // ── Getters ───────────────────────────────────────────────────────────────
  TeknisiLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == TeknisiLoadStatus.loading;

  List<SuratKerja> get tugasList => _filteredTugas;
  String get activeFilter => _activeFilter;

  int get totalBelumDimulai => _dashboardStats['belum_dimulai'] ?? 0;
  int get totalAktif => _dashboardStats['aktif'] ?? 0;
  int get totalSelesai => _dashboardStats['selesai'] ?? 0;
  int get totalTugas => _dashboardStats['total'] ?? 0;

  /// Tugas aktif terbaru (untuk widget "Tugas Aktif" di dashboard)
  SuratKerja? get tugasAktifTerbaru {
    final aktif = _allTugas.where((sk) {
      final s = sk.penanganan?.statusPenanganan;
      return s == StatusPenanganan.mulaiDikerjakan ||
          s == StatusPenanganan.sedangDikerjakan;
    }).toList();
    return aktif.isNotEmpty ? aktif.first : null;
  }

  /// 3 tugas terbaru untuk section "Tugas Terbaru" di dashboard
  List<SuratKerja> get tugasTerbaru => _allTugas.take(3).toList();

  String get teknisiId => _localAuth.getSession()?.userId ?? '';

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Dipanggil saat TeknisiDashboardScreen pertama dibuka.
  Future<void> init() async {
    await Future.wait([
      loadDashboardStats(),
      loadTugasList(),
    ]);
  }

  // ── Load Data ─────────────────────────────────────────────────────────────

  Future<void> loadDashboardStats() async {
    if (teknisiId.isEmpty) return;
    try {
      _dashboardStats = await _remote.getDashboardStats(teknisiId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadDashboardStats error: $e');
    }
  }

  Future<void> loadTugasList({String? filter}) async {
    if (teknisiId.isEmpty) return;

    _status = TeknisiLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _allTugas = await _remote.getSuratKerjaList(teknisiId: teknisiId);
      _applyFilter(filter ?? _activeFilter);
      _status = TeknisiLoadStatus.loaded;
    } catch (e) {
      _status = TeknisiLoadStatus.error;
      _errorMessage = 'Gagal memuat daftar tugas. Periksa koneksi internet.';
      debugPrint('loadTugasList error: $e');
    }

    notifyListeners();
  }

  /// Refresh setelah update progress atau selesaikan pekerjaan.
  Future<void> refresh() async {
    await Future.wait([
      loadDashboardStats(),
      loadTugasList(),
    ]);
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  void setFilter(String filter) {
    _activeFilter = filter;
    _applyFilter(filter);
    notifyListeners();
  }

  void _applyFilter(String filter) {
    _activeFilter = filter;
    if (filter == 'semua') {
      _filteredTugas = List.from(_allTugas);
      return;
    }

    // Map label filter UI ke kondisi status_penanganan di DB
    switch (filter) {
      case 'belum_dimulai':
        // Belum ada record penanganan
        _filteredTugas =
            _allTugas.where((sk) => sk.penanganan == null).toList();
        break;
      case 'aktif':
        // mulai_dikerjakan atau sedang_dikerjakan
        _filteredTugas = _allTugas.where((sk) {
          final s = sk.penanganan?.statusPenanganan;
          return s == StatusPenanganan.mulaiDikerjakan ||
              s == StatusPenanganan.sedangDikerjakan;
        }).toList();
        break;
      case 'selesai':
        _filteredTugas = _allTugas
            .where((sk) =>
                sk.penanganan?.statusPenanganan == StatusPenanganan.selesai)
            .toList();
        break;
      default:
        _filteredTugas = List.from(_allTugas);
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void searchTugas(String query) {
    if (query.trim().isEmpty) {
      _applyFilter(_activeFilter);
      notifyListeners();
      return;
    }

    final lower = query.toLowerCase();
    _filteredTugas = _allTugas.where((sk) {
      final nama = (sk.namaSarana ?? '').toLowerCase();
      final lokasi = (sk.lokasiPerbaikan ?? '').toLowerCase();
      final nomor = (sk.nomorSuratKerja ?? '').toLowerCase();
      return nama.contains(lower) ||
          lokasi.contains(lower) ||
          nomor.contains(lower);
    }).toList();

    notifyListeners();
  }
}