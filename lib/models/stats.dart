// lib/models/stats.dart

class StatAttribute {
  final int level;
  final int currentXp;
  final int maxXp;
  final int tier; // 0=Iron, 1=Bronze, etc.

  const StatAttribute({
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 100,
    this.tier = 0,
  });

  // WICHTIG für Riverpod: State ist immutable (unveränderlich).
  // Wir verändern Objekte nicht, wir kopieren sie mit neuen Werten.
  StatAttribute copyWith({
    int? level,
    int? currentXp,
    int? maxXp,
    int? tier,
  }) {
    return StatAttribute(
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      tier: tier ?? this.tier,
    );
  }

  // Für Datenbank (JSON)
  Map<String, dynamic> toJson() => {
    'level': level,
    'currentXp': currentXp,
    'maxXp': maxXp,
    'tier': tier,
  };

  factory StatAttribute.fromJson(Map<String, dynamic> json) {
    return StatAttribute(
      level: json['level'] ?? 1,
      currentXp: json['currentXp'] ?? 0,
      maxXp: json['maxXp'] ?? 100,
      tier: json['tier'] ?? 0,
    );
  }
}

class PlayerStats {
  final StatAttribute strength;
  final StatAttribute agility;
  final StatAttribute intelligence;
  final StatAttribute discipline;
  
  final int globalLevel;
  final int currentXp;
  final int maxXp;
  final int streak;

  const PlayerStats({
    required this.strength,
    required this.agility,
    required this.intelligence,
    required this.discipline,
    this.globalLevel = 1,
    this.currentXp = 0,
    this.maxXp = 1000,
    this.streak = 0,
  });

  // Helper für State Updates
  PlayerStats copyWith({
    StatAttribute? strength,
    StatAttribute? agility,
    StatAttribute? intelligence,
    StatAttribute? discipline,
    int? globalLevel,
    int? currentXp,
    int? maxXp,
    int? streak,
  }) {
    return PlayerStats(
      strength: strength ?? this.strength,
      agility: agility ?? this.agility,
      intelligence: intelligence ?? this.intelligence,
      discipline: discipline ?? this.discipline,
      globalLevel: globalLevel ?? this.globalLevel,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      streak: streak ?? this.streak,
    );
  }

  // Serialisierung
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

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      strength: StatAttribute.fromJson(json['strength']),
      agility: StatAttribute.fromJson(json['agility']),
      intelligence: StatAttribute.fromJson(json['intelligence']),
      discipline: StatAttribute.fromJson(json['discipline']),
      globalLevel: json['globalLevel'] ?? 1,
      currentXp: json['currentXp'] ?? 0,
      maxXp: json['maxXp'] ?? 1000,
      streak: json['streak'] ?? 0,
    );
  }
}