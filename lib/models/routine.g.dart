// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineStackAdapter extends TypeAdapter<RoutineStack> {
  @override
  final int typeId = 7;

  @override
  RoutineStack read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineStack(
      id: fields[0] as String,
      title: fields[1] as String,
      iconCodePoint: fields[2] as int,
      templates: (fields[3] as List).cast<ChallengeTemplate>(),
    );
  }

  @override
  void write(BinaryWriter writer, RoutineStack obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.iconCodePoint)
      ..writeByte(3)
      ..write(obj.templates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineStackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
