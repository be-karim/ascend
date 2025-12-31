import 'package:hive/hive.dart';
import 'package:ascend/models/enums.dart';

part 'stats.g.dart';

@HiveType(typeId: 3)
class StatAttribute {
  @HiveField(0) final int level;
  @HiveField(1) final double currentXp; // Changed to double for precision
  @HiveField(2) final double maxXp;     // Changed to double
  @HiveField(3) final int tier;         // WIEDER DA!

  const StatAttribute({
    this.level = 1,
    this.currentXp = 0.0,
    this.maxXp = 100.0,
    this.tier = 0,
  });

  StatAttribute copyWith({
    int? level,
    double? currentXp,
    double? maxXp,
    int? tier,
  }) {
    return StatAttribute(
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      tier: tier ?? this.tier,
    );
  }
}

@HiveType(typeId: 4)
class PlayerStats {
  @HiveField(0) final StatAttribute strength;
  @HiveField(1) final StatAttribute agility;
  @HiveField(2) final StatAttribute intelligence;
  @HiveField(3) final StatAttribute discipline;
  
  @HiveField(4) final int globalLevel;
  @HiveField(5) final double currentXp; // Changed to double
  @HiveField(6) final int streak;       // WIEDER DA!
  @HiveField(7) final double maxXp;     // Changed to double
  
  // NEU: Mercy System
  @HiveField(8) final bool mercyTokenAvailable; 

  const PlayerStats({
    required this.strength,
    required this.agility,
    required this.intelligence,
    required this.discipline,
    this.globalLevel = 1,
    this.currentXp = 0.0,
    this.maxXp = 1000.0,
    this.streak = 0,
    this.mercyTokenAvailable = true, // Standard: Jeden Tag verfügbar
  });

  PlayerStats copyWith({
    StatAttribute? strength,
    StatAttribute? agility,
    StatAttribute? intelligence,
    StatAttribute? discipline,
    int? globalLevel,
    double? currentXp,
    int? streak,
    double? maxXp,
    bool? mercyTokenAvailable,
  }) {
    return PlayerStats(
      strength: strength ?? this.strength,
      agility: agility ?? this.agility,
      intelligence: intelligence ?? this.intelligence,
      discipline: discipline ?? this.discipline,
      globalLevel: globalLevel ?? this.globalLevel,
      currentXp: currentXp ?? this.currentXp,
      streak: streak ?? this.streak,
      maxXp: maxXp ?? this.maxXp,
      mercyTokenAvailable: mercyTokenAvailable ?? this.mercyTokenAvailable,
    );
  }
}