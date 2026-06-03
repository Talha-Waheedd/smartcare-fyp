import 'health_profile_model.dart';
import 'medication_model.dart';
import 'prescription_model.dart';

/// Aggregated snapshot of patient health data for the recommendation engine.
class PatientHealthContext {
  final String userId;
  final String name;
  final int? age;
  final String gender;
  final String bloodGroup;
  final String allergies;
  final String dateOfBirth;
  final HealthProfileModel healthProfile;
  final List<MedicationModel> patientMedications;
  final List<PrescribedMedicine> prescriptionMedicines;
  final List<String> diagnoses;
  final List<String> clinicalNotes;
  final List<String> appointmentReasons;
  final Set<String> conditionTags;
  final double? bmi;
  final String? bmiCategory;
  final int profileCompleteness;
  final double adherenceRate;
  final int expectedDosesLast7Days;
  final int loggedDosesLast7Days;
  final int hourOfDay;

  const PatientHealthContext({
    required this.userId,
    this.name = '',
    this.age,
    this.gender = '',
    this.bloodGroup = '',
    this.allergies = '',
    this.dateOfBirth = '',
    this.healthProfile = const HealthProfileModel(),
    this.patientMedications = const [],
    this.prescriptionMedicines = const [],
    this.diagnoses = const [],
    this.clinicalNotes = const [],
    this.appointmentReasons = const [],
    this.conditionTags = const {},
    this.bmi,
    this.bmiCategory,
    this.profileCompleteness = 0,
    this.adherenceRate = 1.0,
    this.expectedDosesLast7Days = 0,
    this.loggedDosesLast7Days = 0,
    required this.hourOfDay,
  });

  int get totalMedicationCount =>
      patientMedications.length + prescriptionMedicines.length;

  bool get hasMedications => totalMedicationCount > 0;

  bool get hasPolypharmacy => totalMedicationCount >= 3;

  bool get hasAllergies => allergies.trim().isNotEmpty;

  bool get isProfileSparse => profileCompleteness < 40;

  bool get hasLowAdherence =>
      expectedDosesLast7Days > 0 && adherenceRate < 0.7;

  bool hasCondition(String tag) => conditionTags.contains(tag);

  List<String> get allMedicationNamesLower {
    final names = <String>[];
    for (final m in patientMedications) {
      names.add(m.name.toLowerCase());
    }
    for (final m in prescriptionMedicines) {
      names.add(m.name.toLowerCase());
    }
    return names;
  }

  String get allMedicationInstructionsLower {
    final parts = <String>[];
    for (final m in patientMedications) {
      parts.add(m.instructions.toLowerCase());
    }
    for (final m in prescriptionMedicines) {
      parts.add(m.instructions.toLowerCase());
    }
    return parts.join(' ');
  }

  bool get hasMealRelatedMed {
    final text = allMedicationInstructionsLower;
    return text.contains('meal') ||
        text.contains('food') ||
        text.contains('eat');
  }

  bool get hasFrequentDosing {
    if (patientMedications.any((m) => m.times.length >= 3)) return true;
    for (final m in prescriptionMedicines) {
      final f = m.frequency.toLowerCase();
      if (f.contains('3') ||
          f.contains('three') ||
          f.contains('thrice') ||
          f.contains('4') ||
          f.contains('four')) {
        return true;
      }
    }
    return false;
  }

  bool get hasPainReliever {
    const keys = ['paracetamol', 'ibuprofen', 'aspirin', 'acetaminophen'];
    return allMedicationNamesLower
        .any((n) => keys.any((k) => n.contains(k)));
  }
}
