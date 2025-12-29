import 'package:ascend/models/template.dart';
import 'package:ascend/models/enums.dart';

// Interface (optional, aber sauberer)
abstract class ChallengesRepository {
  Future<List<ChallengeTemplate>> fetchTemplates();
  Future<void> saveTemplate(ChallengeTemplate template);
}

// Mock Implementierung
class MockChallengesRepository implements ChallengesRepository {
  
  // Simuliert Datenbank
  final List<ChallengeTemplate> _mockDb = [
    ChallengeTemplate(id: 't1', title: 'Push-Ups', description: 'Chest & Triceps', defaultTarget: 50, unit: 'reps', type: ChallengeType.reps, attribute: ChallengeAttribute.strength),
    ChallengeTemplate(id: 't2', title: 'Hydration', description: 'Daily water', defaultTarget: 3000, unit: 'ml', type: ChallengeType.hydration, attribute: ChallengeAttribute.discipline),
    // ... mehr
  ];

  @override
  Future<List<ChallengeTemplate>> fetchTemplates() async {
    // Simuliert Netzwerk-Verzögerung
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockDb;
  }

  @override
  Future<void> saveTemplate(ChallengeTemplate template) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockDb.add(template);
  }
}