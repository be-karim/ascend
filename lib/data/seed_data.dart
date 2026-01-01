import 'package:ascend/models/routine.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/enums.dart';
import 'package:flutter/material.dart';

class SeedData {
  static final List<ChallengeTemplate> initialProtocols = [
    // --- BODY (Strength & Agility) ---
    ChallengeTemplate(
      id: 'std_pushups',
      title: 'Push Ups',
      description: 'Standard chest and tricep exercise.',
      type: ChallengeType.reps,
      unit: 'reps',
      defaultTarget: 50,
      attribute: ChallengeAttribute.strength,
    ),
    ChallengeTemplate(
      id: 'std_squats',
      title: 'Air Squats',
      description: 'Leg strength and mobility.',
      type: ChallengeType.reps,
      unit: 'reps',
      defaultTarget: 50,
      attribute: ChallengeAttribute.strength,
    ),
    ChallengeTemplate(
      id: 'std_run',
      title: 'Morning Run',
      description: 'Cardio activation.',
      type: ChallengeType.time,
      unit: 'min',
      defaultTarget: 30, // 30 Minutes
      attribute: ChallengeAttribute.agility,
    ),
    ChallengeTemplate(
      id: 'std_plank',
      title: 'Core Plank',
      description: 'Static core stability.',
      type: ChallengeType.time,
      unit: 'min',
      defaultTarget: 5,
      attribute: ChallengeAttribute.strength,
    ),
    
    // --- MIND (Intelligence) ---
    ChallengeTemplate(
      id: 'std_reading',
      title: 'Read Book',
      description: 'Expand knowledge base.',
      type: ChallengeType.time,
      unit: 'min',
      defaultTarget: 30,
      attribute: ChallengeAttribute.intelligence,
    ),
    ChallengeTemplate(
      id: 'std_learn_lang',
      title: 'Language Learning',
      description: 'Vocabulary and grammar practice.',
      type: ChallengeType.time,
      unit: 'min',
      defaultTarget: 15,
      attribute: ChallengeAttribute.intelligence,
    ),
    ChallengeTemplate(
      id: 'std_meditation',
      title: 'Meditation',
      description: 'Mindfulness and focus resetting.',
      type: ChallengeType.time,
      unit: 'min',
      defaultTarget: 20,
      attribute: ChallengeAttribute.intelligence,
    ),

    // --- GRIND (Discipline & Hydration) ---
    ChallengeTemplate(
      id: 'std_hydration',
      title: 'Hydration',
      description: 'Daily water intake.',
      type: ChallengeType.hydration,
      unit: 'ml',
      defaultTarget: 3000,
      attribute: ChallengeAttribute.strength, // Or Discipline, depending on preference
    ),
    ChallengeTemplate(
      id: 'std_cold_shower',
      title: 'Cold Shower',
      description: 'Build resilience through cold exposure.',
      type: ChallengeType.boolean,
      unit: 'done',
      defaultTarget: 1,
      attribute: ChallengeAttribute.discipline,
    ),
    ChallengeTemplate(
      id: 'std_plan_day',
      title: 'Tactical Planning',
      description: 'Plan the next day\'s missions.',
      type: ChallengeType.boolean,
      unit: 'done',
      defaultTarget: 1,
      attribute: ChallengeAttribute.discipline,
    ),
    ChallengeTemplate(
      id: 'std_protein',
      title: 'Protein Intake',
      description: 'Track daily protein consumption.',
      type: ChallengeType.reps, // Reps works well for grams
      unit: 'g',
      defaultTarget: 160,
      attribute: ChallengeAttribute.strength,
    ),
  ];

  static RoutineStack getMorningRoutine(List<ChallengeTemplate> availableTemplates) {
    // Helper to find template by ID
    ChallengeTemplate? find(String id) => availableTemplates.cast<ChallengeTemplate?>().firstWhere((t) => t?.id == id, orElse: () => null);

    final selected = [
      find('std_hydration'),
      find('std_pushups'),
      find('std_cold_shower'),
      find('std_meditation'),
    ].whereType<ChallengeTemplate>().toList();

    return RoutineStack(
      id: 'routine_morning_glory',
      title: 'Morning Glory',
      iconCodePoint: Icons.wb_sunny.codePoint,
      templates: selected,
    );
  }
}
