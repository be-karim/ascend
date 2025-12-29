import 'dart:math';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/stats.dart';

class XPService {
  // Grundwert für XP pro Challenge (bevor Multiplikatoren)
  static const int BASE_ACTION_XP = 10;
  
  // Exponent für die Level-Kurve (höher = schwieriger im Lategame)
  static const double LEVEL_EXPONENT = 1.6;
  static const int BASE_LEVEL_XP = 100;

  /// Berechnet XP basierend auf Challenge-Typ und Menge
  int calculateXP(Challenge challenge, double amountDone) {
    if (amountDone <= 0) return 0;

    double multiplier = 1.0;
    
    // Balancing der Einheiten
    switch (challenge.type) {
      case ChallengeType.time:
        // 1 Minute = 1.0 Basispunkte (z.B.)
        multiplier = 1.0; 
        break;
      case ChallengeType.hydration:
        // 100ml = 1 Punkt
        multiplier = 0.01; 
        break;
      case ChallengeType.reps:
        // 1 Rep = 0.5 Punkte (hängt stark von der Übung ab, hier pauschal)
        multiplier = 0.5; 
        break;
      case ChallengeType.boolean:
        // Checkbox = Fester Wert
        return 50; 
    }

    // Ergebnis: amount * multiplier * difficulty_bonus (optional)
    int xp = (amountDone * multiplier * BASE_ACTION_XP).floor();
    return max(1, xp); // Mindestens 1 XP
  }

  int calculateCompletionBonus(Challenge challenge) {
    // Großer Bonus für das Abschließen
    return 50;
  }

  /// Prüft auf Level-Up und gibt das aktualisierte Attribut zurück
  StatAttribute applyXP(StatAttribute stat, int xpAmount) {
    int newCurrent = stat.currentXp + xpAmount;
    int newLevel = stat.level;
    int newMax = stat.maxXp;
    int newTier = stat.tier;

    // Level-Up Schleife (falls man so viel XP bekommt, dass man mehrere Level aufsteigt)
    while (newCurrent >= newMax) {
      newCurrent -= newMax;
      newLevel++;

      // Tier Ascension Check (Soft Cap bei Level 100)
      if (newLevel > 100) {
        newLevel = 1;
        newTier++;
        // Hier könnte man den Nutzer benachrichtigen (Return-Typ anpassen oder Event feuern)
      }

      // Neue Max XP berechnen für das nächste Level
      // Formel: 100 * (Level ^ 1.6) * (1.2 ^ Tier) -> Tier macht es auch schwerer
      newMax = (BASE_LEVEL_XP * pow(newLevel, LEVEL_EXPONENT) * pow(1.1, newTier)).floor();
    }

    return stat.copyWith(
      level: newLevel,
      currentXp: newCurrent,
      maxXp: newMax,
      tier: newTier,
    );
  }
  
  /// Helper um den "Global Level" zu berechnen (Durchschnitt aller Stats + Tiers)
  int calculateGlobalLevel(PlayerStats stats) {
    int totalLevels = stats.strength.level + stats.agility.level + stats.intelligence.level + stats.discipline.level;
    int totalTiers = stats.strength.tier + stats.agility.tier + stats.intelligence.tier + stats.discipline.tier;
    
    // Ein Tier ist wie 100 virtuelle Level wert
    return (totalLevels + (totalTiers * 100)) ~/ 4;
  }
}