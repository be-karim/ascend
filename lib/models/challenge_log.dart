import 'package:hive/hive.dart';

part 'challenge_log.g.dart';

@HiveType(typeId: 9) // Neue ID
class ChallengeLog {
  @HiveField(0)
  final DateTime timestamp;
  
  @HiveField(1)
  final double amount;

  ChallengeLog({required this.timestamp, required this.amount});
}