// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_v1.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventV1Adapter extends TypeAdapter<EventV1> {
  @override
  final typeId = 27466;

  @override
  EventV1 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventV1(
      id: fields[0] as String,
      name: fields[1] as String,
      chainName: fields[2] as String,
      accountId: fields[3] as String,
      tempParentId: fields[4] as String?,
      permParentId: fields[5] as String?,
      payload: fields[6] as String,
      applied: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EventV1 obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.chainName)
      ..writeByte(3)
      ..write(obj.accountId)
      ..writeByte(4)
      ..write(obj.tempParentId)
      ..writeByte(5)
      ..write(obj.permParentId)
      ..writeByte(6)
      ..write(obj.payload)
      ..writeByte(7)
      ..write(obj.applied);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventV1Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
