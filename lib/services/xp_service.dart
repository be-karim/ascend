import 'package:ascend/models/enums.dart';
import 'package:ascend/models/challenge.dart';

class XPService {
  // Konfiguration: Wie viel XP gibt es "grundsätzlich"?
  static const int BASE_XP_REWARD = 20;

  /// Berechnet die XP für einen Fortschritt
  /// [challenge]: Die Challenge, um die es geht
  /// [amountDone]: Wie viel wurde gerade hinzugefügt (z.B. 10 Reps)
  int calculateXP(Challenge challenge, double amountDone) {
    if (amountDone <= 0) return 0;

    // Aktuell: Flat Rate, damit jede Challenge gleich viel wert ist.
    // Wir geben XP proportional zum Fortschritt der Challenge.
    // Wenn Challenge = 50 Reps und 20 XP wert ist:
    // 1 Rep = 0.4 XP (gerundet)
    
    // Einfacher Ansatz für den Anfang: 
    // Jede Einheit bringt minimal Punkte, Completion bringt den Rest.
    
    // VORLÄUFIGE LOGIK (wie besprochen):
    // Man bekommt XP basierend auf der 'Schwere'? 
    // Nein, aktuell "Gleich viel XP".
    
    // Wir geben 1 XP pro Interaktion, aber cappen es nicht?
    // Oder wir berechnen es basierend auf dem Typ:
    
    int xp = 0;

    switch (challenge.type) {
      case ChallengeType.time:
        // Zeit: 1 XP pro Minute
        xp = amountDone.toInt(); 
        break;
      case ChallengeType.hydration:
        // Wasser: 1 XP pro 250ml (Beispiel)
        xp = (amountDone / 250).floor();
        break;
      case ChallengeType.reps:
      default:
        // Reps: 1 XP pro 5 Reps (Beispiel)
        xp = (amountDone / 5).floor();
        // Fallback: Mindestens 1 XP bei Interaktion
        if (xp == 0 && amountDone > 0) xp = 1;
        break;
    }

    return xp;
  }

  /// Berechnet den Bonus bei Abschluss einer Challenge
  int calculateCompletionBonus(Challenge challenge) {
    // Hier können wir später deine Logik einbauen:
    // "Wenn Target > 100 Reps -> 30 XP, sonst 20 XP"
    
    double target = challenge.target;
    
    // Beispiel für deine spätere Skalierung (auskommentiert):
    /*
    if (challenge.type == ChallengeType.reps) {
      if (target >= 200) return 30;
      if (target >= 100) return 20;
      return 10;
    }
    */

    return BASE_XP_REWARD; // Aktuell pauschal 20 XP Bonus
  }
}