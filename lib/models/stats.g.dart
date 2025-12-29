// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StatAttributeAdapter extends TypeAdapter<StatAttribute> {
  @override
  final int typeId = 3;

  @override
  StatAttribute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StatAttribute(
      level: fields[0] as int,
      currentXp: fields[1] as int,
      maxXp: fields[2] as int,
      tier: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StatAttribute obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.level)
      ..writeByte(1)
      ..write(obj.currentXp)
      ..writeByte(2)
      ..write(obj.maxXp)
      ..writeByte(3)
      ..write(obj.tier);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatAttributeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlayerStatsAdapter extends TypeAdapter<PlayerStats> {
  @override
  final int typeId = 4;

  @override
  PlayerStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerStats(
      strength: fields[0] as StatAttribute,
      agility: fields[1] as StatAttribute,
      intelligence: fields[2] as StatAttribute,
      discipline: fields[3] as StatAttribute,
      globalLevel: fields[4] as int,
      currentXp: fields[5] as int,
      maxXp: fields[7] as int,
      streak: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerStats obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.strength)
      ..writeByte(1)
      ..write(obj.agility)
      ..writeByte(2)
      ..write(obj.intelligence)
      ..writeByte(3)
      ..write(obj.discipline)
      ..writeByte(4)
      ..write(obj.globalLevel)
      ..writeByte(5)
      ..write(obj.currentXp)
      ..writeByte(6)
      ..write(obj.streak)
      ..writeByte(7)
      ..write(obj.maxXp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
