// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_v1.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountV1Adapter extends TypeAdapter<AccountV1> {
  @override
  final typeId = 27462;

  @override
  AccountV1 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountV1(id: fields[0] as String);
  }

  @override
  void write(BinaryWriter writer, AccountV1 obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountV1Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
