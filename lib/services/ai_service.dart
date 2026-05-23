// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/ai_service.dart
// FIXED: All field names now match ai_suggestion_model.dart exactly
//   - 'body' → 'description'
//   - 'isAlert' removed → using 'priority' for sorting
//   - SuggestionCategory.nutrition → SuggestionCategory.diet
//   - SuggestionCategory.mental → SuggestionCategory.stress
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_suggestion_model.dart';
import '../models/medication_model.dart';

class AiService {
  final _db = FirebaseFirestore.instance;

  // ── GENERATE SUGGESTIONS ───────────────────────────────────────────────────
  Future<List<AiSuggestionModel>> generateSuggestions(String userId) async {
    final suggestions = <AiSuggestionModel>[];

    // Fetch patient's active medications from Firestore
    List<MedicationModel> medications = [];
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('medications')
          .where('isActive', isEqualTo: true)
          .get();

      medications = snap.docs
          .map((doc) => MedicationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Continue with general suggestions even if fetch fails
    }

    // Build suggestion list
    suggestions.addAll(_generalWellnessSuggestions());

    if (medications.isNotEmpty) {
      suggestions.addAll(_medicationBasedSuggestions(medications));
    }

    suggestions.addAll(_timeBasedSuggestions());

    if (medications.length >= 3) {
      suggestions.add(AiSuggestionModel(
        id: 'multi_med',
        title: 'Managing Multiple Medications',
        description:
            'You have ${medications.length} active medications. Consider using a pill organizer '
            'and setting reminders for each one. Taking medications at consistent times '
            'improves effectiveness. Always consult your doctor before making any changes.',
        category: SuggestionCategory.medication,
        priority: 'high',
        generatedAt: DateTime.now(),
      ));
    }

    // Sort by priority: high → medium → low
    const order = {'high': 0, 'medium': 1, 'low': 2};
    suggestions.sort((a, b) =>
        (order[a.priority] ?? 2).compareTo(order[b.priority] ?? 2));

    return suggestions.take(8).toList();
  }

  // ── GENERAL WELLNESS SUGGESTIONS ──────────────────────────────────────────
  List<AiSuggestionModel> _generalWellnessSuggestions() {
    return [
      AiSuggestionModel(
        id: 'hydration_daily',
        title: 'Stay Hydrated',
        description:
            'Drink at least 8 glasses (2 liters) of water daily. Proper hydration supports '
            'kidney function, helps medications absorb better, and maintains energy levels. '
            'Start your morning with a glass of water before breakfast.',
        category: SuggestionCategory.hydration,
        priority: 'high',
        generatedAt: DateTime.now(),
      ),
      AiSuggestionModel(
        id: 'sleep_routine',
        title: 'Maintain a Sleep Schedule',
        description:
            'Aim for 7-8 hours of sleep each night. Going to bed and waking up at consistent '
            'times helps regulate your body clock, improves mood, and supports immune function. '
            'Avoid screens 30 minutes before bed.',
        category: SuggestionCategory.sleep,
        priority: 'medium',
        generatedAt: DateTime.now(),
      ),
      AiSuggestionModel(
        id: 'exercise_basic',
        title: '30 Minutes of Daily Movement',
        description:
            'Regular physical activity — even a 30-minute walk — reduces risk of chronic '
            'disease, improves cardiovascular health, and boosts mental wellbeing. '
            'Consult your doctor before starting a new exercise routine.',
        category: SuggestionCategory.exercise,
        priority: 'medium',
        generatedAt: DateTime.now(),
      ),
      AiSuggestionModel(
        id: 'diet_balanced',
        title: 'Eat a Balanced Diet',
        description:
            'Include fruits, vegetables, whole grains, and lean proteins in your meals. '
            'Reduce processed foods, added sugars, and excessive salt. '
            'A balanced diet supports medication effectiveness and overall health.',
        category: SuggestionCategory.diet,
        priority: 'medium',
        generatedAt: DateTime.now(),
      ),
      AiSuggestionModel(
        id: 'stress_management',
        title: 'Manage Daily Stress',
        description:
            'Chronic stress can worsen many health conditions. Try deep breathing exercises, '
            'spending time in nature, or talking to someone you trust. Even 10 minutes of '
            'mindfulness daily can make a significant difference.',
        category: SuggestionCategory.stress,
        priority: 'low',
        generatedAt: DateTime.now(),
      ),
    ];
  }

  // ── MEDICATION-BASED SUGGESTIONS ──────────────────────────────────────────
  List<AiSuggestionModel> _medicationBasedSuggestions(
      List<MedicationModel> medications) {
    final suggestions = <AiSuggestionModel>[];
    final medNames =
        medications.map((m) => m.name.toLowerCase()).toList();

    // Always remind about consistency when meds exist
    suggestions.add(AiSuggestionModel(
      id: 'med_consistency',
      title: 'Take Medications Consistently',
      description:
          'You have active medications scheduled. Taking them at the same time each day '
          'maintains steady levels in your body and maximizes effectiveness. '
          'Never skip a dose without consulting your doctor.',
      category: SuggestionCategory.medication,
      priority: 'high',
      generatedAt: DateTime.now(),
    ));

    // Rule: medication has meal-related instructions
    final hasMealMed = medications.any((m) =>
        m.instructions.toLowerCase().contains('meal') ||
        m.instructions.toLowerCase().contains('food') ||
        m.instructions.toLowerCase().contains('eat'));

    if (hasMealMed) {
      suggestions.add(AiSuggestionModel(
        id: 'meal_timing',
        title: 'Mind Your Meal Timing',
        description:
            'Some of your medications should be taken with or after food. '
            'Eating regular meals at consistent times helps ensure you take your '
            'medication correctly and reduces stomach irritation.',
        category: SuggestionCategory.diet,
        priority: 'high',
        generatedAt: DateTime.now(),
      ));
    }

    // Rule: common pain relievers detected
    if (medNames.any((n) =>
        n.contains('paracetamol') ||
        n.contains('ibuprofen') ||
        n.contains('aspirin'))) {
      suggestions.add(AiSuggestionModel(
        id: 'pain_hydration',
        title: 'Extra Hydration with Pain Relievers',
        description:
            'Pain relievers work best when you are well-hydrated. '
            'Drink extra water when taking these medications to support kidney '
            'health and reduce the risk of side effects.',
        category: SuggestionCategory.hydration,
        priority: 'medium',
        generatedAt: DateTime.now(),
      ));
    }

    // Rule: medication taken 3+ times a day
    final hasFrequentMed = medications.any((m) => m.times.length >= 3);
    if (hasFrequentMed) {
      suggestions.add(AiSuggestionModel(
        id: 'frequent_reminder',
        title: 'Managing Frequent Doses',
        description:
            'You have medications scheduled multiple times a day. Setting phone alarms '
            'alongside SmartCare reminders can help. Keep a water bottle nearby '
            'to take medications comfortably throughout the day.',
        category: SuggestionCategory.medication,
        priority: 'medium',
        generatedAt: DateTime.now(),
      ));
    }

    return suggestions;
  }

  // ── TIME-BASED SUGGESTIONS ─────────────────────────────────────────────────
  List<AiSuggestionModel> _timeBasedSuggestions() {
    final hour = DateTime.now().hour;
    final suggestions = <AiSuggestionModel>[];

    if (hour >= 6 && hour < 10) {
      suggestions.add(AiSuggestionModel(
        id: 'morning_routine',
        title: 'Start Your Morning Right',
        description:
            'Begin your day with a glass of water, light stretching, and a nutritious '
            'breakfast. Morning routines ensure you don\'t miss morning medications '
            'on an empty stomach.',
        category: SuggestionCategory.general,
        priority: 'medium',
        generatedAt: DateTime.now(),
      ));
    } else if (hour >= 21 || hour < 6) {
      suggestions.add(AiSuggestionModel(
        id: 'evening_checklist',
        title: 'Evening Health Checklist',
        description:
            'Before bed: take any evening medications, drink a small glass of water, '
            'avoid heavy meals, and prepare tomorrow\'s medications if needed. '
            'Good evening habits lead to better sleep and health outcomes.',
        category: SuggestionCategory.general,
        priority: 'low',
        generatedAt: DateTime.now(),
      ));
    }

    return suggestions;
  }
}