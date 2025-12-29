import 'package:hive/hive.dart';

part 'enums.g.dart'; // This file will be generated

@HiveType(typeId: 0)
enum ChallengeType { 
  @HiveField(0) reps, 
  @HiveField(1) time, 
  @HiveField(2) hydration, 
  @HiveField(3) boolean 
}

@HiveType(typeId: 1)
enum ChallengeAttribute { 
  @HiveField(0) strength, 
  @HiveField(1) agility, 
  @HiveField(2) intelligence, 
  @HiveField(3) discipline 
}

@HiveType(typeId: 2)
enum Difficulty { 
  @HiveField(0) iron, 
  @HiveField(1) bronze, 
  @HiveField(2) silver, 
  @HiveField(3) gold, 
  @HiveField(4) ascended 
}