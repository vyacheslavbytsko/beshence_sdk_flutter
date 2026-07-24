// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_v1.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaultV1Adapter extends TypeAdapter<VaultV1> {
  @override
  final typeId = 27464;

  @override
  VaultV1 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VaultV1(
      id: fields[0] as String,
      accountId: fields[1] as String,
      bankId: fields[2] as String,
      priority: (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, VaultV1 obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.bankId)
      ..writeByte(3)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultV1Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
