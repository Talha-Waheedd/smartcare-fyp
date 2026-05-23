// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/doctor_service.dart
// PURPOSE: All Firestore operations needed by the Doctor role:
//   - Fetch patient list
//   - Fetch patient medications (read-only)
//   - Add/get consultation notes
//   - Create/get prescriptions (doctors only)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';

class DoctorService {
  final _db = FirebaseFirestore.instance;

  // ── GET ALL PATIENTS ───────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getPatients() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
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
      return false;
    }
  }

  // ── GET CONSULTATIONS FOR A PATIENT ───────────────────────────────────────
  Stream<List<ConsultationModel>> getPatientConsultations(String patientId) {
    return _db
        .collection('consultations')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ConsultationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── CREATE PRESCRIPTION ────────────────────────────────────────────────────
  // ⚠️ Only this service method creates prescriptions — never AI
  Future<bool> createPrescription(PrescriptionModel prescription) async {
    try {
      await _db.collection('prescriptions').add(prescription.toMap());
      return true;
    } catch (e) {
      return false;
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
  Stream<List<ConsultationModel>> getDoctorConsultations(String doctorId) {
    return _db
        .collection('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ConsultationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}