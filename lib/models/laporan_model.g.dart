// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laporan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LaporanLokalAdapter extends TypeAdapter<LaporanLokal> {
  @override
  final int typeId = 0;

  @override
  LaporanLokal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LaporanLokal(
      laporanId: fields[0] as String,
      judul: fields[1] as String,
      deskripsi: fields[2] as String,
      kategori: fields[3] as String,
      lokasi: fields[4] as String,
      nomorInventaris: fields[5] as String?,
      tingkatKerusakan: fields[6] as String,
      fotoPath: fields[7] as String?,
      fotoCloudUrl: fields[8] as String?,
      status: fields[9] as String,
      isSynced: fields[10] as bool,
      createdAt: fields[11] as DateTime?,
      pelaporId: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LaporanLokal obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.laporanId)
      ..writeByte(1)
      ..write(obj.judul)
      ..writeByte(2)
      ..write(obj.deskripsi)
      ..writeByte(3)
      ..write(obj.kategori)
      ..writeByte(4)
      ..write(obj.lokasi)
      ..writeByte(5)
      ..write(obj.nomorInventaris)
      ..writeByte(6)
      ..write(obj.tingkatKerusakan)
      ..writeByte(7)
      ..write(obj.fotoPath)
      ..writeByte(8)
      ..write(obj.fotoCloudUrl)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.pelaporId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaporanLokalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
