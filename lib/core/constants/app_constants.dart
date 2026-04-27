class AppConstants {
  // Hive box names
  static const String boxLaporan = 'laporan_box';
  static const String boxUser = 'user_box';

  // Role pengguna (sesuai entitas baru)
  static const String roleMahasiswa = 'pelapor';
  static const String roleTeknisiJurusan = 'teknisi_jurusan';
  static const String roleAdminJurusan = 'admin_jurusan';
  static const String roleKajur = 'kajur';
  static const String roleAdminUptPp = 'admin_upt_pp';
  static const String roleKetuaUptPp = 'ketua_upt_pp';
  static const String roleTeknisiUptPp = 'teknisi_upt_pp';

  // Kategori kerusakan
  static const List<String> kategoriList = [
    'AC_Kipas',
    'Proyektor',
    'Listrik',
    'Jalan_Infrastruktur',
    'Mebel',
    'Lainnya',
  ];

  // Status laporan (sesuai entitas Laporan baru — 8 status)
  static const String statusMenungguKlasifikasi = 'menunggu_klasifikasi';
  static const String statusKlasifikasiSelesai = 'klasifikasi_selesai';
  static const String statusPengajuanDibuat = 'pengajuan_dibuat';
  static const String statusMenungguKajur = 'menunggu_persetujuan_kajur';
  static const String statusDiajukanKeUpt = 'diajukan_ke_upt';
  static const String statusMenungguDisposisiUpt = 'menunggu_disposisi_upt';
  static const String statusSedangDitangani = 'sedang_ditangani';
  static const String statusSelesai = 'selesai';
  static const String statusMenunggu = statusMenungguKlasifikasi;
  static const String statusDisposisi = statusSedangDitangani;

  // Tingkat kerusakan
  static const String tingkatRingan = 'rusak_ringan';
  static const String tingkatBerat = 'rusak_berat';
}
