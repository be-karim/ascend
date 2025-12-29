// lib/models/routine.dart

import 'package:flutter/widgets.dart'; // Für IconData
import 'package:ascend/models/template.dart';

class RoutineStack {
  final String id;
  final String title;
  final IconData icon;
  final List<ChallengeTemplate> templates;

  RoutineStack({
    required this.id,
    required this.title,
    required this.icon,
    required this.templates,
  });
}