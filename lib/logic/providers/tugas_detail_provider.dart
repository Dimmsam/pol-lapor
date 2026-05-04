// lib/logic/providers/tugas_detail_provider.dart
// Nama Pembuat: Dimas Rizal Ramadhani
// Provider untuk halaman Detail Tugas, Update Progress, dan Selesaikan Pekerjaan
// Disesuaikan: status enum DB (mulai_dikerjakan, sedang_dikerjakan, selesai),
// foto_progres_url sebagai List<String> (ARRAY), tanpa persentase_progress.

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/teknisi_upt_remote_datasource.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/models/surat_kerja.dart';
import '../../data/models/penanganan.dart';

enum TugasDetailStatus { idle, loading, submitting, success, error }

class TugasDetailProvider extends ChangeNotifier {
  final TeknisiUptRemoteDatasource _remote = TeknisiUptRemoteDatasource();
  final AuthLocalDatasource _localAuth = AuthLocalDatasource();
  final _uuid = const Uuid();

  // ── State ─────────────────────────────────────────────────────────────────
  TugasDetailStatus _status = TugasDetailStatus.idle;
  String? _errorMessage;
  String? _successMessage;

  SuratKerja? _suratKerja;
  Penanganan? _penanganan;

  /// Status yang dipilih untuk update progress
  /// Hanya bisa: mulai_dikerjakan | sedang_dikerjakan
  String _selectedStatus = StatusPenanganan.mulaiDikerjakan;

  /// Path file foto progres baru yang akan diupload
  String? _fotoProgresPath;

  /// Path file foto hasil (untuk selesaikan pekerjaan)
  String? _fotoHasilPath;

  // ── Getters ───────────────────────────────────────────────────────────────
  TugasDetailStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoading => _status == TugasDetailStatus.loading;
  bool get isSubmitting => _status == TugasDetailStatus.submitting;

  SuratKerja? get suratKerja => _suratKerja;
  Penanganan? get penanganan => _penanganan;

  String get selectedStatus => _selectedStatus;
  String? get fotoProgresPath => _fotoProgresPath;
  String? get fotoHasilPath => _fotoHasilPath;

  /// Daftar URL foto progress yang sudah diupload sebelumnya
  List<String> get existingFotoProgresUrls =>
      _penanganan?.fotoProgresUrl ?? [];

  String get teknisiId => _localAuth.getSession()?.userId ?? '';

  /// Apakah tugas sudah punya record penanganan (sudah dimulai)?
  bool get sudahDimulai => _penanganan != null;

  /// Apakah tugas sudah selesai?
  bool get sudahSelesai =>
      _penanganan?.statusPenanganan == StatusPenanganan.selesai;

  /// Status saat ini dari penanganan
  String get statusSaatIni =>
      _penanganan?.statusPenanganan ?? 'belum_dimulai';

  // ── Load Detail ───────────────────────────────────────────────────────────

  Future<void> loadDetail(String suratKerjaId) async {
    _status = TugasDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _suratKerja = await _remote.getSuratKerjaDetail(suratKerjaId);

      // Sync penanganan dari data yang sudah di-join
      if (_suratKerja!.penanganan != null) {
        final p = _suratKerja!.penanganan!;
        // Buat Penanganan lengkap dari PenangananRingkas (untuk update form)
        _penanganan = Penanganan(
          penangananId: p.penangananId,
          suratKerjaId: suratKerjaId,
          formulirId: _suratKerja!.formulirId,
          teknisiId: teknisiId,
          statusPenanganan: p.statusPenanganan,
          catatanProgres: p.catatanProgres,
          fotoProgresUrl: p.fotoProgresUrl,
          fotoHasilUrl: p.fotoHasilUrl,
          deskripsiHasil: p.deskripsiHasil,
          tanggalMulai: p.tanggalMulai,
          tanggalSelesai: p.tanggalSelesai,
          updatedAt: DateTime.now(),
        );
        // Inisialisasi form state dari data existing
        _selectedStatus = p.statusPenanganan;
      }

      _status = TugasDetailStatus.idle;
    } catch (e) {
      _status = TugasDetailStatus.error;
      _errorMessage = 'Gagal memuat detail tugas.';
      debugPrint('loadDetail error: $e');
    }

    notifyListeners();
  }

  // ── Mulai Pengerjaan ──────────────────────────────────────────────────────

  /// Dipanggil pertama kali saat teknisi tap "Lanjutkan" / "Terima Tugas".
  /// Membuat record penanganan baru di Supabase dengan status 'mulai_dikerjakan'.
  Future<bool> mulaiPengerjaan() async {
    if (_suratKerja == null || teknisiId.isEmpty) return false;
    if (sudahDimulai) return true; // Sudah dimulai sebelumnya

    _status = TugasDetailStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      _penanganan = await _remote.mulaiPengerjaan(
        suratKerjaId: _suratKerja!.suratKerjaId,
        formulirId: _suratKerja!.formulirId,
        teknisiId: teknisiId,
        penangananId: _uuid.v4(),
      );

      _selectedStatus = StatusPenanganan.mulaiDikerjakan;
      _status = TugasDetailStatus.success;
      _successMessage = 'Pengerjaan dimulai!';
    } catch (e) {
      _status = TugasDetailStatus.error;
      _errorMessage = 'Gagal memulai pengerjaan. Coba lagi.';
      debugPrint('mulaiPengerjaan error: $e');
    }

    notifyListeners();
    return _status == TugasDetailStatus.success;
  }

  // ── Update Progress ───────────────────────────────────────────────────────

  /// Set status progress. Hanya boleh: mulai_dikerjakan | sedang_dikerjakan.
  void setSelectedStatus(String status) {
    assert(
      status == StatusPenanganan.mulaiDikerjakan ||
          status == StatusPenanganan.sedangDikerjakan,
      'setSelectedStatus hanya menerima mulai_dikerjakan atau sedang_dikerjakan',
    );
    _selectedStatus = status;
    notifyListeners();
  }

  void setFotoProgres(String path) {
    _fotoProgresPath = path;
    notifyListeners();
  }

  Future<bool> simpanProgress({String? catatanProgres}) async {
    if (_penanganan == null) {
      _errorMessage = 'Mulai pengerjaan terlebih dahulu.';
      notifyListeners();
      return false;
    }

    _status = TugasDetailStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      _penanganan = await _remote.updateProgress(
        penangananId: _penanganan!.penangananId,
        formulirId: _suratKerja!.formulirId,
        statusBaru: _selectedStatus,
        catatanProgres: catatanProgres,
        fotoLokalPath: _fotoProgresPath,
        existingFotoUrls: _penanganan!.fotoProgresUrl, // append ke ARRAY existing
      );

      _fotoProgresPath = null; // Reset setelah upload
      _status = TugasDetailStatus.success;
      _successMessage = 'Progress berhasil disimpan!';
    } catch (e) {
      _status = TugasDetailStatus.error;
      _errorMessage = 'Gagal menyimpan progress. Periksa koneksi internet.';
      debugPrint('simpanProgress error: $e');
    }

    notifyListeners();
    return _status == TugasDetailStatus.success;
  }

  // ── Selesaikan Pekerjaan ─────────────────────────────────────────────────

  void setFotoHasil(String path) {
    _fotoHasilPath = path;
    notifyListeners();
  }

  Future<bool> selesaikanPekerjaan({required String deskripsiHasil}) async {
    if (_penanganan == null) {
      _errorMessage = 'Data penanganan tidak ditemukan.';
      notifyListeners();
      return false;
    }

    if (_fotoHasilPath == null || _fotoHasilPath!.isEmpty) {
      _errorMessage = 'Foto hasil perbaikan wajib diambil.';
      notifyListeners();
      return false;
    }

    if (deskripsiHasil.trim().length < 10) {
      _errorMessage = 'Catatan hasil minimal 10 karakter.';
      notifyListeners();
      return false;
    }

    _status = TugasDetailStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      _penanganan = await _remote.selesaikanPekerjaan(
        penangananId: _penanganan!.penangananId,
        formulirId: _suratKerja!.formulirId,
        fotoHasilPath: _fotoHasilPath!,
        deskripsiHasil: deskripsiHasil.trim(),
      );

      _selectedStatus = StatusPenanganan.selesai;
      _fotoHasilPath = null;
      _status = TugasDetailStatus.success;
      _successMessage = 'Pekerjaan berhasil diselesaikan!';
    } catch (e) {
      _status = TugasDetailStatus.error;
      _errorMessage = 'Gagal menyelesaikan pekerjaan. Coba lagi.';
      debugPrint('selesaikanPekerjaan error: $e');
    }

    notifyListeners();
    return _status == TugasDetailStatus.success;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void resetMessages() {
    _errorMessage = null;
    _successMessage = null;
    if (_status == TugasDetailStatus.success ||
        _status == TugasDetailStatus.error) {
      _status = TugasDetailStatus.idle;
    }
    notifyListeners();
  }

  void resetAll() {
    _status = TugasDetailStatus.idle;
    _errorMessage = null;
    _successMessage = null;
    _suratKerja = null;
    _penanganan = null;
    _selectedStatus = StatusPenanganan.mulaiDikerjakan;
    _fotoProgresPath = null;
    _fotoHasilPath = null;
    notifyListeners();
  }
}