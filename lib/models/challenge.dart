// lib/models/challenge.dart

import 'package:ascend/models/enums.dart';

class Challenge {
  final String id;
  final String templateId; // Referenz zum Original-Template
  final String name;
  
  // Diese Felder sind veränderbar (für Daily Progress)
  // In einer reinen immutablen Architektur würde man hier auch 'final' nutzen
  // und copyWith() verwenden, aber für einfache Handhabung ist das hier okay.
  double current; 
  double target;
  
  final String unit;
  final ChallengeType type;
  final ChallengeAttribute attribute;
  
  bool isRunning; // Für Timer
  final DateTime dateAssigned;

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