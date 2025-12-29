import 'package:hive/hive.dart';

part 'history.g.dart';

@HiveType(typeId: 8)
class HistoryEntry {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final int completedCount;
  
  @HiveField(2)
  final int totalXpGained;
  
  @HiveField(3)
  final List<String> completedChallengeNames;

  HistoryEntry({
    required this.date,
    required this.completedCount,
    this.totalXpGained = 0,
    this.completedChallengeNames = const [],
  });
}