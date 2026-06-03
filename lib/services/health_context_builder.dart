import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../models/health_profile_model.dart';
import '../models/medication_model.dart';
import '../models/patient_health_context.dart';
import '../models/prescription_model.dart';
import '../models/user_model.dart';
import '../utils/health_context_utils.dart';

/// Loads and aggregates patient health data from Firestore.
class HealthContextBuilder {
  final _db = FirebaseFirestore.instance;

  Future<PatientHealthContext> build(String userId) async {
    final now = DateTime.now();
    final hour = now.hour;

    UserModel? user;
    List<MedicationModel> meds = [];
    List<PrescribedMedicine> rxMeds = [];
    List<String> diagnoses = [];
    List<String> notes = [];
    List<String> reasons = [];
    var loggedDoses = 0;
    var expectedDoses = 0;

    try {
      final results = await Future.wait([
        _fetchUser(userId),
        _fetchMedications(userId),
        _fetchPrescriptions(userId),
        _fetchConsultations(userId),
        _fetchAppointments(userId),
        _fetchAdherence(userId, now),
      ]);

      user = results[0] as UserModel?;
      meds = results[1] as List<MedicationModel>;
      final rx = results[2] as List<PrescriptionModel>;
      rxMeds = rx.expand((p) => p.medicines).toList();
      final consultations = results[3] as List<ConsultationModel>;
      diagnoses = consultations
          .map((c) => c.diagnosis)
          .where((d) => d.trim().isNotEmpty)
          .toList();
      notes = consultations
          .map((c) => c.notes)
          .where((n) => n.trim().isNotEmpty)
          .toList();
      reasons = results[4] as List<String>;
      final adherence = results[5] as Map<String, int>;
      loggedDoses = adherence['logged'] ?? 0;
      expectedDoses = adherence['expected'] ?? 0;
    } catch (_) {
      // Partial context is acceptable
    }

    final hp = user?.healthProfile ?? const HealthProfileModel();
    final age = HealthContextUtils.computeAge(user?.dateOfBirth ?? '');
    final bmi = HealthContextUtils.computeBmi(hp.weightKg, hp.heightCm);
    final bmiCat = HealthContextUtils.bmiCategory(bmi);

    final textSources = [
      user?.allergies ?? '',
      ...diagnoses,
      ...notes,
      ...reasons,
      ...hp.chronicConditions,
    ];

    final conditionTags = HealthContextUtils.extractConditionTags(
      textSources: textSources,
      chronicConditions: hp.chronicConditions,
    );

    final adherenceRate = expectedDoses > 0
        ? (loggedDoses / expectedDoses).clamp(0.0, 1.0)
        : 1.0;

    final completeness = HealthContextUtils.computeProfileCompleteness(
      dateOfBirth: user?.dateOfBirth ?? '',
      gender: user?.gender ?? '',
      bloodGroup: user?.bloodGroup ?? '',
      allergies: user?.allergies ?? '',
      hasVitals: hp.hasVitals,
      activityLevel: hp.activityLevel,
      sleepHours: hp.sleepHoursPerNight,
      smokingStatus: hp.smokingStatus,
      hasChronicOrDiagnosis:
          hp.chronicConditions.isNotEmpty || diagnoses.isNotEmpty,
      hasMedicationOrConsultation:
          meds.isNotEmpty || rxMeds.isNotEmpty || diagnoses.isNotEmpty,
    );

    return PatientHealthContext(
      userId: userId,
      name: user?.name ?? '',
      age: age,
      gender: user?.gender ?? '',
      bloodGroup: user?.bloodGroup ?? '',
      allergies: user?.allergies ?? '',
      dateOfBirth: user?.dateOfBirth ?? '',
      healthProfile: hp,
      patientMedications: meds,
      prescriptionMedicines: rxMeds,
      diagnoses: diagnoses,
      clinicalNotes: notes,
      appointmentReasons: reasons,
      conditionTags: conditionTags,
      bmi: bmi,
      bmiCategory: bmiCat,
      profileCompleteness: completeness,
      adherenceRate: adherenceRate,
      expectedDosesLast7Days: expectedDoses,
      loggedDosesLast7Days: loggedDoses,
      hourOfDay: hour,
    );
  }

  Future<UserModel?> _fetchUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<List<MedicationModel>> _fetchMedications(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => MedicationModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<List<PrescriptionModel>> _fetchPrescriptions(String userId) async {
    final snap = await _db
        .collection('prescriptions')
        .where('patientId', isEqualTo: userId)
        .get();
    final list = snap.docs
        .map((d) => PrescriptionModel.fromMap(d.data(), d.id))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(10).toList();
  }

  Future<List<ConsultationModel>> _fetchConsultations(String userId) async {
    final snap = await _db
        .collection('consultations')
        .where('patientId', isEqualTo: userId)
        .get();
    final list = snap.docs
        .map((d) => ConsultationModel.fromMap(d.data(), d.id))
        .toList();
    list.sort((a, b) => b.consultationDate.compareTo(a.consultationDate));
    return list.take(10).toList();
  }

  Future<List<String>> _fetchAppointments(String userId) async {
    final snap = await _db
        .collection('appointments')
        .where('patientId', isEqualTo: userId)
        .get();
    return snap.docs
        .map((d) => (d.data()['reason'] as String?) ?? '')
        .where((r) => r.trim().isNotEmpty)
        .toList();
  }

  Future<Map<String, int>> _fetchAdherence(String userId, DateTime now) async {
    final medsSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .where('isActive', isEqualTo: true)
        .get();

    var expected = 0;
    for (final doc in medsSnap.docs) {
      final times = List<String>.from(doc.data()['times'] ?? []);
      expected += times.length * 7;
    }

    if (expected == 0) {
      return {'logged': 0, 'expected': 0};
    }

    final weekAgo = now.subtract(const Duration(days: 7));
    final logsSnap = await _db
        .collection('users')
        .doc(userId)
        .collection('medicationLogs')
        .get();

    var logged = 0;
    for (final doc in logsSnap.docs) {
      final data = doc.data();
      final takenAt = data['takenAt'];
      DateTime? dt;
      if (takenAt is Timestamp) {
        dt = takenAt.toDate();
      }
      if (dt != null && dt.isAfter(weekAgo)) {
        logged++;
      }
    }

    return {'logged': logged, 'expected': expected};
  }
}
