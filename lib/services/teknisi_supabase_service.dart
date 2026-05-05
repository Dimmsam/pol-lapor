// Import package supabase
import 'package:supabase_flutter/supabase_flutter.dart';

// Import model Penanganan (Pastikan path folder ini sesuai dengan struktur foldermu)
import '/data/models/penanganan.dart'; 

class TeknisiSupabaseService {
  // Inisialisasi client Supabase
  final supabase = Supabase.instance.client;
  
  Future<void> kirimPenangananBaru(Penanganan data) async {
    await supabase
        .from('penanganan')
        .insert(data.toJson()); 
  }

  Future<void> updateStatusPenanganan(Penanganan data) async {
    await supabase
        .from('penanganan')
        .update(data.toJson())
        .eq('penanganan_id', data.penangananId);
  }

  Future<void> prosesEskalasi({
    required Penanganan penangananLokal,
    required String idFormulir,
  }) async {
    // 1. Simpan/Update data penanganan (Sebagai bukti Teknisi Jurusan sudah mengecek)
    await supabase
        .from('penanganan')
        .update(penangananLokal.toJson())
        .eq('penanganan_id', penangananLokal.penangananId);

    // 2. Ubah status laporannya agar masuk ke antrean persetujuan Kajur
    await supabase
        .from('formulir_laporan')
        .update({
          'status': 'menunggu_persetujuan_kajur' // Sesuaikan dengan text ENUM di database kalian
        })
        .eq('formulir_id', idFormulir);
  }
}