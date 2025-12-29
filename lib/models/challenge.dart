import 'package:hive/hive.dart';
import 'package:ascend/models/enums.dart';

part 'challenge.g.dart';

@HiveType(typeId: 6)
class Challenge {
  @HiveField(0) final String id;
  @HiveField(1) final String templateId;
  @HiveField(2) final String name;
  @HiveField(3) double current;
  @HiveField(4) double target;
  @HiveField(5) final String unit;
  @HiveField(6) final ChallengeType type;
  @HiveField(7) final ChallengeAttribute attribute;
  @HiveField(8) bool isRunning;
  @HiveField(9) final DateTime dateAssigned;

  Challenge({
    required this.id,
    required this.templateId,
    required this.name,
    required this.current,
    required this.target,
    required this.unit,
    required this.type,
    required this.attribute,
    required this.dateAssigned,
    this.isRunning = false,
  });

  bool get isCompleted => current >= target;
  double get progress {
    if (target <= 0) return 1.0;
    return (current / target).clamp(0.0, 1.0);
  }
}