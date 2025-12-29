import 'package:hive_flutter/hive_flutter.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/stats.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/repositories/challenges_repository.dart';
import 'package:flutter/material.dart'; // for Icons

class HiveChallengesRepository implements ChallengesRepository {
  static const String boxLibrary = 'libraryBox';
  static const String boxRoutines = 'routinesBox';
  static const String boxChallenges = 'activeChallengesBox';
  static const String boxStats = 'statsBox';

  late Box<ChallengeTemplate> _libraryBox;
  late Box<RoutineStack> _routinesBox;
  late Box<Challenge> _activeBox;
  late Box<PlayerStats> _statsBox;

  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    Hive.registerAdapter(ChallengeTypeAdapter());
    Hive.registerAdapter(ChallengeAttributeAdapter());
    Hive.registerAdapter(DifficultyAdapter());
    Hive.registerAdapter(StatAttributeAdapter());
    Hive.registerAdapter(PlayerStatsAdapter());
    Hive.registerAdapter(ChallengeTemplateAdapter());
    Hive.registerAdapter(ChallengeAdapter());
    Hive.registerAdapter(RoutineStackAdapter());

    _libraryBox = await Hive.openBox<ChallengeTemplate>(boxLibrary);
    _routinesBox = await Hive.openBox<RoutineStack>(boxRoutines);
    _activeBox = await Hive.openBox<Challenge>(boxChallenges);
    _statsBox = await Hive.openBox<PlayerStats>(boxStats);

    await _seedDefaultsIfNeeded();
  }

  Future<void> _seedDefaultsIfNeeded() async {
    if (_libraryBox.isEmpty) {
      final defaults = [
        ChallengeTemplate(id: 't1', title: 'Push-Ups', description: 'Chest & Triceps', defaultTarget: 50, unit: 'reps', type: ChallengeType.reps, attribute: ChallengeAttribute.strength),
        ChallengeTemplate(id: 't2', title: 'Hydration', description: 'Daily water intake', defaultTarget: 3000, unit: 'ml', type: ChallengeType.hydration, attribute: ChallengeAttribute.discipline),
        ChallengeTemplate(id: 't3', title: 'Deep Work', description: 'Focused productivity', defaultTarget: 60, unit: 'min', type: ChallengeType.time, attribute: ChallengeAttribute.intelligence),
        ChallengeTemplate(id: 't4', title: 'Running', description: 'Cardio session', defaultTarget: 5, unit: 'km', type: ChallengeType.reps, attribute: ChallengeAttribute.agility),
        ChallengeTemplate(id: 't5', title: 'Cold Shower', description: 'Thermodynamic stress', defaultTarget: 1, unit: 'sess', type: ChallengeType.reps, attribute: ChallengeAttribute.discipline),
      ];
      await _libraryBox.addAll(defaults);
    }

    if (_statsBox.isEmpty) {
      await _statsBox.put('player', const PlayerStats(
        strength: StatAttribute(),
        agility: StatAttribute(),
        intelligence: StatAttribute(),
        discipline: StatAttribute(),
      ));
    }
  }

  // --- INTERFACE IMPLEMENTATION ---

  @override
  Future<List<ChallengeTemplate>> fetchTemplates() async {
    return _libraryBox.values.toList();
  }

  @override
  Future<void> saveTemplate(ChallengeTemplate template) async {
    // If ID exists, it updates; if not, it adds (assuming key is ID, but here we use auto-keys or just values)
    // To allow updates by ID easily, we should find the key.
    // For MVP, simplistic add/update:
    final index = _libraryBox.values.toList().indexWhere((t) => t.id == template.id);
    if (index != -1) {
      await _libraryBox.putAt(index, template);
    } else {
      await _libraryBox.add(template);
    }
  }

  // Helper methods for the Provider to call
  Future<List<RoutineStack>> fetchRoutines() async {
    return _routinesBox.values.toList();
  }

  Future<void> saveRoutine(RoutineStack stack) async {
    await _routinesBox.add(stack);
  }

  Future<List<Challenge>> fetchActiveChallenges() async {
    // Filter for "Today" could happen here or in logic. 
    // For now, return all in box (assuming we clear old ones or filter by date in logic)
    return _activeBox.values.toList();
  }

  Future<void> saveActiveChallenge(Challenge challenge) async {
    await _activeBox.put(challenge.id, challenge); // Use ID as key for easy update
  }

  Future<void> deleteActiveChallenge(String id) async {
    await _activeBox.delete(id);
  }

  Future<PlayerStats> fetchPlayerStats() async {
    return _statsBox.get('player')!;
  }

  Future<void> savePlayerStats(PlayerStats stats) async {
    await _statsBox.put('player', stats);
  }
}