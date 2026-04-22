class AppConstants {
  // Hive box names
  static const String boxLaporan = 'laporan_box';
  static const String boxUser    = 'user_box';

  // Kategori laporan
  static const List<String> kategoriList = [
    'AC / Kipas',
    'Proyektor',
    'Listrik',
    'Jalan / Infrastruktur',
    'Mebel',
    'Lainnya',
  ];

  // Status laporan
  static const String statusMenunggu   = 'menunggu_disposisi';
  static const String statusDisposisi  = 'disposisi_bmn';
  static const String statusDiperiksa  = 'pemeriksaan_bmn';
  static const String statusDitugaskan = 'tugaskan_upt';
  static const String statusDitangani  = 'sedang_ditangani';
  static const String statusSelesai    = 'selesai_perbaikan';
  static const String statusTarik      = 'rekomen_tarik';
}