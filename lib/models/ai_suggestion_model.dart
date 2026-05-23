// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/ai_suggestion_model.dart
// PURPOSE: Data model for AI-generated wellness suggestions.
// ⚠️  MEDICAL CONSTRAINT: AI suggestions are preventive/wellness only.
//     AI must NEVER diagnose, prescribe, or replace doctor advice.
// ─────────────────────────────────────────────────────────────────────────────

enum SuggestionCategory {
  diet,
  exercise,
  sleep,
  hydration,
  stress,
  medication,
  general,
}

extension SuggestionCategoryExtension on SuggestionCategory {
  String get label {
    switch (this) {
      case SuggestionCategory.diet:       return 'Diet';
      case SuggestionCategory.exercise:   return 'Exercise';
      case SuggestionCategory.sleep:      return 'Sleep';
      case SuggestionCategory.hydration:  return 'Hydration';
      case SuggestionCategory.stress:     return 'Stress';
      case SuggestionCategory.medication: return 'Medication';
      case SuggestionCategory.general:    return 'General';
    }
  }

  String get emoji {
    switch (this) {
      case SuggestionCategory.diet:       return '🥗';
      case SuggestionCategory.exercise:   return '🏃';
      case SuggestionCategory.sleep:      return '😴';
      case SuggestionCategory.hydration:  return '💧';
      case SuggestionCategory.stress:     return '🧘';
      case SuggestionCategory.medication: return '💊';
      case SuggestionCategory.general:    return '💡';
    }
  }
}

class AiSuggestionModel {
  final String id;
  final String title;
  final String description;
  final SuggestionCategory category;
  final String priority;    // 'high', 'medium', 'low'
  final DateTime generatedAt;

  const AiSuggestionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.generatedAt,
  });

  // Priority color for UI
  String get priorityLabel {
    switch (priority) {
      case 'high':   return '⚠️ Important';
      case 'medium': return '📌 Suggested';
      default:       return '💬 Tip';
    }
  }
}