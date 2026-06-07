// ============================================================
// File : mock_datasources.dart
// Deskripsi : Deklarasi mock classes untuk semua datasource
//             yang digunakan PenangananProvider.
//             Di-generate oleh build_runner via @GenerateMocks.
// ============================================================

import 'package:mockito/annotations.dart';
import 'package:pol_lapor/data/datasources/remote/penanganan_remote_datasource.dart';
import 'package:pol_lapor/data/datasources/remote/tracking_remote_datasource.dart';
import 'package:pol_lapor/data/datasources/remote/storage_remote_datasource.dart';
import 'package:pol_lapor/data/datasources/remote/notifikasi_remote_datasource.dart';

@GenerateMocks([
  PenangananRemoteDatasource,
  TrackingRemoteDatasource,
  StorageRemoteDatasource,
  NotifikasiRemoteDatasource,
])
void main() {}
