import 'package:hive/hive.dart';
import 'package:ascend/models/enums.dart';

part 'template.g.dart';

@HiveType(typeId: 5)
class ChallengeTemplate {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String description;
  @HiveField(3) final double defaultTarget;
  @HiveField(4) final String unit;
  @HiveField(5) final ChallengeType type;
  @HiveField(6) final ChallengeAttribute attribute;
  @HiveField(7) final Difficulty difficulty;

  ChallengeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.defaultTarget,
    required this.unit,
    required this.type,
    required this.attribute,
    this.difficulty = Difficulty.iron,
  });
  
  ChallengeTemplate copyWith({
    String? id,
    String? title,
    String? description,
    double? defaultTarget,
    String? unit,
    ChallengeType? type,
    ChallengeAttribute? attribute,
    Difficulty? difficulty,
  }) {
    return ChallengeTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      defaultTarget: defaultTarget ?? this.defaultTarget,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      attribute: attribute ?? this.attribute,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}