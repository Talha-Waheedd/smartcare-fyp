/// Pure helpers for building [PatientHealthContext].
class HealthContextUtils {
  HealthContextUtils._();

  static const conditionKeywords = {
    'diabetes': ['diabetes', 'diabetic', 'blood sugar', 'glucose'],
    'hypertension': ['hypertension', 'high blood pressure', 'bp'],
    'asthma': ['asthma', 'wheez', 'inhaler'],
    'heart': ['heart', 'cardiac', 'cardiovascular', 'cholesterol'],
    'kidney': ['kidney', 'renal'],
    'pregnancy': ['pregnant', 'pregnancy'],
    'anxiety': ['anxiety', 'panic'],
    'depression': ['depression', 'depressive'],
    'anemia': ['anemia', 'anaemia', 'iron deficiency'],
  };

  static int? computeAge(String dateOfBirth) {
    if (dateOfBirth.trim().isEmpty) return null;
    try {
      final parts = dateOfBirth.split('-');
      if (parts.length != 3) return null;
      final dob = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      var age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age >= 0 && age <= 120 ? age : null;
    } catch (_) {
      return null;
    }
  }

  static double? computeBmi(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static String? bmiCategory(double? bmi) {
    if (bmi == null) return null;
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }

  static Set<String> extractConditionTags({
    required List<String> textSources,
    required List<String> chronicConditions,
  }) {
    final tags = <String>{};
    final combined = textSources.join(' ').toLowerCase();

    for (final entry in conditionKeywords.entries) {
      if (entry.value.any((k) => combined.contains(k))) {
        tags.add(entry.key);
      }
    }

    for (final condition in chronicConditions) {
      final lower = condition.toLowerCase();
      for (final entry in conditionKeywords.entries) {
        if (entry.value.any((k) => lower.contains(k)) ||
            lower.contains(entry.key)) {
          tags.add(entry.key);
        }
      }
      if (lower.contains('diabetes')) tags.add('diabetes');
      if (lower.contains('hypertension') || lower.contains('blood pressure')) {
        tags.add('hypertension');
      }
      if (lower.contains('asthma')) tags.add('asthma');
      if (lower.contains('heart')) tags.add('heart');
      if (lower.contains('kidney')) tags.add('kidney');
      if (lower.contains('anxiety')) tags.add('anxiety');
      if (lower.contains('depression')) tags.add('depression');
      if (lower.contains('anemia')) tags.add('anemia');
    }

    return tags;
  }

  static int computeProfileCompleteness({
    required String dateOfBirth,
    required String gender,
    required String bloodGroup,
    required String allergies,
    required bool hasVitals,
    required String activityLevel,
    required double sleepHours,
    required String smokingStatus,
    required bool hasChronicOrDiagnosis,
    required bool hasMedicationOrConsultation,
  }) {
    var score = 0;
    if (dateOfBirth.isNotEmpty) score += 15;
    if (gender.isNotEmpty) score += 10;
    if (bloodGroup.isNotEmpty) score += 10;
    if (allergies.isNotEmpty) score += 10;
    if (hasVitals) score += 15;
    if (activityLevel.isNotEmpty) score += 10;
    if (sleepHours > 0) score += 10;
    if (smokingStatus.isNotEmpty) score += 10;
    if (hasChronicOrDiagnosis) score += 10;
    if (hasMedicationOrConsultation) score += 10;
    return score.clamp(0, 100);
  }
}
