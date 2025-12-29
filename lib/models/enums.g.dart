// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChallengeTypeAdapter extends TypeAdapter<ChallengeType> {
  @override
  final int typeId = 0;

  @override
  ChallengeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChallengeType.reps;
      case 1:
        return ChallengeType.time;
      case 2:
        return ChallengeType.hydration;
      case 3:
        return ChallengeType.boolean;
      default:
        return ChallengeType.reps;
    }
  }

  @override
  void write(BinaryWriter writer, ChallengeType obj) {
    switch (obj) {
      case ChallengeType.reps:
        writer.writeByte(0);
        break;
      case ChallengeType.time:
        writer.writeByte(1);
        break;
      case ChallengeType.hydration:
        writer.writeByte(2);
        break;
      case ChallengeType.boolean:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChallengeAttributeAdapter extends TypeAdapter<ChallengeAttribute> {
  @override
  final int typeId = 1;

  @override
  ChallengeAttribute read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChallengeAttribute.strength;
      case 1:
        return ChallengeAttribute.agility;
      case 2:
        return ChallengeAttribute.intelligence;
      case 3:
        return ChallengeAttribute.discipline;
      default:
        return ChallengeAttribute.strength;
    }
  }

  @override
  void write(BinaryWriter writer, ChallengeAttribute obj) {
    switch (obj) {
      case ChallengeAttribute.strength:
        writer.writeByte(0);
        break;
      case ChallengeAttribute.agility:
        writer.writeByte(1);
        break;
      case ChallengeAttribute.intelligence:
        writer.writeByte(2);
        break;
      case ChallengeAttribute.discipline:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeAttributeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DifficultyAdapter extends TypeAdapter<Difficulty> {
  @override
  final int typeId = 2;

  @override
  Difficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Difficulty.iron;
      case 1:
        return Difficulty.bronze;
      case 2:
        return Difficulty.silver;
      case 3:
        return Difficulty.gold;
      case 4:
        return Difficulty.ascended;
      default:
        return Difficulty.iron;
    }
  }

  @override
  void write(BinaryWriter writer, Difficulty obj) {
    switch (obj) {
      case Difficulty.iron:
        writer.writeByte(0);
        break;
      case Difficulty.bronze:
        writer.writeByte(1);
        break;
      case Difficulty.silver:
        writer.writeByte(2);
        break;
      case Difficulty.gold:
        writer.writeByte(3);
        break;
      case Difficulty.ascended:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
