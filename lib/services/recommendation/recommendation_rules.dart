import '../../models/ai_suggestion_model.dart';
import '../../models/patient_health_context.dart';

/// Rule-based wellness suggestions driven by [PatientHealthContext].
class RecommendationRules {
  List<AiSuggestionModel> evaluateAll(PatientHealthContext ctx) {
    final now = DateTime.now();
    final rules = <AiSuggestionModel?>[
      _profileComplete(ctx, now),
      _allergies(ctx, now),
      _ageSenior(ctx, now),
      _ageYoung(ctx, now),
      _bmiUnderweight(ctx, now),
      _bmiOverweight(ctx, now),
      _bmiObese(ctx, now),
      _diabetes(ctx, now),
      _hypertension(ctx, now),
      _asthma(ctx, now),
      _heart(ctx, now),
      _anxietyDepression(ctx, now),
      _smoking(ctx, now),
      _sedentary(ctx, now),
      _lowSleep(ctx, now),
      _highSleep(ctx, now),
      _medConsistency(ctx, now),
      _mealTiming(ctx, now),
      _painHydration(ctx, now),
      _frequentDoses(ctx, now),
      _polypharmacy(ctx, now),
      _lowAdherence(ctx, now),
      _goodAdherence(ctx, now),
      _morningRoutine(ctx, now),
      _eveningRoutine(ctx, now),
      _hydrationFallback(ctx, now),
      _sleepFallback(ctx, now),
      _exerciseFallback(ctx, now),
      _stressFallback(ctx, now),
    ];
    return rules.whereType<AiSuggestionModel>().toList();
  }

  String _greeting(PatientHealthContext ctx) {
    if (ctx.name.trim().isEmpty) return '';
    final first = ctx.name.trim().split(' ').first;
    return '$first, ';
  }

  AiSuggestionModel? _profileComplete(PatientHealthContext ctx, DateTime now) {
    if (!ctx.isProfileSparse) return null;
    return AiSuggestionModel(
      id: 'profile_complete',
      title: 'Complete Your Health Profile',
      description:
          '${_greeting(ctx)}your health profile is only ${ctx.profileCompleteness}% complete. '
          'Add your date of birth, vitals (weight & height), lifestyle details, and '
          'any chronic conditions in My Profile so SmartCare can tailor wellness tips for you.',
      category: SuggestionCategory.general,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Profile completeness below 40%',
      relevanceScore: 95,
    );
  }

  AiSuggestionModel? _allergies(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasAllergies) return null;
    return AiSuggestionModel(
      id: 'allergy_awareness',
      title: 'Allergy Awareness',
      description:
          '${_greeting(ctx)}you have listed allergies (${ctx.allergies}). '
          'Always check food labels and inform healthcare providers. '
          'Discuss any new medication with your doctor to avoid reactions.',
      category: SuggestionCategory.diet,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: Allergies on your profile',
      relevanceScore: 90,
    );
  }

  AiSuggestionModel? _ageSenior(PatientHealthContext ctx, DateTime now) {
    if (ctx.age == null || ctx.age! < 65) return null;
    return AiSuggestionModel(
      id: 'senior_wellness',
      title: 'Wellness for Your Age Group',
      description:
          'At age ${ctx.age}, focus on balance-friendly movement, staying hydrated, '
          'and reviewing medications with your doctor regularly. '
          'Ensure your home is fall-safe and keep emergency contacts updated.',
      category: SuggestionCategory.exercise,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: Age ${ctx.age} (65+)',
      relevanceScore: 85,
    );
  }

  AiSuggestionModel? _ageYoung(PatientHealthContext ctx, DateTime now) {
    if (ctx.age == null || ctx.age! >= 18) return null;
    return AiSuggestionModel(
      id: 'youth_activity',
      title: 'Age-Appropriate Activity',
      description:
          'Regular play and movement support healthy growth. '
          'Limit screen time before bed and maintain consistent sleep. '
          'Parents should supervise medication and discuss any concerns with a pediatrician.',
      category: SuggestionCategory.exercise,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: Age under 18',
      relevanceScore: 85,
    );
  }

  AiSuggestionModel? _bmiUnderweight(PatientHealthContext ctx, DateTime now) {
    if (ctx.bmiCategory != 'underweight') return null;
    return AiSuggestionModel(
      id: 'bmi_underweight',
      title: 'Nutrition for Healthy Weight',
      description:
          'Your BMI (${ctx.bmi!.toStringAsFixed(1)}) suggests you may benefit from '
          'nutrient-dense meals with adequate protein. Consult your doctor before '
          'making major dietary changes.',
      category: SuggestionCategory.diet,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: BMI ${ctx.bmi!.toStringAsFixed(1)} (underweight)',
      relevanceScore: 88,
    );
  }

  AiSuggestionModel? _bmiOverweight(PatientHealthContext ctx, DateTime now) {
    if (ctx.bmiCategory != 'overweight') return null;
    return AiSuggestionModel(
      id: 'bmi_overweight',
      title: 'Gentle Movement & Portion Awareness',
      description:
          'With BMI ${ctx.bmi!.toStringAsFixed(1)}, try 20–30 minutes of brisk walking '
          'most days and mindful portion sizes. Small, consistent changes work best — '
          'check with your doctor before starting intense exercise.',
      category: SuggestionCategory.exercise,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: BMI ${ctx.bmi!.toStringAsFixed(1)} (overweight)',
      relevanceScore: 88,
    );
  }

  AiSuggestionModel? _bmiObese(PatientHealthContext ctx, DateTime now) {
    if (ctx.bmiCategory != 'obese') return null;
    return AiSuggestionModel(
      id: 'bmi_obese',
      title: 'Low-Impact Activity',
      description:
          'Your BMI is ${ctx.bmi!.toStringAsFixed(1)}. Start with low-impact activities '
          'like walking or swimming. Pair movement with balanced meals and discuss '
          'a sustainable plan with your healthcare provider.',
      category: SuggestionCategory.exercise,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: BMI ${ctx.bmi!.toStringAsFixed(1)} (obese)',
      relevanceScore: 90,
    );
  }

  AiSuggestionModel? _diabetes(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasCondition('diabetes')) return null;
    return AiSuggestionModel(
      id: 'condition_diabetes',
      title: 'Blood Sugar Friendly Habits',
      description:
          'Eat regular meals with balanced carbs, stay active as approved by your doctor, '
          'and take medications on schedule. Monitor how you feel and attend follow-ups.',
      category: SuggestionCategory.diet,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: Diabetes-related health record',
      relevanceScore: 92,
    );
  }

  AiSuggestionModel? _hypertension(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasCondition('hypertension')) return null;
    return AiSuggestionModel(
      id: 'condition_hypertension',
      title: 'Heart-Healthy Daily Habits',
      description:
          'Reduce excess salt, manage stress, stay active within your limits, '
          'and take prescribed medications consistently. Track blood pressure if your doctor advises.',
      category: SuggestionCategory.general,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: Hypertension-related health record',
      relevanceScore: 92,
    );
  }

  AiSuggestionModel? _asthma(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasCondition('asthma')) return null;
    return AiSuggestionModel(
      id: 'condition_asthma',
      title: 'Respiratory Wellness',
      description:
          'Avoid smoke and strong fumes, keep rescue inhalers accessible, '
          'and follow your asthma action plan. Warm up gradually before exercise.',
      category: SuggestionCategory.general,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: Asthma-related health record',
      relevanceScore: 90,
    );
  }

  AiSuggestionModel? _heart(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasCondition('heart')) return null;
    return AiSuggestionModel(
      id: 'condition_heart',
      title: 'Cardiovascular Care',
      description:
          'Follow a heart-healthy diet low in saturated fats, stay active as recommended, '
          'and never skip heart medications without medical advice.',
      category: SuggestionCategory.diet,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: Heart-related health record',
      relevanceScore: 90,
    );
  }

  AiSuggestionModel? _anxietyDepression(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasCondition('anxiety') && !ctx.hasCondition('depression')) {
      return null;
    }
    return AiSuggestionModel(
      id: 'condition_mental_wellness',
      title: 'Mental Wellbeing Support',
      description:
          'Practice short breathing exercises, maintain social connection, '
          'and keep a regular sleep routine. Seek professional support if you feel overwhelmed.',
      category: SuggestionCategory.stress,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: Mental health-related record',
      relevanceScore: 85,
    );
  }

  AiSuggestionModel? _smoking(PatientHealthContext ctx, DateTime now) {
    if (ctx.healthProfile.smokingStatus != 'current') return null;
    return AiSuggestionModel(
      id: 'smoking_cessation',
      title: 'Smoking & Your Health',
      description:
          'Quitting smoking improves lung and heart health over time. '
          'Consider support programs and discuss cessation options with your doctor.',
      category: SuggestionCategory.general,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: Current smoker (health profile)',
      relevanceScore: 88,
    );
  }

  AiSuggestionModel? _sedentary(PatientHealthContext ctx, DateTime now) {
    if (ctx.healthProfile.activityLevel != 'sedentary') return null;
    return AiSuggestionModel(
      id: 'activity_sedentary',
      title: 'Start With Short Walks',
      description:
          'A sedentary lifestyle increases health risks. Try 10–15 minute walks '
          'after meals and build up gradually. Consult your doctor before intense exercise.',
      category: SuggestionCategory.exercise,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: Sedentary activity level',
      relevanceScore: 82,
    );
  }

  AiSuggestionModel? _lowSleep(PatientHealthContext ctx, DateTime now) {
    final h = ctx.healthProfile.sleepHoursPerNight;
    if (h <= 0 || h >= 6) return null;
    return AiSuggestionModel(
      id: 'sleep_low',
      title: 'Improve Your Sleep Duration',
      description:
          'You reported about ${h.toStringAsFixed(0)} hours of sleep. Most adults benefit from '
          '7–8 hours. Try a consistent bedtime and limit screens before sleep.',
      category: SuggestionCategory.sleep,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: Sleep under 6 hours/night',
      relevanceScore: 80,
    );
  }

  AiSuggestionModel? _highSleep(PatientHealthContext ctx, DateTime now) {
    final h = ctx.healthProfile.sleepHoursPerNight;
    if (h < 9) return null;
    return AiSuggestionModel(
      id: 'sleep_high',
      title: 'Sleep Quality Matters',
      description:
          'Long sleep duration can sometimes reflect poor quality rest. '
          'Keep a regular schedule and discuss persistent fatigue with your doctor.',
      category: SuggestionCategory.sleep,
      priority: 'low',
      generatedAt: now,
      triggerReason: 'Based on: Sleep 9+ hours/night',
      relevanceScore: 55,
    );
  }

  AiSuggestionModel? _medConsistency(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasMedications) return null;
    return AiSuggestionModel(
      id: 'med_consistency',
      title: 'Take Medications Consistently',
      description:
          '${_greeting(ctx)}you have ${ctx.totalMedicationCount} medication(s) on record. '
          'Taking them at the same time each day maintains steady levels. '
          'Never skip doses without consulting your doctor.',
      category: SuggestionCategory.medication,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: Active medications',
      relevanceScore: 88,
    );
  }

  AiSuggestionModel? _mealTiming(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasMealRelatedMed) return null;
    return AiSuggestionModel(
      id: 'meal_timing',
      title: 'Mind Your Meal Timing',
      description:
          'Some of your medications should be taken with or after food. '
          'Eat regular meals at consistent times to reduce stomach irritation.',
      category: SuggestionCategory.diet,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: Meal-related medication instructions',
      relevanceScore: 86,
    );
  }

  AiSuggestionModel? _painHydration(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasPainReliever) return null;
    return AiSuggestionModel(
      id: 'pain_hydration',
      title: 'Extra Hydration with Pain Relievers',
      description:
          'Pain relievers work best when you are well-hydrated. '
          'Drink extra water to support kidney health and reduce side effects.',
      category: SuggestionCategory.hydration,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: Pain reliever medications',
      relevanceScore: 75,
    );
  }

  AiSuggestionModel? _frequentDoses(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasFrequentDosing) return null;
    return AiSuggestionModel(
      id: 'frequent_reminder',
      title: 'Managing Frequent Doses',
      description:
          'You have medications scheduled multiple times daily. '
          'Use SmartCare reminders and keep water nearby when taking doses.',
      category: SuggestionCategory.medication,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: Frequent dosing schedule',
      relevanceScore: 78,
    );
  }

  AiSuggestionModel? _polypharmacy(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasPolypharmacy) return null;
    return AiSuggestionModel(
      id: 'multi_med',
      title: 'Managing Multiple Medications',
      description:
          'You have ${ctx.totalMedicationCount} medications on record. '
          'Use a pill organizer and consistent reminder times. '
          'Review all medicines with your doctor periodically.',
      category: SuggestionCategory.medication,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: 3+ medications',
      relevanceScore: 85,
    );
  }

  AiSuggestionModel? _lowAdherence(PatientHealthContext ctx, DateTime now) {
    if (!ctx.hasLowAdherence) return null;
    final pct = (ctx.adherenceRate * 100).round();
    return AiSuggestionModel(
      id: 'adherence_low',
      title: 'Improve Medication Adherence',
      description:
          'Your logged doses (${ctx.loggedDosesLast7Days} of ${ctx.expectedDosesLast7Days} expected '
          'this week, ~$pct%) suggest missed doses. Set alarms and log each dose in SmartCare.',
      category: SuggestionCategory.medication,
      priority: 'high',
      generatedAt: now,
      triggerReason: 'Based on: Medication logs (low adherence)',
      relevanceScore: 90,
    );
  }

  AiSuggestionModel? _goodAdherence(PatientHealthContext ctx, DateTime now) {
    if (ctx.expectedDosesLast7Days < 7 ||
        ctx.adherenceRate < 0.85 ||
        ctx.hasLowAdherence) {
      return null;
    }
    return AiSuggestionModel(
      id: 'adherence_good',
      title: 'Great Medication Consistency',
      description:
          'You are logging doses regularly — keep it up! Consistent adherence '
          'helps treatments work as intended.',
      category: SuggestionCategory.medication,
      priority: 'low',
      generatedAt: now,
      triggerReason: 'Based on: Strong medication adherence',
      relevanceScore: 60,
    );
  }

  AiSuggestionModel? _morningRoutine(PatientHealthContext ctx, DateTime now) {
    if (ctx.hourOfDay < 6 || ctx.hourOfDay >= 10) return null;
    return AiSuggestionModel(
      id: 'morning_routine',
      title: 'Start Your Morning Right',
      description:
          'Begin with water, light stretching, and breakfast. '
          'Morning routines help you take morning medications on time.',
      category: SuggestionCategory.general,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'Based on: Time of day (morning)',
      relevanceScore: 55,
    );
  }

  AiSuggestionModel? _eveningRoutine(PatientHealthContext ctx, DateTime now) {
    if (ctx.hourOfDay < 21 && ctx.hourOfDay >= 6) return null;
    return AiSuggestionModel(
      id: 'evening_checklist',
      title: 'Evening Health Checklist',
      description:
          'Take evening medications, hydrate lightly, avoid heavy late meals, '
          'and prepare tomorrow\'s doses if needed.',
      category: SuggestionCategory.general,
      priority: 'low',
      generatedAt: now,
      triggerReason: 'Based on: Time of day (evening)',
      relevanceScore: 50,
    );
  }

  bool _shouldShowFallbacks(PatientHealthContext ctx) {
    return !ctx.isProfileSparse && ctx.profileCompleteness >= 50;
  }

  AiSuggestionModel? _hydrationFallback(PatientHealthContext ctx, DateTime now) {
    if (!_shouldShowFallbacks(ctx)) return null;
    if (ctx.hasPainReliever || ctx.hasCondition('diabetes')) return null;
    return AiSuggestionModel(
      id: 'hydration_daily',
      title: 'Stay Hydrated',
      description:
          'Aim for about 2 liters of water daily unless your doctor advises otherwise. '
          'Hydration supports energy and medication absorption.',
      category: SuggestionCategory.hydration,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'General wellness (profile complete)',
      relevanceScore: 45,
    );
  }

  AiSuggestionModel? _sleepFallback(PatientHealthContext ctx, DateTime now) {
    if (!_shouldShowFallbacks(ctx)) return null;
    if (ctx.healthProfile.sleepHoursPerNight > 0) return null;
    return AiSuggestionModel(
      id: 'sleep_routine',
      title: 'Maintain a Sleep Schedule',
      description:
          'Aim for 7–8 hours nightly with consistent bed and wake times. '
          'Avoid screens 30 minutes before bed.',
      category: SuggestionCategory.sleep,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'General wellness (no sleep data entered)',
      relevanceScore: 42,
    );
  }

  AiSuggestionModel? _exerciseFallback(PatientHealthContext ctx, DateTime now) {
    if (!_shouldShowFallbacks(ctx)) return null;
    if (ctx.healthProfile.activityLevel.isNotEmpty) return null;
    if (ctx.bmiCategory == 'overweight' || ctx.bmiCategory == 'obese') {
      return null;
    }
    return AiSuggestionModel(
      id: 'exercise_basic',
      title: '30 Minutes of Daily Movement',
      description:
          'Regular activity — even a brisk walk — supports heart health and mood. '
          'Consult your doctor before starting intense exercise.',
      category: SuggestionCategory.exercise,
      priority: 'medium',
      generatedAt: now,
      triggerReason: 'General wellness (no activity level set)',
      relevanceScore: 40,
    );
  }

  AiSuggestionModel? _stressFallback(PatientHealthContext ctx, DateTime now) {
    if (!_shouldShowFallbacks(ctx)) return null;
    if (ctx.hasCondition('anxiety') || ctx.hasCondition('depression')) {
      return null;
    }
    return AiSuggestionModel(
      id: 'stress_management',
      title: 'Manage Daily Stress',
      description:
          'Try deep breathing, short walks, or talking to someone you trust. '
          'Even 10 minutes of mindfulness daily can help.',
      category: SuggestionCategory.stress,
      priority: 'low',
      generatedAt: now,
      triggerReason: 'General wellness',
      relevanceScore: 35,
    );
  }
}
