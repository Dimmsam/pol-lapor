import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../../data/datasources/remote/notifikasi_remote_datasource.dart';
import '../../data/models/notifikasi.dart';

class NotifikasiProvider extends ChangeNotifier {
  final NotifikasiRemoteDatasource _remote = NotifikasiRemoteDatasource();

  List<Notifikasi> _notifikasiList = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _realtimeSub;
  String? _currentUserId;

  // ── Getters ──────────────────────────────────────────────────────────────
  List<Notifikasi> get notifikasiList => _notifikasiList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount =>
      _notifikasiList.where((n) => !n.isRead).length;

  List<Notifikasi> get unreadList =>
      _notifikasiList.where((n) => !n.isRead).toList();

  // ── Init: panggil setelah user login ────────────────────────────────────
  Future<void> init(String userId) async {
    _currentUserId = userId;
    await fetchNotifikasi();
    _startRealtimeListener(userId);
  }

  // ── Fetch dari Supabase ──────────────────────────────────────────────────
  Future<void> fetchNotifikasi() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifikasiList = await _remote.fetchNotifikasiUser(_currentUserId!);
    } catch (e) {
      _errorMessage = 'Gagal memuat notifikasi: $e';
      debugPrint('NotifikasiProvider.fetchNotifikasi error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Tandai satu notifikasi sebagai dibaca ────────────────────────────────
  Future<void> markAsRead(String notifikasiId) async {
    final index = _notifikasiList.indexWhere(
      (n) => n.notifikasiId == notifikasiId,
    );
    if (index == -1) return;

    // Optimistic update
    _notifikasiList[index] = _notifikasiList[index].copyWith(isRead: true);
    notifyListeners();

    try {
      await _remote.markAsRead(notifikasiId);
    } catch (e) {
      // Rollback
      _notifikasiList[index] = _notifikasiList[index].copyWith(isRead: false);
      notifyListeners();
      debugPrint('NotifikasiProvider.markAsRead error: $e');
    }
  }

  // ── Tandai semua sebagai dibaca ──────────────────────────────────────────
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    // Optimistic update
    _notifikasiList = _notifikasiList
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await _remote.markAllAsRead(_currentUserId!);
    } catch (e) {
      // Re-fetch jika gagal
      await fetchNotifikasi();
      debugPrint('NotifikasiProvider.markAllAsRead error: $e');
    }
  }

  // ── Hapus notifikasi (swipe-to-delete) ───────────────────────────────────
  Future<void> deleteNotifikasi(String notifikasiId) async {
    final index = _notifikasiList.indexWhere(
      (n) => n.notifikasiId == notifikasiId,
    );
    if (index == -1) return;

    // Simpan data asli untuk rollback
    final notifToDelete = _notifikasiList[index];

    // Optimistic update
    _notifikasiList.removeAt(index);
    notifyListeners();

    try {
      await _remote.deleteNotifikasi(notifikasiId);
    } catch (e) {
      // Rollback
      _notifikasiList.insert(index, notifToDelete);
      notifyListeners();
      debugPrint('NotifikasiProvider.deleteNotifikasi error: $e');
    }
  }

  // ── Insert notifikasi dari sisi app (pelapor → notif teknisi dsb) ────────
  Future<void> kirimNotifikasi({
    required String penerimaId,
    required String judul,
    required String pesan,
    required String tipe,
    String? formulirId,
  }) async {
    try {
      await _remote.insertNotifikasi(
        penerimaId: penerimaId,
        judul:      judul,
        pesan:      pesan,
        tipe:       tipe,
        formulirId: formulirId,
      );
      // Jika penerima adalah user yang sedang login, update lokal
      if (penerimaId == _currentUserId) {
        await fetchNotifikasi();
      }
    } catch (e) {
      debugPrint('NotifikasiProvider.kirimNotifikasi error (non-critical): $e');
    }
  }

  // ── Realtime listener ────────────────────────────────────────────────────
  void _startRealtimeListener(String userId) {
    if (_realtimeSub != null) {
      SupabaseService.db.removeChannel(_realtimeSub!);
    }
    _realtimeSub = _remote.subscribeToUserNotifikasi(
      penerimaId: userId,
      onNew: (notif) {
        _notifikasiList.insert(0, notif);
        notifyListeners();
        debugPrint('Notifikasi baru: ${notif.judul}');
      },
    );
  }

  // ── Reset saat logout ────────────────────────────────────────────────────
  void reset() {
    try {
      if (_realtimeSub != null) {
        SupabaseService.db.removeChannel(_realtimeSub!);
      }
    } catch (e) {
      debugPrint('Error removing channel: $e');
    } finally {
      _realtimeSub = null;
      _notifikasiList = [];
      _currentUserId = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    try {
      if (_realtimeSub != null) {
        SupabaseService.db.removeChannel(_realtimeSub!);
      }
    } catch (e) {
      debugPrint('Error disposing channel: $e');
    } finally {
      _realtimeSub = null;
    }
    super.dispose();
  }
}
