class LaporanValidator {
  static String? validateNamaSarana(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama sarana tidak boleh kosong';
    if (text.length < 6) return 'Minimal 6 karakter';
    return null;
  }

  static String? validateDeskripsi(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Deskripsi harus diisi';
    if (text.length < 12) return 'Minimal 12 karakter';
    return null;
  }
}
