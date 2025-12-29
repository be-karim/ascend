// lib/models/enums.dart

enum ChallengeType { 
  reps,       // Wiederholungen (z.B. Pushups)
  time,       // Zeitbasiert (z.B. Meditation)
  hydration,  // Flüssigkeit (z.B. Wasser trinken)
  boolean     // Checkbox (z.B. Bett machen)
}

enum ChallengeAttribute { 
  strength,     // Rot
  agility,      // Blau
  intelligence, // Weiß
  discipline    // Grün
}

enum Difficulty { 
  iron, 
  bronze, 
  silver, 
  gold, 
  ascended 
}