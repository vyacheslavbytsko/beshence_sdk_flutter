// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chain_v1.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChainV1Adapter extends TypeAdapter<ChainV1> {
  @override
  final typeId = 2;

  @override
  ChainV1 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChainV1(name: fields[0] as String, vaultId: fields[1] as String);
  }

  @override
  void write(BinaryWriter writer, ChainV1 obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.vaultId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChainV1Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
