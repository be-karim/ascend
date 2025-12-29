// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChallengeTemplateAdapter extends TypeAdapter<ChallengeTemplate> {
  @override
  final int typeId = 5;

  @override
  ChallengeTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChallengeTemplate(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      defaultTarget: fields[3] as double,
      unit: fields[4] as String,
      type: fields[5] as ChallengeType,
      attribute: fields[6] as ChallengeAttribute,
      difficulty: fields[7] as Difficulty,
    );
  }

  @override
  void write(BinaryWriter writer, ChallengeTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.defaultTarget)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.attribute)
      ..writeByte(7)
      ..write(obj.difficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
