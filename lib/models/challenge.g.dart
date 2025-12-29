// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChallengeAdapter extends TypeAdapter<Challenge> {
  @override
  final int typeId = 6;

  @override
  Challenge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Challenge(
      id: fields[0] as String,
      templateId: fields[1] as String,
      name: fields[2] as String,
      logs: (fields[11] as List).cast<ChallengeLog>(),
      target: fields[4] as double,
      unit: fields[5] as String,
      type: fields[6] as ChallengeType,
      attribute: fields[7] as ChallengeAttribute,
      dateAssigned: fields[9] as DateTime,
      isRunning: fields[8] as bool,
      completedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Challenge obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(11)
      ..write(obj.logs)
      ..writeByte(4)
      ..write(obj.target)
      ..writeByte(5)
      ..write(obj.unit)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.attribute)
      ..writeByte(8)
      ..write(obj.isRunning)
      ..writeByte(9)
      ..write(obj.dateAssigned)
      ..writeByte(10)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
