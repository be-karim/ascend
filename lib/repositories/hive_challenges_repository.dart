import 'package:hive_flutter/hive_flutter.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/stats.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/history.dart'; // Import new model
import 'package:ascend/repositories/challenges_repository.dart';

class HiveChallengesRepository implements ChallengesRepository {
  static const String boxLibrary = 'libraryBox';
  static const String boxRoutines = 'routinesBox';
  static const String boxChallenges = 'activeChallengesBox';
  static const String boxStats = 'statsBox';
  static const String boxHistory = 'historyBox';
  static const String boxSettings = 'settingsBox'; // For tracking "Last Opened"

  late Box<ChallengeTemplate> _libraryBox;
  late Box<RoutineStack> _routinesBox;
  late Box<Challenge> _activeBox;
  late Box<PlayerStats> _statsBox;
  late Box<HistoryEntry> _historyBox;
  late Box _settingsBox;

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
    Hive.registerAdapter(HistoryEntryAdapter()); // New Adapter

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

  // --- STANDARD FETCHERS ---

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

  // --- HISTORY & SETTINGS METHODS ---

  Future<List<HistoryEntry>> fetchHistory() async => _historyBox.values.toList();
  
  Future<void> saveHistoryEntry(HistoryEntry entry) async {
    await _historyBox.add(entry);
  }

  DateTime? getLastOpenedDate() {
    final str = _settingsBox.get('lastOpenedDate');
    if (str == null) return null;
    return DateTime.parse(str);
  }

  Future<void> setLastOpenedDate(DateTime date) async {
    await _settingsBox.put('lastOpenedDate', date.toIso8601String());
  }
}