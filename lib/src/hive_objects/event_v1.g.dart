// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_v1.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventV1Adapter extends TypeAdapter<EventV1> {
  @override
  final typeId = 3;

  @override
  EventV1 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventV1(
      id: fields[0] as String,
      chainId: fields[1] as String,
      parentId: fields[2] as String?,
      sessionId: fields[3] as String?,
      payload: fields[4] as String,
      locallyCreatedAt: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, EventV1 obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chainId)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(3)
      ..write(obj.sessionId)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.locallyCreatedAt)
      ..writeByte(6)
      ..write(obj.createdAt);
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
