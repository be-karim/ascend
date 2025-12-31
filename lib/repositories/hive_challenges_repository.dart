import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart'; // Für Icons
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/stats.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/history.dart';
import 'package:ascend/models/challenge_log.dart';
import 'package:ascend/repositories/challenges_repository.dart';

class HiveChallengesRepository implements ChallengesRepository {
  static const String boxLibrary = 'libraryBox';
  static const String boxRoutines = 'routinesBox';
  static const String boxChallenges = 'activeChallengesBox';
  static const String boxStats = 'statsBox';
  static const String boxHistory = 'historyBox';
  static const String boxSettings = 'settingsBox';

  late Box<ChallengeTemplate> _libraryBox;
  late Box<RoutineStack> _routinesBox;
  late Box<Challenge> _activeBox;
  late Box<PlayerStats> _statsBox;
  late Box<HistoryEntry> _historyBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(ChallengeTypeAdapter());
    Hive.registerAdapter(ChallengeAttributeAdapter());
    Hive.registerAdapter(DifficultyAdapter());
    Hive.registerAdapter(StatAttributeAdapter());
    Hive.registerAdapter(PlayerStatsAdapter());
    Hive.registerAdapter(ChallengeTemplateAdapter());
    Hive.registerAdapter(ChallengeAdapter());
    Hive.registerAdapter(RoutineStackAdapter());
    Hive.registerAdapter(HistoryEntryAdapter());
    Hive.registerAdapter(ChallengeLogAdapter());

    _libraryBox = await Hive.openBox<ChallengeTemplate>(boxLibrary);
    _routinesBox = await Hive.openBox<RoutineStack>(boxRoutines);
    _activeBox = await Hive.openBox<Challenge>(boxChallenges);
    _statsBox = await Hive.openBox<PlayerStats>(boxStats);
    _historyBox = await Hive.openBox<HistoryEntry>(boxHistory);
    _settingsBox = await Hive.openBox(boxSettings);

    await _seedDefaultsIfNeeded();
  }

  Future<void> _seedDefaultsIfNeeded() async {
    if (_libraryBox.isEmpty) {
      final defaults = [
        // --- BODY (Agility / Strength) ---
        ChallengeTemplate(
          id: 'p_xmkqp', title: 'Yoga Stretching', description: 'YouTube Session',
          defaultTarget: 1, unit: 'sess', type: ChallengeType.boolean, attribute: ChallengeAttribute.agility,
          iconCodePoint: Icons.self_improvement.codePoint
        ),
        ChallengeTemplate(
          id: 'p_o9f1e', title: 'Morning Run', description: 'Planten un Blomen',
          defaultTarget: 5, unit: 'km', type: ChallengeType.reps, attribute: ChallengeAttribute.agility,
          iconCodePoint: Icons.directions_run.codePoint
        ),
        ChallengeTemplate(
          id: 'p_81uso', title: 'Pike Push Ups', description: 'Shoulder Focus',
          defaultTarget: 50, unit: 'reps', type: ChallengeType.reps, attribute: ChallengeAttribute.strength,
          iconCodePoint: Icons.accessibility_new.codePoint
        ),
        ChallengeTemplate(
          id: 'p_nc23e', title: 'Push Ups', description: 'Volume Training',
          defaultTarget: 200, unit: 'reps', type: ChallengeType.reps, attribute: ChallengeAttribute.strength,
          iconCodePoint: Icons.fitness_center.codePoint
        ),
        ChallengeTemplate(
          id: 'p_ojxea', title: 'Pull Ups', description: 'Back & Biceps',
          defaultTarget: 200, unit: 'reps', type: ChallengeType.reps, attribute: ChallengeAttribute.strength,
          iconCodePoint: Icons.height.codePoint
        ),
        ChallengeTemplate(
          id: 'p_oe8ya', title: 'Handstand', description: 'Static Hold',
          defaultTarget: 10, unit: 'min', type: ChallengeType.time, attribute: ChallengeAttribute.strength,
          iconCodePoint: Icons.accessibility.codePoint
        ),

        // --- MIND (Intelligence) ---
        ChallengeTemplate(
          id: 'p_1nhas', title: 'Learning Italian', description: 'Vocab & Grammar',
          defaultTarget: 30, unit: 'min', type: ChallengeType.time, attribute: ChallengeAttribute.intelligence,
          iconCodePoint: Icons.language.codePoint
        ),
        ChallengeTemplate(
          id: 'p_aars5', title: 'Reading Book', description: 'Deep Focus',
          defaultTarget: 30, unit: 'min', type: ChallengeType.time, attribute: ChallengeAttribute.intelligence,
          iconCodePoint: Icons.menu_book.codePoint
        ),
        ChallengeTemplate(
          id: 'p_uuljt', title: 'Podcast Learning', description: 'Educational',
          defaultTarget: 15, unit: 'min', type: ChallengeType.time, attribute: ChallengeAttribute.intelligence,
          iconCodePoint: Icons.headphones.codePoint
        ),
        ChallengeTemplate(
          id: 'p_mqjof', title: 'Journaling', description: 'Reflection',
          defaultTarget: 10, unit: 'min', type: ChallengeType.time, attribute: ChallengeAttribute.intelligence,
          iconCodePoint: Icons.edit_note.codePoint
        ),

        // --- GRIND (Discipline) ---
        ChallengeTemplate(
          id: 'p_zb4x0', title: 'Walking', description: 'Active Recovery',
          defaultTarget: 30, unit: 'min', type: ChallengeType.time, attribute: ChallengeAttribute.discipline,
          iconCodePoint: Icons.directions_walk.codePoint
        ),
        ChallengeTemplate(
          id: 'p_owd6s', title: 'Breath Work', description: 'Wim Hof / Box',
          defaultTarget: 5, unit: 'min', type: ChallengeType.time, attribute: ChallengeAttribute.discipline,
          iconCodePoint: Icons.air.codePoint
        ),
        ChallengeTemplate(
          id: 'p_8v2e8', title: 'Cold Shower', description: 'Exposure Therapy',
          defaultTarget: 1, unit: 'sess', type: ChallengeType.boolean, attribute: ChallengeAttribute.discipline,
          iconCodePoint: Icons.ac_unit.codePoint
        ),
        ChallengeTemplate(
          id: 'p_ktyz9', title: 'Day Planning', description: 'Structure Tomorrow',
          defaultTarget: 1, unit: 'sess', type: ChallengeType.boolean, attribute: ChallengeAttribute.discipline,
          iconCodePoint: Icons.calendar_today.codePoint
        ),
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

  // --- STANDARD METHODEN (Ab hier unverändert, aber wichtig für Interface) ---
  @override
  Future<List<ChallengeTemplate>> fetchTemplates() async => _libraryBox.values.toList();

  @override
  Future<void> saveTemplate(ChallengeTemplate template) async {
    final index = _libraryBox.values.toList().indexWhere((t) => t.id == template.id);
    if (index != -1) {
      await _libraryBox.putAt(index, template);
    } else {
      await _libraryBox.add(template);
    }
  }

  Future<List<RoutineStack>> fetchRoutines() async => _routinesBox.values.toList();
  Future<void> saveRoutine(RoutineStack stack) async => await _routinesBox.add(stack);

  Future<List<Challenge>> fetchActiveChallenges() async => _activeBox.values.toList();
  Future<void> saveActiveChallenge(Challenge challenge) async => await _activeBox.put(challenge.id, challenge);
  Future<void> deleteActiveChallenge(String id) async => await _activeBox.delete(id);

  Future<PlayerStats> fetchPlayerStats() async => _statsBox.get('player')!;
  Future<void> savePlayerStats(PlayerStats stats) async => await _statsBox.put('player', stats);

  Future<List<HistoryEntry>> fetchHistory() async => _historyBox.values.toList();
  Future<void> saveHistoryEntry(HistoryEntry entry) async => await _historyBox.add(entry);

  DateTime? getLastOpenedDate() {
    final str = _settingsBox.get('lastOpenedDate');
    if (str == null) return null;
    return DateTime.parse(str);
  }

  Future<void> setLastOpenedDate(DateTime date) async {
    await _settingsBox.put('lastOpenedDate', date.toIso8601String());
  }
}