// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChallengeLogAdapter extends TypeAdapter<ChallengeLog> {
  @override
  final int typeId = 9;

  @override
  ChallengeLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChallengeLog(
      timestamp: fields[0] as DateTime,
      amount: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ChallengeLog obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
