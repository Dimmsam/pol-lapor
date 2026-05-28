import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';

class StorageRemoteDatasource {
  final _storage = SupabaseService.storage;

  static const String _bucketBuktiFoto = 'bukti_laporan';
  static const String _folderFoto = 'foto_kerusakan';

  /// Upload foto kerusakan ke Supabase Storage.
  Future<String?> uploadFotoKerusakan({
    required String filePath,
    required String formulirId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('StorageRemote: file tidak ada di path "$filePath"');
      return null;
    }

    try {
      final ext = filePath.split('.').last;
      final fileName = 'formulir_$formulirId.$ext';
      final storagePath = '$_folderFoto/$fileName';

      await _storage
          .from(_bucketBuktiFoto)
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _storage
          .from(_bucketBuktiFoto)
          .getPublicUrl(storagePath);

      debugPrint('StorageRemote: upload berhasil → $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint(
        'StorageRemote: gagal upload foto formulir $formulirId: '
        '${e.message} (status: ${e.statusCode})',
      );
      return null;
    } catch (e) {
      debugPrint('StorageRemote: unexpected error saat upload: $e');
      return null;
    }
  }
}
