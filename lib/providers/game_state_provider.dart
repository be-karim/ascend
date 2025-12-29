import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/models/stats.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/repositories/challenges_repository.dart';
import 'package:ascend/services/xp_service.dart';

// 1. REPOSITORY PROVIDER
final repositoryProvider = Provider<ChallengesRepository>((ref) {
  return MockChallengesRepository();
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
  final List<RoutineStack> routines; // This property was missing in your error log
  final bool isLoading;

  GameState({
    required this.stats,
    required this.activeChallenges,
    required this.library,
    required this.routines,
    this.isLoading = false,
  });

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

// 4. THE NOTIFIER
class GameController extends Notifier<GameState> {
  
  @override
  GameState build() {
    // Trigger initial load
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
      isLoading: true,
    );
  }

  Future<void> _init() async {
    final repo = ref.read(repositoryProvider);
    final templates = await repo.fetchTemplates();
    
    // Mock Routines (Ideally fetch from Repo)
    // Using integer codepoints for Icons since IconData isn't directly serializable in some contexts, 
    // but here we just pass the object if using in-memory.
    // Assuming RoutineStack accepts IconData directly based on previous models.
    /* Note: If you encounter errors with IconData here, ensure your RoutineStack model 
       imports flutter/widgets.dart and uses IconData type.
    */
    
    // Simple Mock Setup
    final routines = <RoutineStack>[]; // Empty start, or populate if you have mock data logic

    state = state.copyWith(
      library: templates,
      routines: routines,
      isLoading: false
    );
  }

  // --- DAILY LOG ACTIONS ---

  void addChallenge(ChallengeTemplate template) {
    final newChallenge = Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      templateId: template.id,
      name: template.title,
      current: 0,
      target: template.defaultTarget,
      unit: template.unit,
      type: template.type,
      attribute: template.attribute,
      dateAssigned: DateTime.now(),
    );

    state = state.copyWith(
      activeChallenges: [...state.activeChallenges, newChallenge],
    );
  }

  void removeChallenge(String id) {
    state = state.copyWith(
      activeChallenges: state.activeChallenges.where((c) => c.id != id).toList(),
    );
  }

  void updateChallengeTarget(String id, double newTarget) {
    // Note: Since Challenge isn't fully immutable in our quick model (current/target are mutable),
    // we force a rebuild by creating a new list. In a stricter setup, use copyWith on Challenge.
    final updatedList = state.activeChallenges.map((c) {
      if (c.id == id) {
        c.target = newTarget; 
      }
      return c;
    }).toList();
    
    state = state.copyWith(activeChallenges: updatedList);
  }

  void toggleTimer(String id, bool isRunning) {
    final updatedList = state.activeChallenges.map((c) {
      if (c.id == id) {
        c.isRunning = isRunning;
      }
      return c;
    }).toList();

    state = state.copyWith(activeChallenges: updatedList);
  }

  void updateProgress(String challengeId, double amount) {
    final xpService = ref.read(xpServiceProvider);
    int xpGained = 0;

    final updatedList = state.activeChallenges.map((challenge) {
      if (challenge.id == challengeId) {
        if (challenge.isCompleted && amount > 0) return challenge;

        final bool wasCompleted = challenge.isCompleted;
        challenge.current = (challenge.current + amount).clamp(0.0, challenge.target);
        final bool nowCompleted = challenge.isCompleted;

        // XP Calc
        xpGained += xpService.calculateXP(challenge, amount);
        if (!wasCompleted && nowCompleted) {
          xpGained += xpService.calculateCompletionBonus(challenge);
        }
        
        return challenge;
      }
      return challenge;
    }).toList();

    // Update Stats if needed
    PlayerStats newStats = state.stats;
    if (xpGained > 0) {
      newStats = state.stats.copyWith(
        currentXp: state.stats.currentXp + xpGained
      );
    }

    state = state.copyWith(
      activeChallenges: updatedList,
      stats: newStats,
    );
  }

  // --- ROUTINE & LIBRARY ACTIONS ---

  void addRoutine(RoutineStack stack) {
    for (var template in stack.templates) {
      addChallenge(template);
    }
  }

  void createRoutine(String title, dynamic icon, List<ChallengeTemplate> selectedTemplates) {
    // Assuming RoutineStack expects IconData. If 'icon' is dynamic, cast it.
    // If your model uses int/codePoint, adjust accordingly.
    final newStack = RoutineStack(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      icon: icon, 
      templates: selectedTemplates,
    );
    
    state = state.copyWith(
      routines: [...state.routines, newStack],
    );
  }

  void addNewTemplate(ChallengeTemplate template) {
    state = state.copyWith(
      library: [...state.library, template],
    );
    // Future: ref.read(repositoryProvider).saveTemplate(template);
  }

  void updateTemplate(ChallengeTemplate updated) {
    final newLib = state.library.map((t) => t.id == updated.id ? updated : t).toList();
    state = state.copyWith(library: newLib);
  }
}

// 5. THE GLOBAL PROVIDER
final gameProvider = NotifierProvider<GameController, GameState>(GameController.new);