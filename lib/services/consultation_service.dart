// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/consultation_service.dart
// PURPOSE: Patient–doctor consultation booking and queries.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';

class ConsultationService {
  final _db = FirebaseFirestore.instance;

  /// Active doctors available for patient booking.
  Stream<List<Map<String, dynamic>>> getAvailableDoctors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList()
          ..sort((a, b) =>
              ((a['name'] as String?) ?? '').compareTo((b['name'] as String?) ?? '')));
  }

  /// Creates a new active consultation between patient and doctor.
  Future<String> createConsultation({
    required String patientId,
    required String doctorId,
  }) async {
    final existing = await _db
        .collection('consultations')
        .where('patientId', isEqualTo: patientId)
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final hasActive = existing.docs.any(
      (d) => (d.data()['status'] as String?) == ConsultationStatus.active.value,
    );
    if (hasActive) {
      throw StateError('You already have an active consultation with this doctor.');
    }

    final patientDoc = await _db.collection('users').doc(patientId).get();
    final doctorDoc = await _db.collection('users').doc(doctorId).get();

    if (!doctorDoc.exists) {
      throw StateError('Doctor not found.');
    }

    final patientData = patientDoc.data();
    final doctorData = doctorDoc.data();
    final now = DateTime.now();

    final docRef = await _db.collection('consultations').add({
      'patientId': patientId,
      'patientName': (patientData?['name'] as String?) ?? 'Patient',
      'doctorId': doctorId,
      'doctorName': (doctorData?['name'] as String?) ?? 'Doctor',
      'consultationDate': Timestamp.fromDate(now),
      'status': ConsultationStatus.active.value,
      'notes': '',
      'diagnosis': '',
      'followUpDate': '',
      'createdAt': Timestamp.fromDate(now),
    });

    return docRef.id;
  }

  Stream<List<ConsultationModel>> getPatientConsultations(String patientId) {
    return _db
        .collection('consultations')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ConsultationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.consultationDate.compareTo(a.consultationDate));
      return list;
    });
  }

  Stream<List<ConsultationModel>> getDoctorConsultations(String doctorId) {
    return _db
        .collection('consultations')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => ConsultationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.consultationDate.compareTo(a.consultationDate));
      return list;
    });
  }
}
