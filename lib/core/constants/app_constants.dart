class AppConstants {
  // Hive box names
  static const String boxLaporan = 'laporan_box';
  static const String boxUser = 'user_box';

  // Role pengguna
  static const String roleMahasiswa = 'pelapor';
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
}
