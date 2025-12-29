import 'package:hive/hive.dart';

part 'stats.g.dart';

@HiveType(typeId: 3)
class StatAttribute {
  @HiveField(0)
  final int level;
  @HiveField(1)
  final int currentXp;
  @HiveField(2)
  final int maxXp;
  @HiveField(3)
  final int tier;

  const StatAttribute({this.level = 1, this.currentXp = 0, this.maxXp = 100, this.tier = 0});

  StatAttribute copyWith({int? level, int? currentXp, int? maxXp, int? tier}) {
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
  @HiveField(5) final int currentXp;
  @HiveField(6) final int streak; // Renamed from maxXp to streak for clarity? Or keeping maxXp separate? 
  // Let's keep your original fields:
  @HiveField(7) final int maxXp;

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
}