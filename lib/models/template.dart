// lib/models/template.dart

import 'package:ascend/models/enums.dart';

class ChallengeTemplate {
  final String id;
  final String title;
  final String description;
  final double defaultTarget;
  final String unit; // z.B. "reps", "min", "km"
  final ChallengeType type;
  final ChallengeAttribute attribute;
  final Difficulty difficulty;

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

  // Hilfreich, wenn wir Templates bearbeiten
  ChallengeTemplate copyWith({
    String? title,
    String? description,
    double? defaultTarget,
    String? unit,
    ChallengeType? type,
    ChallengeAttribute? attribute,
    Difficulty? difficulty,
  }) {
    return ChallengeTemplate(
      id: this.id, // ID bleibt immer gleich
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