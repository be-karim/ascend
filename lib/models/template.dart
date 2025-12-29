import 'package:flutter/widgets.dart'; // Für IconData
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
  @HiveField(8) final int? iconCodePoint; // NEU: Individuelles Icon

  ChallengeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.defaultTarget,
    required this.unit,
    required this.type,
    required this.attribute,
    this.difficulty = Difficulty.iron,
    this.iconCodePoint,
  });
  
  // Helper
  IconData? get icon => iconCodePoint != null ? IconData(iconCodePoint!, fontFamily: 'MaterialIcons') : null;

  ChallengeTemplate copyWith({
    String? id,
    String? title,
    String? description,
    double? defaultTarget,
    String? unit,
    ChallengeType? type,
    ChallengeAttribute? attribute,
    Difficulty? difficulty,
    int? iconCodePoint,
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
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }
}