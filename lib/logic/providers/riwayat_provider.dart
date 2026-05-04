// lib/logic/providers/riwayat_provider.dart
// Nama Pembuat: Dimas Rizal Ramadhani
// Provider untuk halaman Riwayat Pekerjaan Teknisi UPT-PP
// Disesuaikan: status enum DB (mulai_dikerjakan, sedang_dikerjakan, selesai).

import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/teknisi_upt_remote_datasource.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/models/surat_kerja.dart';
import '../../data/models/penanganan.dart';

enum RiwayatLoadStatus { idle, loading, loaded, error }

class RiwayatProvider extends ChangeNotifier {
  final TeknisiUptRemoteDatasource _remote = TeknisiUptRemoteDatasource();
  final AuthLocalDatasource _localAuth = AuthLocalDatasource();

  // ── State ─────────────────────────────────────────────────────────────────
  RiwayatLoadStatus _status = RiwayatLoadStatus.idle;
  String? _errorMessage;
  List<SuratKerja> _riwayat = [];
  List<SuratKerja> _riwayatFiltered = [];
  String _searchQuery = '';

  /// Tab filter: 'semua' | 'selesai' | 'aktif'
  /// Catatan: riwayat hanya menampilkan pekerjaan yang sudah selesai dari
  /// server, tapi tab 'aktif' bisa dipakai untuk menyaring yang masih
  /// in-progress jika diperlukan di masa depan.
  String _activeTabFilter = 'semua';

  // ── Getters ───────────────────────────────────────────────────────────────
  RiwayatLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == RiwayatLoadStatus.loading;
  List<SuratKerja> get riwayat => _riwayatFiltered;
  String get activeTabFilter => _activeTabFilter;

  String get teknisiId => _localAuth.getSession()?.userId ?? '';

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadRiwayat() async {
    if (teknisiId.isEmpty) return;

    _status = RiwayatLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _riwayat = await _remote.getRiwayatPekerjaan(teknisiId);
      _applySearchAndFilter();
      _status = RiwayatLoadStatus.loaded;
    } catch (e) {
      _status = RiwayatLoadStatus.error;
      _errorMessage = 'Gagal memuat riwayat pekerjaan.';
      debugPrint('loadRiwayat error: $e');
    }

    notifyListeners();
  }

  // ── Filter & Search ───────────────────────────────────────────────────────

  void setTabFilter(String filter) {
    _activeTabFilter = filter;
    _applySearchAndFilter();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applySearchAndFilter();
    notifyListeners();
  }

  void _applySearchAndFilter() {
    var result = List<SuratKerja>.from(_riwayat);

    // Filter tab — riwayat hanya berisi status 'selesai' dari server,
    // tapi kita sediakan filter jika ada campuran data masa depan.
    switch (_activeTabFilter) {
      case 'selesai':
        result = result
            .where((sk) =>
                sk.penanganan?.statusPenanganan == StatusPenanganan.selesai)
            .toList();
        break;
      case 'aktif':
        result = result.where((sk) {
          final s = sk.penanganan?.statusPenanganan;
          return s == StatusPenanganan.mulaiDikerjakan ||
              s == StatusPenanganan.sedangDikerjakan;
        }).toList();
        break;
      default:
        // 'semua' — tampilkan semua
        break;
    }

    // Search
    if (_searchQuery.trim().isNotEmpty) {
      final lower = _searchQuery.toLowerCase();
      result = result.where((sk) {
        final nama = (sk.namaSarana ?? '').toLowerCase();
        final lokasi = (sk.lokasiPerbaikan ?? '').toLowerCase();
        final nomor = (sk.nomorSuratKerja ?? '').toLowerCase();
        return nama.contains(lower) ||
            lokasi.contains(lower) ||
            nomor.contains(lower);
      }).toList();
    }

    _riwayatFiltered = result;
  }
}