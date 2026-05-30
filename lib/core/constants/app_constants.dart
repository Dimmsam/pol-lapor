class AppConstants {
  // Hive box names
  static const String boxLaporan = 'laporan_box';
  static const String boxUser = 'user_box';

  // Role pengguna
  static const String roleMahasiswa = 'pelapor';
  static const String rolePelapor = 'pelapor'; // alias dari roleMahasiswa
  static const String roleTeknisiJurusan = 'teknisi';
  static const String roleAdminJurusan = 'admin_jurusan';
  static const String roleKajur = 'kajur';
  static const String roleAdminUptPp = 'admin_upt_pp';
  static const String roleKetuaUptPp = 'ketua_upt_pp';
  static const String roleTeknisiUptPp = 'teknisi_upt_pp';

  // Kategori kerusakan
  static const List<String> kategoriList = [
    'AC / Kipas',
    'Proyektor',
    'Listrik',
    'Jalan / Infrastruktur',
    'Mebel',
    'Lainnya',
  ];

  // Status laporan & penanganan
  static const List<String> lokasiPerbaikanOptions = [
    'D101 - Kelas',
    'D102 - Lab. MT',
    'D105 - Kelas',
    'D106 - Lab. SDB',
    'D107 - Lab. RPL',
    'D108 - Kelas',
    'D111 - Kelas',
    'D112 - Kelas',
    'D115 - Lab. PjBL-1',
    'D116 - Lab. PjBL-2',
    'D217 - Kelas',
    'D219 - Kelas',
    'D223 - Kelas',
    'D224 - Kelas',
  ];

  // Tingkat kerusakan
  static const String tingkatRingan = 'rusak_ringan';
  static const String tingkatBerat = 'rusak_berat';

  // Status progres untuk dropdown update laporan
  static const String statusDiproses = 'Diproses';
  static const String statusSelesai = 'Selesai';
  
  static const List<Map<String, String>> statusProgresOptions = [
    {'value': 'Diproses', 'label': 'Masih Dikerjakan'},
    {'value': 'Selesai', 'label': 'Selesai Diperbaiki'},
  ];
}

/// Nilai enum `jenis_event_enum` di tabel `tracking` Supabase.
///
/// Dikonfirmasi dari Supabase DB pada 29 Mei 2026.
/// Lihat: REFACTOR_NOTES.md §9 — B10 (resolved).
class JenisEvent {
  JenisEvent._();

  static const String laporanDibuat       = 'laporan_dibuat';
  static const String laporanDiterimaAdmin = 'laporan_diterima_admin';
  static const String teknisiDitugaskan   = 'teknisi_ditugaskan';
  static const String teknisiMulaiPeriksa = 'teknisi_mulai_periksa';
  static const String penangananDimulai   = 'penanganan_dimulai';
  static const String penangananSelesai   = 'penanganan_selesai';
  static const String diteruskanKePusat   = 'diteruskan_ke_pusat';

  /// Semua nilai valid — berguna untuk validasi.
  static const Set<String> values = {
    laporanDibuat,
    laporanDiterimaAdmin,
    teknisiDitugaskan,
    teknisiMulaiPeriksa,
    penangananDimulai,
    penangananSelesai,
    diteruskanKePusat,
  };
}
