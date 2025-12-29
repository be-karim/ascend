import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/models/stats.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/repositories/hive_challenges_repository.dart'; // Stelle sicher, dass diese Datei existiert
import 'package:ascend/services/xp_service.dart';

// 1. REPOSITORY PROVIDER
// Wir nutzen hier direkt das HiveRepository, um Zugriff auf alle Methoden zu haben.
final repositoryProvider = Provider<HiveChallengesRepository>((ref) {
  return HiveChallengesRepository();
});

// 2. XP SERVICE PROVIDER
final xpServiceProvider = Provider<XPService>((ref) {
  return XPService();
});

// 3. GAME STATE
// Hält den aktuellen Zustand der App (Statistiken, Aktive Aufgaben, Bibliothek, Routinen)
class GameState {
  final PlayerStats stats;
  final List<Challenge> activeChallenges;
  final List<ChallengeTemplate> library;
  final List<RoutineStack> routines;
  final bool isLoading;

  GameState({
    required this.stats,
    required this.activeChallenges,
    required this.library,
    required this.routines,
    this.isLoading = false,
  });

  // Helper zum Kopieren des States (da Riverpod State immutable ist)
  GameState copyWith({
    PlayerStats? stats,
    List<Challenge>? activeChallenges,
    List<ChallengeTemplate>? library,
    List<RoutineStack>? routines,
    bool? isLoading,
  }) {
    return GameState(
      stats: stats ?? this.stats,
      activeChallenges: activeChallenges ?? this.activeChallenges,
      library: library ?? this.library,
      routines: routines ?? this.routines,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 4. THE NOTIFIER (Logik-Zentrale)
class GameController extends Notifier<GameState> {
  
  @override
  GameState build() {
    // Initialisierung starten (Microtask, damit es nicht den Build blockiert)
    Future.microtask(() => _init());
    
    // Start-Zustand (leer/default)
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
      isLoading: true,
    );
  }

  /// Lädt alle Daten aus der lokalen Hive-Datenbank
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    
    final repo = ref.read(repositoryProvider);
    
    // WICHTIG: Datenbank initialisieren
    await repo.init(); 

    // Daten abrufen
    final templates = await repo.fetchTemplates();
    final routines = await repo.fetchRoutines();
    final active = await repo.fetchActiveChallenges();
    final stats = await repo.fetchPlayerStats();

    // State aktualisieren
    state = state.copyWith(
      library: templates,
      routines: routines,
      activeChallenges: active,
      stats: stats,
      isLoading: false
    );
  }

  // --- DAILY LOG ACTIONS (Ausführung) ---

  /// Fügt eine einzelne Challenge zum heutigen Tag hinzu
  void addChallenge(ChallengeTemplate template) {
    final repo = ref.read(repositoryProvider);

    final newChallenge = Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString() + template.id, // Einzigartige ID
      templateId: template.id,
      name: template.title,
      current: 0,
      target: template.defaultTarget,
      unit: template.unit,
      type: template.type,
      attribute: template.attribute,
      dateAssigned: DateTime.now(),
    );

    // 1. Speichern
    repo.saveActiveChallenge(newChallenge);

    // 2. State Update
    state = state.copyWith(
      activeChallenges: [...state.activeChallenges, newChallenge],
    );
  }

  /// Entfernt eine Challenge aus dem Daily Log
  void removeChallenge(String id) {
    final repo = ref.read(repositoryProvider);
    
    // 1. Löschen
    repo.deleteActiveChallenge(id);

    // 2. State Update
    state = state.copyWith(
      activeChallenges: state.activeChallenges.where((c) => c.id != id).toList(),
    );
  }

  /// Ändert das Ziel einer aktiven Challenge (z.B. Edit Dialog)
  void updateChallengeTarget(String id, double newTarget) {
    final repo = ref.read(repositoryProvider);

    // Neue Liste erstellen mit aktualisierter Challenge
    final updatedList = state.activeChallenges.map((c) {
      if (c.id == id) {
        c.target = newTarget; // Mutable update (vereinfacht)
        repo.saveActiveChallenge(c); // Änderungen speichern
      }
      return c;
    }).toList();
    
    state = state.copyWith(activeChallenges: updatedList);
  }

  /// Startet/Stoppt den Timer für eine Challenge
  void toggleTimer(String id, bool isRunning) {
    final repo = ref.read(repositoryProvider);

    final updatedList = state.activeChallenges.map((c) {
      if (c.id == id) {
        c.isRunning = isRunning;
        repo.saveActiveChallenge(c); // Speichern, falls App geschlossen wird
      }
      return c;
    }).toList();

    state = state.copyWith(activeChallenges: updatedList);
  }

  /// Aktualisiert den Fortschritt (Reps, Zeit, etc.) und berechnet XP
  void updateProgress(String challengeId, double amount) {
    final repo = ref.read(repositoryProvider);
    final xpService = ref.read(xpServiceProvider);
    int xpGained = 0;

    final updatedList = state.activeChallenges.map((challenge) {
      if (challenge.id == challengeId) {
        // Wenn schon fertig und positive Eingabe, nichts tun (außer du willst Overfill erlauben)
        if (challenge.isCompleted && amount > 0) return challenge;

        final bool wasCompleted = challenge.isCompleted;
        
        // Wert updaten
        challenge.current = (challenge.current + amount).clamp(0.0, challenge.target);
        
        final bool nowCompleted = challenge.isCompleted;

        // XP Berechnen
        xpGained += xpService.calculateXP(challenge, amount);
        
        // Bonus XP bei Abschluss
        if (!wasCompleted && nowCompleted) {
          xpGained += xpService.calculateCompletionBonus(challenge);
        }
        
        // Speichern
        repo.saveActiveChallenge(challenge);
        
        return challenge;
      }
      return challenge;
    }).toList();

    // Player Stats aktualisieren, falls XP gewonnen wurden
    PlayerStats newStats = state.stats;
    
    if (xpGained > 0) {
      // Wir müssen wissen, welches Attribut betroffen ist.
      // Da wir in 'updatedList' die Challenge haben, holen wir sie uns kurz.
      final currentChallenge = state.activeChallenges.firstWhere((c) => c.id == challengeId);
      final attr = currentChallenge.attribute;

      StatAttribute updatedAttr;

      // 1. Das richtige Attribut auswählen und XP anwenden
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

      // 2. Global Level neu berechnen
      final newGlobalLevel = xpService.calculateGlobalLevel(newStats);
      
      // 3. Globale XP erhöhen (für Highscore/Leaderboard später)
      newStats = newStats.copyWith(
        currentXp: newStats.currentXp + xpGained,
        globalLevel: newGlobalLevel
      );

      // 4. Speichern
      ref.read(repositoryProvider).savePlayerStats(newStats);
    }

    state = state.copyWith(
      activeChallenges: updatedList,
      stats: newStats,
    );
  }

  // --- ROUTINE & LIBRARY ACTIONS (Planung) ---

  /// Fügt eine ganze Routine zum Daily Log hinzu
  void addRoutine(RoutineStack stack) {
    for (var template in stack.templates) {
      addChallenge(template);
    }
  }

  /// Erstellt eine neue Routine und speichert sie
  void createRoutine(String title, dynamic icon, List<ChallengeTemplate> selectedTemplates) {
    final repo = ref.read(repositoryProvider);

    // Icon handling: Wir erwarten einen int (codePoint) für die DB
    int iconCode;
    if (icon is int) {
      iconCode = icon;
    } else {
      // Fallback/Konvertierung falls IconData übergeben wird
      // Dies setzt voraus, dass IconData übergeben wurde (was im UI passiert)
      // Wir nutzen hier einen Standard-Wert oder extrahieren den codePoint
      try {
        iconCode = (icon).codePoint; 
      } catch (e) {
        iconCode = 0xe539; // Default: layers icon
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

  /// Fügt ein neues Template zur Bibliothek hinzu
  void addNewTemplate(ChallengeTemplate template) {
    final repo = ref.read(repositoryProvider);
    
    repo.saveTemplate(template);

    state = state.copyWith(
      library: [...state.library, template],
    );
  }

  /// Aktualisiert ein existierendes Template
  void updateTemplate(ChallengeTemplate updated) {
    final repo = ref.read(repositoryProvider);
    
    repo.saveTemplate(updated);

    final newLib = state.library.map((t) => t.id == updated.id ? updated : t).toList();
    state = state.copyWith(library: newLib);
  }
}

// 5. THE GLOBAL PROVIDER (Zugriffspunkt für die UI)
final gameProvider = NotifierProvider<GameController, GameState>(GameController.new);