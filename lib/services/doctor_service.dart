// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/doctor_service.dart
// PURPOSE: All Firestore operations needed by the Doctor role:
//   - Fetch patient list (scoped to doctor's consultations)
//   - Fetch patient medications (read-only)
//   - Add/get consultation notes
//   - Create/get prescriptions (doctors only)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import '../models/health_record_model.dart';
import '../models/user_model.dart';
import 'consultation_service.dart';

class DoctorService {
  final _db = FirebaseFirestore.instance;
  final _consultService = ConsultationService();

  // ── GET DOCTOR'S PATIENTS (via consultations collection) ─────────────────
  Stream<List<Map<String, dynamic>>> getMyPatients(String doctorId) {
    if (doctorId.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .asyncMap((consultSnap) async {
      final patientIds = consultSnap.docs
          .map((d) => d.data()['patientId'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      if (patientIds.isEmpty) return <Map<String, dynamic>>[];

      final patients = <Map<String, dynamic>>[];
      for (var i = 0; i < patientIds.length; i += 10) {
        final end = (i + 10 > patientIds.length) ? patientIds.length : i + 10;
        final batch = patientIds.sublist(i, end);
        final snap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          if (data['isActive'] == true && data['role'] == 'patient') {
            patients.add({'id': doc.id, ...data});
          }
        }
      }
      return patients;
    });
  }

  // ── GET PATIENT MEDICATIONS (read-only for doctor) ─────────────────────────
  Stream<List<MedicationModel>> getPatientMedications(String patientId) {
    return _db
        .collection('users')
        .doc(patientId)
        .collection('medications')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => MedicationModel.fromMap(
              doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── ADD CONSULTATION NOTE ──────────────────────────────────────────────────
  Future<bool> addConsultation(ConsultationModel consultation) async {
    try {
      await _db.collection('consultations').add(consultation.toMap());
      return true;
    } catch (e) {
      // ignore: avoid_print
      print(e);
      rethrow;
    }
  }

  // ── GET CONSULTATIONS FOR A PATIENT ───────────────────────────────────────
  Stream<List<ConsultationModel>> getPatientConsultations(String patientId) =>
      _consultService.getPatientConsultations(patientId);

  // ── CREATE PRESCRIPTION ────────────────────────────────────────────────────
  Future<bool> createPrescription(PrescriptionModel prescription) async {
    try {
      await _db.collection('prescriptions').add(prescription.toMap());
      return true;
    } catch (e) {
      // ignore: avoid_print
      print(e);
      rethrow;
    }
  }

  // ── GET PRESCRIPTIONS FOR A PATIENT ───────────────────────────────────────
  Stream<List<PrescriptionModel>> getPatientPrescriptions(String patientId) {
    return _db
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => PrescriptionModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── GET DOCTOR'S OWN CONSULTATIONS (for dashboard stats) ──────────────────
  Stream<List<ConsultationModel>> getDoctorConsultations(String doctorId) =>
      _consultService.getDoctorConsultations(doctorId);

  // ── GET PATIENT PROFILE (medical history summary) ─────────────────────────
  Future<UserModel?> getPatientProfile(String patientId) async {
    if (patientId.isEmpty) return null;
    final doc = await _db.collection('users').doc(patientId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // ── GET PATIENT HEALTH RECORDS (read-only for doctor) ─────────────────────
  Stream<List<HealthRecordModel>> getPatientHealthRecords(String patientId) {
    return _db
        .collection('users')
        .doc(patientId)
        .collection('healthRecords')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => HealthRecordModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }
}
