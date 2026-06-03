// Personalized wellness recommendations via rule-based expert system.

import '../models/ai_suggestion_model.dart';
import 'health_context_builder.dart';
import 'recommendation/recommendation_rules.dart';
import 'recommendation/suggestion_ranker.dart';

class AiService {
  final _contextBuilder = HealthContextBuilder();
  final _rules = RecommendationRules();
  final _ranker = SuggestionRanker();

  Future<List<AiSuggestionModel>> generateSuggestions(String userId) async {
    final context = await _contextBuilder.build(userId);
    final candidates = _rules.evaluateAll(context);
    final ranked = _ranker.rankAndCap(candidates, maxCount: 8, minCount: 3);

    if (ranked.isNotEmpty) return ranked;

    return [
      AiSuggestionModel(
        id: 'profile_complete',
        title: 'Complete Your Health Profile',
        description:
            'Add your health details in My Profile to receive personalized wellness suggestions.',
        category: SuggestionCategory.general,
        priority: 'high',
        generatedAt: DateTime.now(),
        triggerReason: 'No matching rules — profile needed',
        relevanceScore: 100,
      ),
    ];
  }
}
