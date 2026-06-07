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

  static const Map<String, String> roleDisplayNames = {
    roleMahasiswa: 'Pelapor',
    roleTeknisiJurusan: 'Teknisi JTK',
    'teknisi_jurusan': 'Teknisi JTK', 
    roleAdminJurusan: 'Admin Jurusan',
    roleKajur: 'Ketua Jurusan',
    roleAdminUptPp: 'Admin UPT PP',
    roleKetuaUptPp: 'Ketua UPT PP',
    roleTeknisiUptPp: 'Teknisi UPT PP',
  };

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
  static const List<String> lokasiLantai1 = [
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
  ];

  static const List<String> lokasiLantai2 = [
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

  /// Bangun tracking steps secara dinamis.
  /// [showEskalasi] — true jika riwayat mengandung event eskalasi.
  static List<Map<String, dynamic>> buildTrackingSteps({
    required bool showEskalasi,
  }) {
    return [
      {'title': 'Laporan Dibuat', 'events': ['laporan_dibuat']},
      {'title': 'Ditinjau Admin', 'events': ['laporan_diterima_admin', 'laporan_ditolak']},
      {'title': 'Teknisi Ditugaskan', 'events': ['teknisi_ditugaskan']},
      {'title': 'Dalam Penanganan', 'events': ['penanganan_dimulai', 'teknisi_mulai_periksa']},
      if (showEskalasi) {'title': 'Diteruskan ke Pusat', 'events': ['eskalasi_dari_teknisi', 'eskalasi_disetujui', 'eskalasi_ditolak', 'kajur_approve_eskalasi', 'diteruskan_ke_pusat']},
      {'title': 'Selesai', 'events': ['penanganan_selesai', 'laporan_dikunci']},
    ];
  }
}

/// Nilai enum `jenis_event_enum` di tabel `tracking` Supabase.
///
/// Dikonfirmasi dari Supabase DB pada 29 Mei 2026.
/// Lihat: REFACTOR_NOTES.md §9 — B10 (resolved).
class JenisEvent {
  JenisEvent._();

  static const String laporanDibuat        = 'laporan_dibuat';
  static const String laporanDiterimaAdmin = 'laporan_diterima_admin';
  static const String laporanDitolak       = 'laporan_ditolak';
  static const String teknisiDitugaskan    = 'teknisi_ditugaskan';
  static const String teknisiMulaiPeriksa  = 'teknisi_mulai_periksa';
  static const String penangananDimulai    = 'penanganan_dimulai';
  static const String eskalasiDariTeknisi  = 'eskalasi_dari_teknisi';
  static const String eskalasiDitolak      = 'eskalasi_ditolak';
  static const String eskalasiDisetujui    = 'eskalasi_disetujui';
  static const String kajurApproveEskalasi = 'kajur_approve_eskalasi';
  static const String penangananSelesai    = 'penanganan_selesai';
  static const String diteruskanKePusat    = 'diteruskan_ke_pusat';

  /// Semua nilai valid — berguna untuk validasi.
  static const Set<String> values = {
    laporanDibuat,
    laporanDiterimaAdmin,
    laporanDitolak,
    teknisiDitugaskan,
    teknisiMulaiPeriksa,
    penangananDimulai,
    eskalasiDariTeknisi,
    eskalasiDitolak,
    eskalasiDisetujui,
    kajurApproveEskalasi,
    penangananSelesai,
    diteruskanKePusat,
  };
}
