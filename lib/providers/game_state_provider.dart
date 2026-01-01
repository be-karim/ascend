import 'package:ascend/data/seed_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart'; // Für IconData
import 'package:ascend/models/stats.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/history.dart';
import 'package:ascend/models/challenge_log.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/repositories/hive_challenges_repository.dart';
import 'package:ascend/services/xp_service.dart';

// --- DEPENDENCY INJECTION ---

final repositoryProvider = Provider<HiveChallengesRepository>((ref) {
  return HiveChallengesRepository();
});

final xpServiceProvider = Provider<XPService>((ref) {
  return XPService();
});

// --- STATE MODEL ---

class GameState {
  final PlayerStats stats;
  final List<Challenge> activeChallenges;
  final List<ChallengeTemplate> library;
  final List<RoutineStack> routines;
  final List<HistoryEntry> history;
  final bool isLoading;

  GameState({
    required this.stats,
    required this.activeChallenges,
    required this.library,
    required this.routines,
    required this.history,
    this.isLoading = false,
  });

  GameState copyWith({
    PlayerStats? stats,
    List<Challenge>? activeChallenges,
    List<ChallengeTemplate>? library,
    List<RoutineStack>? routines,
    List<HistoryEntry>? history,
    bool? isLoading,
  }) {
    return GameState(
      stats: stats ?? this.stats,
      activeChallenges: activeChallenges ?? this.activeChallenges,
      library: library ?? this.library,
      routines: routines ?? this.routines,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- CONTROLLER (LOGIC ENGINE) ---

class GameController extends Notifier<GameState> {
  @override
  GameState build() {
    // Initialisierung asynchron starten
    Future.microtask(() => _init());
    
    // Leeren Start-Zustand zurückgeben
    return GameState(
      stats: const PlayerStats(
        strength: StatAttribute(),
        agility: StatAttribute(),
        intelligence: StatAttribute(),
        discipline: StatAttribute(),
      ),
      activeChallenges: [],
      library: [],
      routines: [],
      history: [],
      isLoading: true,
    );
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(repositoryProvider);
    await repo.init();

    await _performDailyResetIfNeeded(repo);
    
    await _seedLibraryIfNeeded(repo); 

    await _seedRoutinesIfNeeded(repo);

    final templates = await repo.fetchTemplates();
    final routines = await repo.fetchRoutines();
    final active = await repo.fetchActiveChallenges();
    final stats = await repo.fetchPlayerStats();
    final history = await repo.fetchHistory();

    state = state.copyWith(
      library: templates,
      routines: routines,
      activeChallenges: active,
      stats: stats,
      history: history,
      isLoading: false,
    );
  }

  // --- NEW SEEDING LOGIC ---
  Future<void> _seedLibraryIfNeeded(HiveChallengesRepository repo) async {
    final currentTemplates = await repo.fetchTemplates();
    final currentIds = currentTemplates.map((t) => t.id).toSet();
    
    bool hasChanges = false;

    for (var seedItem in SeedData.initialProtocols) {
      // Only add if it doesn't exist yet
      if (!currentIds.contains(seedItem.id)) {
        await repo.saveTemplate(seedItem);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      debugPrint("Library seeded with new protocols.");
    }
  }

  Future<void> _seedRoutinesIfNeeded(HiveChallengesRepository repo) async {
    final currentRoutines = await repo.fetchRoutines();
    // Only seed if NO routines exist (fresh start) to avoid duplicating if user deleted it
    if (currentRoutines.isEmpty) {
      final templates = await repo.fetchTemplates();
      if (templates.isNotEmpty) {
        final defaultRoutine = SeedData.getMorningRoutine(templates);
        // Only create if we actually found the templates
        if (defaultRoutine.templates.isNotEmpty) {
           await repo.saveRoutine(defaultRoutine);
        }
      }
    }
  }

  // --- DAILY RESET ---

  Future<void> _performDailyResetIfNeeded(HiveChallengesRepository repo) async {
    final lastOpened = repo.getLastOpenedDate();
    final now = DateTime.now();

    if (lastOpened == null) {
      await repo.setLastOpenedDate(now);
      return;
    }

    // Prüfen ob ein neuer Tag ist (Jahr, Monat oder Tag unterschiedlich)
    if (lastOpened.year != now.year || lastOpened.month != now.month || lastOpened.day != now.day) {
      
      // 1. History Eintrag erstellen
      final active = await repo.fetchActiveChallenges();
      final completed = active.where((c) => c.isCompleted).toList();
      
      if (completed.isNotEmpty) {
        await repo.saveHistoryEntry(HistoryEntry(
          date: lastOpened,
          completedCount: completed.length,
          completedChallengeNames: completed.map((c) => c.name).toList(),
        ));
      }

      // 2. Active Protocol Reset (Logs löschen, Status zurücksetzen)
      for (var challenge in active) {
        final resetChallenge = Challenge(
          id: challenge.id, templateId: challenge.templateId, name: challenge.name,
          logs: [], // Logs werden geleert -> Progress 0
          target: challenge.target, unit: challenge.unit, type: challenge.type, attribute: challenge.attribute,
          dateAssigned: DateTime.now(),
          isRunning: false,
          completedAt: null,
          isPriority: challenge.isPriority, // Prio bleibt erhalten
        );
        await repo.saveActiveChallenge(resetChallenge);
      }
      
      // 3. Stats Reset (Mercy Token auffüllen)
      final currentStats = await repo.fetchPlayerStats();
      final newStats = currentStats.copyWith(mercyTokenAvailable: true);
      await repo.savePlayerStats(newStats);

      await repo.setLastOpenedDate(now);
    }
  }

  // --- CRUD ACTIONS ---

  void addChallenge(ChallengeTemplate template) {
    final repo = ref.read(repositoryProvider);
    final newChallenge = Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString() + template.id,
      templateId: template.id, name: template.title, logs: [], target: template.defaultTarget,
      unit: template.unit, type: template.type, attribute: template.attribute, dateAssigned: DateTime.now(),
      isPriority: false,
    );
    repo.saveActiveChallenge(newChallenge);
    state = state.copyWith(activeChallenges: [...state.activeChallenges, newChallenge]);
  }

  void removeChallenge(String id) {
    final repo = ref.read(repositoryProvider);
    repo.deleteActiveChallenge(id);
    state = state.copyWith(activeChallenges: state.activeChallenges.where((c) => c.id != id).toList());
  }

  void togglePriority(String id) {
    final repo = ref.read(repositoryProvider);
    final updatedList = state.activeChallenges.map((c) {
      if (c.id == id) {
        final u = Challenge(
          id: c.id, templateId: c.templateId, name: c.name, logs: c.logs, target: c.target,
          unit: c.unit, type: c.type, attribute: c.attribute, dateAssigned: c.dateAssigned,
          isRunning: c.isRunning, completedAt: c.completedAt, isPriority: !c.isPriority
        );
        repo.saveActiveChallenge(u);
        return u;
      }
      return c;
    }).toList();
    state = state.copyWith(activeChallenges: updatedList);
  }

  // --- TACTICAL CALIBRATION (UPDATE TARGET) ---
  
  void updateChallengeTarget(String id, double newTarget, {bool useXp = false}) {
    final repo = ref.read(repositoryProvider);
    PlayerStats newStats = state.stats;

    // 1. Kosten berechnen
    if (useXp) {
       // XP Strafe
       double newXp = (newStats.currentXp - 150.0).clamp(0.0, double.infinity);
       newStats = newStats.copyWith(currentXp: newXp);
    } else {
       // Mercy Token verbrauchen
       newStats = newStats.copyWith(mercyTokenAvailable: false);
    }
    repo.savePlayerStats(newStats);

    // 2. Challenge Updaten
    final updatedList = state.activeChallenges.map((c) {
      if (c.id == id) {
        final u = Challenge(
          id: c.id, templateId: c.templateId, name: c.name, logs: c.logs, target: newTarget,
          unit: c.unit, type: c.type, attribute: c.attribute, dateAssigned: c.dateAssigned,
          isRunning: c.isRunning, completedAt: c.completedAt, isPriority: c.isPriority
        );
        repo.saveActiveChallenge(u);
        return u;
      }
      return c;
    }).toList();
    
    state = state.copyWith(activeChallenges: updatedList, stats: newStats);
  }

  // --- TIMER LOGIC (SINGLE TASK RULE) ---

  void toggleTimer(String id, bool shouldRun) {
    final repo = ref.read(repositoryProvider);
    final updatedList = state.activeChallenges.map((c) {
      bool newRunningState = c.isRunning;

      if (c.id == id) {
        // Die gewählte Task togglen
        newRunningState = shouldRun;
      } else if (shouldRun && c.isRunning) {
        // SINGLE TASK RULE: Wenn eine neue Task startet (shouldRun=true), 
        // müssen alle anderen gestoppt werden.
        newRunningState = false;
      }

      if (newRunningState != c.isRunning) {
        final u = Challenge(
          id: c.id, templateId: c.templateId, name: c.name, logs: c.logs, target: c.target,
          unit: c.unit, type: c.type, attribute: c.attribute, dateAssigned: c.dateAssigned,
          isRunning: newRunningState, completedAt: c.completedAt, isPriority: c.isPriority
        );
        repo.saveActiveChallenge(u);
        return u;
      }
      return c;
    }).toList();

    state = state.copyWith(activeChallenges: updatedList);
  }

  // --- CORE PROGRESS LOGIC (THE HEARTBEAT) ---

  void updateProgress(String challengeId, double amount) {
    final repo = ref.read(repositoryProvider);
    final xpService = ref.read(xpServiceProvider);
    
    // Speichert die gesamte XP Veränderung für diesen Update-Schritt
    double xpChange = 0.0;

    final updatedList = state.activeChallenges.map((challenge) {
      if (challenge.id == challengeId) {
        // 1. Log erstellen (auch negative Werte für Slider-Rückgang erlauben)
        final newLog = ChallengeLog(timestamp: DateTime.now(), amount: amount);
        final updatedLogs = [...challenge.logs, newLog];

        // Status VOR dem Update merken
        final bool wasCompleted = challenge.isCompleted;

        // Temporäre Challenge bauen, um 'current' neu zu berechnen
        final tempChallenge = Challenge(
          id: challenge.id, templateId: challenge.templateId, name: challenge.name,
          logs: updatedLogs,
          target: challenge.target, unit: challenge.unit, type: challenge.type, attribute: challenge.attribute,
          dateAssigned: challenge.dateAssigned, isRunning: challenge.isRunning, completedAt: challenge.completedAt, isPriority: challenge.isPriority
        );

        // Status NACH dem Update prüfen
        // Toleranz für Floating Point Ungenauigkeiten
        final bool nowCompleted = tempChallenge.current >= tempChallenge.target - 0.01;

        // 2. Basis XP berechnen
        // Wir berechnen XP für den Betrag (amount). 
        // calculateXP gibt immer positiven Int zurück. Wir müssen das Vorzeichen beachten.
        int calculatedBaseXP = xpService.calculateXP(tempChallenge, amount);
        if (amount < 0) {
          xpChange -= calculatedBaseXP; // Abziehen
        } else {
          xpChange += calculatedBaseXP; // Addieren
        }

        // 3. Completion Bonus / Malus
        if (!wasCompleted && nowCompleted) {
          // Gerade fertig geworden -> Bonus drauf
          xpChange += xpService.calculateCompletionBonus(tempChallenge);
        } else if (wasCompleted && !nowCompleted) {
          // War fertig, jetzt nicht mehr (Slider zurück) -> Bonus weg
          xpChange -= xpService.calculateCompletionBonus(tempChallenge);
        }

        // 4. Finales Objekt erstellen
        final finalChallenge = Challenge(
          id: tempChallenge.id, templateId: tempChallenge.templateId, name: tempChallenge.name, logs: tempChallenge.logs, target: tempChallenge.target, unit: tempChallenge.unit, type: tempChallenge.type, attribute: tempChallenge.attribute, dateAssigned: tempChallenge.dateAssigned,
          // Timer stoppen wenn fertig
          isRunning: nowCompleted ? false : tempChallenge.isRunning, 
          // Datum setzen wenn fertig, sonst null
          completedAt: nowCompleted ? (tempChallenge.completedAt ?? DateTime.now()) : null, 
          isPriority: tempChallenge.isPriority
        );

        repo.saveActiveChallenge(finalChallenge);
        return finalChallenge;
      }
      return challenge;
    }).toList();

    // 5. Stats Update (Global & Attribut)
    PlayerStats newStats = state.stats;
    
    if (xpChange != 0) {
      final currentChallenge = state.activeChallenges.firstWhere((c) => c.id == challengeId);
      final attrType = currentChallenge.attribute;
      
      // Global XP Update
      double newGlobalXp = (newStats.currentXp + xpChange).clamp(0.0, double.infinity);
      
      // Global Level Neuberechnung passiert am besten basierend auf Attributen, 
      // aber hier machen wir es simpel über XP oder über Attribute:
      
      // Attribut XP Update
      StatAttribute updatedAttr;
      switch (attrType) {
        case ChallengeAttribute.strength:
          updatedAttr = xpService.applyXP(newStats.strength, xpChange);
          newStats = newStats.copyWith(strength: updatedAttr);
          break;
        case ChallengeAttribute.agility:
          updatedAttr = xpService.applyXP(newStats.agility, xpChange);
          newStats = newStats.copyWith(agility: updatedAttr);
          break;
        case ChallengeAttribute.intelligence:
          updatedAttr = xpService.applyXP(newStats.intelligence, xpChange);
          newStats = newStats.copyWith(intelligence: updatedAttr);
          break;
        case ChallengeAttribute.discipline:
          updatedAttr = xpService.applyXP(newStats.discipline, xpChange);
          newStats = newStats.copyWith(discipline: updatedAttr);
          break;
      }

      // Globale Werte neu berechnen (Level basiert auf Summe der Attribute)
      final newGlobalLevel = xpService.calculateGlobalLevel(newStats);
      final newMaxXp = xpService.calculateMaxXpForGlobalLevel(newGlobalLevel);

      newStats = newStats.copyWith(
        currentXp: newGlobalXp, // Wir nutzen hier die Summe als Anzeige oder separiert, je nach Design
        globalLevel: newGlobalLevel,
        maxXp: newMaxXp,
      );

      repo.savePlayerStats(newStats);
    }

    state = state.copyWith(activeChallenges: updatedList, stats: newStats);
  }

  // --- ROUTINE HELPERS ---

  void addRoutine(RoutineStack stack) {
    for (var template in stack.templates) {
      addChallenge(template);
    }
  }

  void updateRoutine(RoutineStack updatedStack) {
    final repo = ref.read(repositoryProvider);
    repo.saveRoutine(updatedStack);
    
    final updatedList = state.routines.map((r) => r.id == updatedStack.id ? updatedStack : r).toList();
    state = state.copyWith(routines: updatedList);
  }

  void createRoutine(String title, dynamic icon, List<ChallengeTemplate> selectedTemplates) {
    final repo = ref.read(repositoryProvider);
    int iconCode = (icon is int) ? icon : (icon as IconData).codePoint;
    final newStack = RoutineStack(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      iconCodePoint: iconCode,
      templates: selectedTemplates,
    );
    repo.saveRoutine(newStack);
    state = state.copyWith(routines: [...state.routines, newStack]);
  }

  void addNewTemplate(ChallengeTemplate template) {
    final repo = ref.read(repositoryProvider);
    repo.saveTemplate(template);
    state = state.copyWith(library: [...state.library, template]);
  }

  void updateTemplate(ChallengeTemplate updated) {
    final repo = ref.read(repositoryProvider);
    repo.saveTemplate(updated);
    final newLib = state.library.map((t) => t.id == updated.id ? updated : t).toList();
    state = state.copyWith(library: newLib);
  }
}

// Globaler Provider Access Point
final gameProvider = NotifierProvider<GameController, GameState>(GameController.new);