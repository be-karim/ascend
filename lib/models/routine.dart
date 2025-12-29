import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:ascend/models/template.dart';

part 'routine.g.dart';

@HiveType(typeId: 7)
class RoutineStack {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final int iconCodePoint; // Store int instead of IconData
  @HiveField(3) final List<ChallengeTemplate> templates;

  RoutineStack({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.templates,
  });
  
  // Helper to get actual Icon
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}