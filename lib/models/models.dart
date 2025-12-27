
import 'package:flutter/material.dart';

class StatAttribute {
  int level;
  int currentXp;
  int maxXp;
  int tier; // 0=Iron, 1=Bronze, etc.

  StatAttribute({
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 100,
    this.tier = 0,
  });

  void addXp(int amount) {
    currentXp += amount;
    if (currentXp >= maxXp) {
      _levelUp();
    }
  }

  void _levelUp() {
    level++;
    currentXp -= maxXp;
    // Exponential curve: 100 * (Level ^ 1.8)
    maxXp = (100 * (level * 1.8)).toInt();
    
    // Tier Ascension at lvl 100
    if (level >= 100) {
      tier++;
      level = 1;
      maxXp = 100; // Reset curve but Tier acts as multiplier elsewhere
    }
  }
  Map<String, dynamic> toJson() => {
    'level': level,
    'currentXp': currentXp,
    'maxXp': maxXp,
    'tier': tier,
  };

  factory StatAttribute.fromJson(Map<String, dynamic> json) => StatAttribute(
    level: json['level'] ?? 1,
    currentXp: json['currentXp'] ?? 0,
    maxXp: json['maxXp'] ?? 100,
    tier: json['tier'] ?? 0,
  );
}

class PlayerStats {
  StatAttribute strength;
  StatAttribute agility;
  StatAttribute intelligence;
  StatAttribute discipline;
  
  // General
  int globalLevel; // Calculated or separate?
  int currentXp;
  int maxXp;
  int streak;

  PlayerStats({
    required this.strength,
    required this.agility,
    required this.intelligence,
    required this.discipline,
    this.globalLevel = 1,
    this.currentXp = 0,
    this.maxXp = 1000,
    this.streak = 0,
  });

  Map<String, dynamic> toJson() => {
    'strength': strength.toJson(),
    'agility': agility.toJson(),
    'intelligence': intelligence.toJson(),
    'discipline': discipline.toJson(),
    'globalLevel': globalLevel,
    'currentXp': currentXp,
    'maxXp': maxXp,
    'streak': streak,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    strength: StatAttribute.fromJson(json['strength']),
    agility: StatAttribute.fromJson(json['agility']),
    intelligence: StatAttribute.fromJson(json['intelligence']),
    discipline: StatAttribute.fromJson(json['discipline']),
    globalLevel: json['globalLevel'] ?? 1,
    currentXp: json['currentXp'] ?? 0,
    maxXp: json['maxXp'] ?? 1000,
    streak: json['streak'] ?? 0,
  );

  // Helper to get total power for ranking
  int get totalPower => 
      strength.level + agility.level + intelligence.level + discipline.level +
      ((strength.tier + agility.tier + intelligence.tier + discipline.tier) * 100);
}

class Quest {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final String type; // 'STR', 'AGI', 'INT', 'DIS'
  bool isCompleted;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.type,
    this.isCompleted = false,
  });
}

// Mock Data
final PlayerStats mockPlayer = PlayerStats(
  strength: StatAttribute(level: 12, maxXp: 800),
  agility: StatAttribute(level: 5, maxXp: 300),
  intelligence: StatAttribute(level: 8, maxXp: 500),
  discipline: StatAttribute(level: 20, maxXp: 1500),
);

final List<Quest> mockDailyQuests = [
  Quest(id: '1', title: 'Morning Hydra', description: 'Drink 500ml water', xpReward: 10, type: 'DIS'),
  Quest(id: '2', title: 'Pushups x50', description: 'Chest and triceps', xpReward: 25, type: 'STR'),
  Quest(id: '3', title: 'Read Chapter', description: 'Clean Code', xpReward: 20, type: 'INT'),
  Quest(id: '4', title: 'Morning Run', description: '3km jog', xpReward: 30, type: 'AGI'),
];
enum ChallengeType { reps, time, hydration }

enum ChallengeAttribute { strength, agility, intelligence, discipline }

class RoutineStack {
  final String title;
  final IconData icon;
  final List<Challenge> tasks;

  RoutineStack({
    required this.title,
    required this.icon,
    required this.tasks,
  });
}

class Challenge {
  final String id;
  final String name;
  double current;
  final double target;
  final String unit;
  final ChallengeType type;
  final ChallengeAttribute attribute;
  bool isRunning;

  Challenge({
    required this.id,
    required this.name,
    required this.current,
    required this.target,
    required this.unit,
    required this.type,
    required this.attribute,
    this.isRunning = false,
  });

  bool get isCompleted => current >= target;
  double get progress => (current / target).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'current': current,
    'target': target,
    'unit': unit,
    'type': type.index,
    'attribute': attribute.index,
    'isRunning': isRunning,
  };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
    id: json['id'],
    name: json['name'],
    current: json['current'],
    target: json['target'],
    unit: json['unit'],
    type: ChallengeType.values[json['type']],
    attribute: ChallengeAttribute.values[json['attribute']],
    isRunning: json['isRunning'] ?? false,
  );
}

