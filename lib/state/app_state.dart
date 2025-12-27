import 'package:flutter/material.dart';
import 'package:ascend/models/models.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Use the global mockPlayer for now
  PlayerStats get player => mockPlayer;

  // Challenges State
  List<Challenge> challenges = [
    Challenge(
      id: '1',
      name: 'Push-Ups',
      current: 45,
      target: 100,
      unit: 'reps',
      type: ChallengeType.reps,
      attribute: ChallengeAttribute.strength,
    ),
    Challenge(
      id: '2',
      name: 'Water Intake',
      current: 1250,
      target: 3000,
      unit: 'ml',
      type: ChallengeType.hydration,
      attribute: ChallengeAttribute.discipline,
    ),
    Challenge(
      id: '3',
      name: 'Meditation',
      current: 0,
      target: 15,
      unit: 'min',
      type: ChallengeType.time,
      attribute: ChallengeAttribute.discipline,
    ),
  ];

  // Logic
  void addChallenge(Challenge c) {
    challenges.add(c);
    notifyListeners();
  }

  void removeChallenge(String id) {
    challenges.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void updateChallengeProgress(Challenge c, double amount) {
    if (c.isCompleted && amount > 0) return;
    
    // Update Value
    c.current = (c.current + amount).clamp(0.0, c.target);
    
    // Add XP to player if progress made
    if (amount > 0) {
      _addXpToPlayer(c, amount);
    }
    
    notifyListeners();
  }

  void _addXpToPlayer(Challenge task, double amountOfProgress) {
      int xpAmount = 1;
      if (task.type == ChallengeType.hydration) {
        xpAmount = (amountOfProgress / 100).ceil(); 
      } else if (task.type == ChallengeType.time) {
        xpAmount = amountOfProgress.toInt() * 2; 
      } else {
        xpAmount = amountOfProgress.toInt(); 
      }
      
      if (xpAmount <= 0) return;

      StatAttribute? stat;
      switch (task.attribute) {
        case ChallengeAttribute.strength: stat = player.strength; break;
        case ChallengeAttribute.agility: stat = player.agility; break;
        case ChallengeAttribute.intelligence: stat = player.intelligence; break;
        case ChallengeAttribute.discipline: stat = player.discipline; break;
      }
      
      stat.addXp(xpAmount);
      player.currentXp += xpAmount;
      // We don't notify listeners here specifically for player stats changes usually, 
      // but since everything is rebuilt on notifyListeners from AppState in this simple arch, it works.
  }
  
  // Helpers for Home Screen
  Challenge? get priorityTarget {
    // Return first active incomplete challenge or just first.
    try {
      return challenges.firstWhere((c) => !c.isCompleted, orElse: () => challenges.first);
    } catch (e) {
      return null;
    }
  }
}
