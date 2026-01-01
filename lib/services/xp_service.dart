import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/stats.dart';

class XPService {
  // --- BALANCING KONSTANTEN ---
  static const double baseXPPerUnit = 1.0;
  static const int completionBonus = 100;
  
  // Schwierigkeits-Multiplikatoren
  static const double multStrength = 1.0;
  static const double multAgility = 1.0;
  static const double multIntel = 1.2; // Intelligence gibt mehr XP
  static const double multDiscipline = 1.1;

  /// Berechnet die XP für einen bestimmten Fortschritts-Schritt (Delta).
  /// Gibt immer einen positiven Wert zurück. Ob addiert oder subtrahiert wird,
  /// entscheidet der Controller basierend auf der Slider-Richtung.
  int calculateXP(Challenge challenge, double amount) {
    double absAmount = amount.abs();
    double xpFactor = 1.0;

    switch (challenge.type) {
      case ChallengeType.reps:
        xpFactor = 0.5; // Reps sind schnell gemacht
        break;
      case ChallengeType.time:
        xpFactor = 2.0; // Zeit ist wertvoll (pro Minute)
        break;
      case ChallengeType.hydration:
        xpFactor = 0.05; // Milliliter sind kleine Einheiten
        break;
      case ChallengeType.boolean:
        xpFactor = 50.0; // Einmalige Aktion
        break;
    }

    // Attribut-Bonus anwenden
    switch (challenge.attribute) {
      case ChallengeAttribute.strength: xpFactor *= multStrength; break;
      case ChallengeAttribute.agility: xpFactor *= multAgility; break;
      case ChallengeAttribute.intelligence: xpFactor *= multIntel; break;
      case ChallengeAttribute.discipline: xpFactor *= multDiscipline; break;
    }

    return (absAmount * xpFactor).ceil();
  }

  /// Gibt den fixen Bonus für das Abschließen einer Challenge zurück.
  int calculateCompletionBonus(Challenge challenge) {
    // Man könnte hier noch Logik einbauen, dass schwere Challenges mehr Bonus geben.
    return completionBonus;
  }

  /// Wendet XP auf ein Attribut an und handhabt Level Up / Level Down.
  StatAttribute applyXP(StatAttribute attr, double xpChange) {
    double newCurrent = attr.currentXp + xpChange;
    int newLevel = attr.level;
    double newMax = attr.maxXp;

    // --- LEVEL UP LOGIK ---
    while (newCurrent >= newMax) {
      newCurrent -= newMax;
      newLevel++;
      // Kurve: Jedes Level braucht 20% mehr XP als das vorherige
      newMax *= 1.2; 
    }

    // --- LEVEL DOWN LOGIK (Strafe) ---
    while (newCurrent < 0) {
      if (newLevel > 1) {
        newLevel--;
        newMax /= 1.2; // Vorheriges Max wiederherstellen
        newCurrent += newMax; // XP vom vorherigen Level "auffüllen"
      } else {
        // Wir sind Level 1 und gehen unter 0 -> Cap bei 0
        newCurrent = 0;
        break;
      }
    }

    return attr.copyWith(
      level: newLevel,
      currentXp: newCurrent,
      maxXp: newMax,
    );
  }

  /// Berechnet das globale Level basierend auf den 4 Attributen (Durchschnitt).
  int calculateGlobalLevel(PlayerStats stats) {
    final sum = stats.strength.level + 
                stats.agility.level + 
                stats.intelligence.level + 
                stats.discipline.level;
    return (sum / 4).floor();
  }

  /// Berechnet Max XP für das globale Level (für die Progress Bar im Header oder Profil).
  double calculateMaxXpForGlobalLevel(int level) {
    return 1000.0 * (1 + (level * 0.1));
  }
}