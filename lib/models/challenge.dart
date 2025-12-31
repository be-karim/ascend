import 'package:hive/hive.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/challenge_log.dart'; // Sicherstellen, dass diese Datei existiert

part 'challenge.g.dart';

@HiveType(typeId: 6)
class Challenge {
  @HiveField(0) final String id;
  @HiveField(1) final String templateId;
  @HiveField(2) final String name;
  
  // WICHTIG: 'current' entfernt, dafür 'logs' hinzugefügt
  @HiveField(11) final List<ChallengeLog> logs; 
  
  @HiveField(4) double target;
  @HiveField(5) final String unit;
  @HiveField(6) final ChallengeType type;
  @HiveField(7) final ChallengeAttribute attribute;
  @HiveField(8) bool isRunning;
  @HiveField(9) final DateTime dateAssigned;
  @HiveField(10) DateTime? completedAt;

  Challenge({
    required this.id,
    required this.templateId,
    required this.name,
    this.logs = const [], // Standardmäßig leer
    required this.target,
    required this.unit,
    required this.type,
    required this.attribute,
    required this.dateAssigned,
    this.isRunning = false,
    this.completedAt,
  });

  // Die App "denkt", es gibt current, aber wir berechnen es live.
  double get current => logs.fold(0.0, (sum, item) => sum + item.amount);

  bool get isCompleted => current >= target;
  
  double get progress {
    if (target <= 0) return 1.0;
    return (current / target).clamp(0.0, 1.0);
  }
}