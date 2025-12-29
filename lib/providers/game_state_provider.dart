import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/models/stats.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/history.dart';
import 'package:ascend/models/challenge_log.dart'; // Wichtig für die Logs
import 'package:ascend/models/enums.dart';
import 'package:ascend/repositories/hive_challenges_repository.dart';
import 'package:ascend/services/xp_service.dart';

// 1. REPOSITORY PROVIDER
final repositoryProvider = Provider<HiveChallengesRepository>((ref) {
  return HiveChallengesRepository();
});

// 2. XP SERVICE PROVIDER
final xpServiceProvider = Provider<XPService>((ref) {
  return XPService();
});

// 3. GAME STATE
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

// 4. THE NOTIFIER
class GameController extends Notifier<GameState> {
  
  @override
  GameState build() {
    // Startet die Initialisierung asynchron
    Future.microtask(() => _init());
    
    return GameState(
      stats: const PlayerStats(
        strength: StatAttribute(), 
        agility: StatAttribute(), 
        intelligence: StatAttribute(), 
        discipline: StatAttribute()
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
    await repo.init(); // Wichtig: Hive Boxen öffnen

    // Check auf neuen Tag (Daily Reset)
    await _performDailyResetIfNeeded(repo);

    // Daten laden
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
      isLoading: false
    );
  }

  // --- TIME ENGINE: DAILY RESET ---

  Future<void> _performDailyResetIfNeeded(HiveChallengesRepository repo) async {
    final lastOpened = repo.getLastOpenedDate();
    final now = DateTime.now();
    
    // Erster Start der App
    if (lastOpened == null) {
      await repo.setLastOpenedDate(now);
      return;
    }

    // Wenn "heute" ein anderer Tag ist als "zuletzt geöffnet"
    if (!_isSameDay(lastOpened, now)) {
      // 1. Archivieren: Wir speichern den gestrigen Stand
      final active = await repo.fetchActiveChallenges();
      final completed = active.where((c) => c.isCompleted).toList();
      
      if (completed.isNotEmpty) {
        final historyEntry = HistoryEntry(
          date: lastOpened,
          completedCount: completed.length,
          completedChallengeNames: completed.map((c) => c.name).toList(),
          // Optional: XP Summe berechnen
        );
        await repo.saveHistoryEntry(historyEntry);
      }

      // 2. Reset für heute: Logs und Fortschritt leeren
      // Anmerkung: Wenn du Aufgaben hast, die über mehrere Tage gehen sollen, 
      // müsste man hier filtern. Für "Daily Challenges" wird resettet.
      for (var challenge in active) {
        // Wir erstellen eine "frische" Kopie ohne Logs
        final resetChallenge = Challenge(
          id: challenge.id,
          templateId: challenge.templateId,
          name: challenge.name,
          logs: [], // Leere Logs = 0 Fortschritt
          target: challenge.target,
          unit: challenge.unit,
          type: challenge.type,
          attribute: challenge.attribute,
          dateAssigned: DateTime.now(), // Neues Datum
          isRunning: false,
          completedAt: null,
        );
        await repo.saveActiveChallenge(resetChallenge);
      }

      // 3. Update Status
      await repo.setLastOpenedDate(now);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // --- ACTIONS: EXECUTE ---

  void addChallenge(ChallengeTemplate template) {
    final repo = ref.read(repositoryProvider);

    final newChallenge = Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString() + template.id,
      templateId: template.id,
      name: template.title,
      logs: [], // Startet leer
      target: template.defaultTarget,
      unit: template.unit,
      type: template.type,
      attribute: template.attribute,
      dateAssigned: DateTime.now(),
    );

    repo.saveActiveChallenge(newChallenge);

    state = state.copyWith(
      activeChallenges: [...state.activeChallenges, newChallenge],
    );
  }

  void removeChallenge(String id) {
    final repo = ref.read(repositoryProvider);
    repo.deleteActiveChallenge(id);
    state = state.copyWith(
      activeChallenges: state.activeChallenges.where((c) => c.id != id).toList(),
    );
  }

  void updateChallengeTarget(String id, double newTarget) {
    final repo = ref.read(repositoryProvider);
    
    // Da Challenge immutable sein sollte (best practice), erstellen wir eine Kopie
    // Da wir aber keinen copyWith im Model für alles haben, hier manuell:
    final updatedList = state.activeChallenges.map((c) {
      if (c.id == id) {
        // Wir modifizieren das existierende Objekt nur weil target kein 'final' feld ist
        // Wenn du 'target' auch final gemacht hast, musst du hier eine neue Instanz erzeugen.
        c.target = newTarget; 
        repo.saveActiveChallenge(c);
      }
      return c;
    }).toList();
    
    state = state.copyWith(activeChallenges: updatedList);
  }

  void toggleTimer(String id, bool isRunning) {
    final repo = ref.read(repositoryProvider);
    
    // Auch hier: eigentlich neue Instanz erstellen für sauberes State Management
    final updatedList = state.activeChallenges.map((c) {
      if (c.id == id) {
        c.isRunning = isRunning;
        repo.saveActiveChallenge(c);
      }
      return c;
    }).toList();

    state = state.copyWith(activeChallenges: updatedList);
  }

  /// Das Herzstück: Fortschritt loggen
  void updateProgress(String challengeId, double amount) {
    final repo = ref.read(repositoryProvider);
    final xpService = ref.read(xpServiceProvider);
    int xpGained = 0;

    final updatedList = state.activeChallenges.map((challenge) {
      if (challenge.id == challengeId) {
        // Wenn schon fertig und positive Eingabe, nichts tun (außer Overfill gewünscht)
        if (challenge.isCompleted && amount > 0) return challenge;

        final bool wasCompleted = challenge.isCompleted;

        // 1. Neuen Log Eintrag erstellen
        final newLog = ChallengeLog(timestamp: DateTime.now(), amount: amount);
        final updatedLogs = [...challenge.logs, newLog];

        // 2. Neue Challenge Instanz mit aktualisierten Logs
        // Wir müssen hier alle Felder kopieren
        final updatedChallenge = Challenge(
          id: challenge.id,
          templateId: challenge.templateId,
          name: challenge.name,
          logs: updatedLogs, // <--- Die neuen Logs
          target: challenge.target,
          unit: challenge.unit,
          type: challenge.type,
          attribute: challenge.attribute,
          dateAssigned: challenge.dateAssigned,
          isRunning: challenge.isRunning,
          completedAt: challenge.completedAt,
        );

        final bool nowCompleted = updatedChallenge.isCompleted;

        // 3. Completion Check
        if (!wasCompleted && nowCompleted) {
          xpGained += xpService.calculateCompletionBonus(updatedChallenge);
          
          // Timestamp für Completion setzen (Erfordert erneute Kopie, da final)
          final completedChallenge = Challenge(
            id: updatedChallenge.id,
            templateId: updatedChallenge.templateId,
            name: updatedChallenge.name,
            logs: updatedLogs,
            target: updatedChallenge.target,
            unit: updatedChallenge.unit,
            type: updatedChallenge.type,
            attribute: updatedChallenge.attribute,
            dateAssigned: updatedChallenge.dateAssigned,
            isRunning: false, // Timer stoppen bei Abschluss
            completedAt: DateTime.now(),
          );
          
          repo.saveActiveChallenge(completedChallenge);
          return completedChallenge;
        }

        // Standard XP für die Aktion
        xpGained += xpService.calculateXP(updatedChallenge, amount);
        
        repo.saveActiveChallenge(updatedChallenge);
        return updatedChallenge;
      }
      return challenge;
    }).toList();

    // 4. Stats Update wenn XP gewonnen
    PlayerStats newStats = state.stats;
    if (xpGained > 0) {
      // Finde das Attribut der Challenge heraus
      final currentChallenge = state.activeChallenges.firstWhere((c) => c.id == challengeId);
      final attr = currentChallenge.attribute;
      StatAttribute updatedAttr;

      switch (attr) {
        case ChallengeAttribute.strength:
          updatedAttr = xpService.applyXP(newStats.strength, xpGained);
          newStats = newStats.copyWith(strength: updatedAttr);
          break;
        case ChallengeAttribute.agility:
          updatedAttr = xpService.applyXP(newStats.agility, xpGained);
          newStats = newStats.copyWith(agility: updatedAttr);
          break;
        case ChallengeAttribute.intelligence:
          updatedAttr = xpService.applyXP(newStats.intelligence, xpGained);
          newStats = newStats.copyWith(intelligence: updatedAttr);
          break;
        case ChallengeAttribute.discipline:
          updatedAttr = xpService.applyXP(newStats.discipline, xpGained);
          newStats = newStats.copyWith(discipline: updatedAttr);
          break;
      }

      // Global Level und neues MaxXP berechnen
      final newGlobalLevel = xpService.calculateGlobalLevel(newStats);
      final newMaxXp = xpService.calculateMaxXpForGlobalLevel(newGlobalLevel);

      newStats = newStats.copyWith(
        currentXp: newStats.currentXp + xpGained,
        globalLevel: newGlobalLevel,
        maxXp: newMaxXp,
      );

      repo.savePlayerStats(newStats);
    }

    state = state.copyWith(
      activeChallenges: updatedList,
      stats: newStats,
    );
  }

  // --- ACTIONS: PLAN ---

  void addRoutine(RoutineStack stack) {
    for (var template in stack.templates) {
      addChallenge(template);
    }
  }

  void createRoutine(String title, dynamic icon, List<ChallengeTemplate> selectedTemplates) {
    final repo = ref.read(repositoryProvider);

    int iconCode;
    if (icon is int) {
      iconCode = icon;
    } else {
      try {
        iconCode = (icon).codePoint;
      } catch (e) {
        iconCode = 0xe539; // Default Icon
      }
    }

    final newStack = RoutineStack(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      iconCodePoint: iconCode, 
      templates: selectedTemplates,
    );
    
    repo.saveRoutine(newStack);

    state = state.copyWith(
      routines: [...state.routines, newStack],
    );
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

// 5. GLOBAL PROVIDER
final gameProvider = NotifierProvider<GameController, GameState>(GameController.new);