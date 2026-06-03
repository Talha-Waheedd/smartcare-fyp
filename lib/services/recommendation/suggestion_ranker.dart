import '../../models/ai_suggestion_model.dart';

/// Filters, deduplicates, ranks, and caps suggestion lists.
class SuggestionRanker {
  static const _priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
  static const _categoryFamilies = {
    SuggestionCategory.hydration: 'hydration',
    SuggestionCategory.sleep: 'sleep',
    SuggestionCategory.exercise: 'exercise',
    SuggestionCategory.diet: 'diet',
    SuggestionCategory.stress: 'stress',
    SuggestionCategory.medication: 'medication',
    SuggestionCategory.general: 'general',
  };

  List<AiSuggestionModel> rankAndCap(
    List<AiSuggestionModel> candidates, {
    int maxCount = 8,
    int minCount = 3,
  }) {
    if (candidates.isEmpty) return [];

    final sorted = List<AiSuggestionModel>.from(candidates)
      ..sort((a, b) {
        final p = (_priorityOrder[a.priority] ?? 2)
            .compareTo(_priorityOrder[b.priority] ?? 2);
        if (p != 0) return p;
        return b.relevanceScore.compareTo(a.relevanceScore);
      });

    final filtered = _dedupeByFamily(sorted);

    final highRelevance = filtered.where((s) => s.relevanceScore >= 70).length;
    List<AiSuggestionModel> result;
    if (highRelevance >= 3) {
      result = filtered
          .where((s) =>
              s.relevanceScore >= 50 ||
              s.priority == 'high' ||
              s.id == 'profile_complete')
          .toList();
      if (result.length < minCount) {
        result = filtered.take(maxCount).toList();
      } else {
        result = result.take(maxCount).toList();
      }
    } else {
      result = filtered.take(maxCount).toList();
    }

    return result;
  }

  List<AiSuggestionModel> _dedupeByFamily(List<AiSuggestionModel> sorted) {
    final seenFamilies = <String>{};
    final seenIds = <String>{};
    final out = <AiSuggestionModel>[];

    for (final s in sorted) {
      if (seenIds.contains(s.id)) continue;
      final family = _categoryFamilies[s.category] ?? s.category.name;
      if (seenFamilies.contains(family) && s.relevanceScore < 80) {
        continue;
      }
      seenFamilies.add(family);
      seenIds.add(s.id);
      out.add(s);
    }
    return out;
  }
}
