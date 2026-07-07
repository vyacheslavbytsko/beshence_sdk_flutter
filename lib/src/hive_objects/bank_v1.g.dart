// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_v1.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BankV1Adapter extends TypeAdapter<BankV1> {
  @override
  final typeId = 27463;

  @override
  BankV1 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BankV1(
      id: fields[0] as String,
      apiUrls: (fields[1] as List?)?.cast<String>(),
      accessToken: fields[2] as String,
      refreshToken: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BankV1 obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.apiUrls)
      ..writeByte(2)
      ..write(obj.accessToken)
      ..writeByte(3)
      ..write(obj.refreshToken);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankV1Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
