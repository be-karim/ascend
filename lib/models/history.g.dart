// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 8;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntry(
      date: fields[0] as DateTime,
      completedCount: fields[1] as int,
      totalXpGained: fields[2] as int,
      completedChallengeNames: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.completedCount)
      ..writeByte(2)
      ..write(obj.totalXpGained)
      ..writeByte(3)
      ..write(obj.completedChallengeNames);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
