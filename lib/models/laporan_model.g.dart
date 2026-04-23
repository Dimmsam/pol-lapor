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
      uuid: fields[0] as String,
      judul: fields[1] as String,
      deskripsi: fields[2] as String,
      status: fields[3] as int,
      isSynced: fields[4] as bool,
      kategori: fields[5] as String?,
      lokasi: fields[6] as String?,
      nomorInventaris: fields[7] as String?,
      tingkatKerusakan: fields[8] as String?,
      fotoPath: fields[9] as String?,
      createdAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LaporanLokal obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.judul)
      ..writeByte(2)
      ..write(obj.deskripsi)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.kategori)
      ..writeByte(6)
      ..write(obj.lokasi)
      ..writeByte(7)
      ..write(obj.nomorInventaris)
      ..writeByte(8)
      ..write(obj.tingkatKerusakan)
      ..writeByte(9)
      ..write(obj.fotoPath)
      ..writeByte(10)
      ..write(obj.createdAt);
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
