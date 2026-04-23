import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // Nanti gunakan ini untuk kamera

class FormLaporanScreen extends StatefulWidget {
  const FormLaporanScreen({super.key});

  @override
  State<FormLaporanScreen> createState() => _FormLaporanScreenState();
}

class _FormLaporanScreenState extends State<FormLaporanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk menangkap input
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _nomorInventarisController =
      TextEditingController(); // Sesuai aturan Polban

  String? _selectedKategori;
  final List<String> _kategoriList = [
    'AC/Kipas',
    'Proyektor',
    'Listrik',
    'Jalan',
    'Lainnya',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Kerusakan'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Input Judul
              const Text(
                "Judul Laporan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  hintText: "Contoh: AC Mati di Ruang 201",
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // 2. Dropdown Kategori
              const Text(
                "Kategori Fasilitas",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                items: _kategoriList
                    .map(
                      (kat) => DropdownMenuItem(value: kat, child: Text(kat)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedKategori = val),
                decoration: const InputDecoration(hintText: "Pilih Kategori"),
                validator: (value) => value == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),

              // 3. Nomor Inventaris (Sesuai Standar Pelayanan Polban)
              const Text(
                "Nomor Inventaris (Jika ada)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _nomorInventarisController,
                decoration: const InputDecoration(
                  hintText: "Lihat stiker pada barang",
                ),
              ),
              const SizedBox(height: 16),

              // 4. Lokasi
              const Text(
                "Lokasi Gedung/Area",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  hintText: "Contoh: Gedung J Lantai 2",
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Lokasi harus diisi' : null,
              ),
              const SizedBox(height: 16),

              // 5. Deskripsi
              const Text(
                "Deskripsi Kerusakan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Jelaskan detail kerusakan...",
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Deskripsi harus diisi' : null,
              ),
              const SizedBox(height: 20),

              // 6. Preview Foto
              const Text(
                "Foto Bukti Kerusakan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                    Text(
                      "Ambil Foto dari Kamera",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 7. Tombol Kirim (Simpan Lokal ke Hive)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // LOGIK: Simpan ke Hive dengan flag isSynced = false
                      _simpanKeLokal();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                  ),
                  child: const Text(
                    "Kirim Laporan",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simpanKeLokal() {
    // Di sini nanti panggil SyncController / Hive Service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laporan disimpan secara offline (Hive)')),
    );
  }
}
