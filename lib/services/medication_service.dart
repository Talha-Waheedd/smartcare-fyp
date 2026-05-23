// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/medication_service.dart
// FIX: Removed orderBy('createdAt') which was causing the composite index error.
//      Sorting is now done in Dart after fetching — no Firestore index needed.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication_model.dart';

class MedicationService {
  final _firestore = FirebaseFirestore.instance;

  // Collection path: users/{uid}/medications
  CollectionReference _medicationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medications');
  }

  // ── CREATE ────────────────────────────────────────────────────────────────
  Future<String?> addMedication(MedicationModel med) async {
    try {
      final doc = await _medicationsRef(med.userId).add(med.toMap());
      return doc.id;
    } catch (e) {
      return null;
    }
  }

  // ── READ (active only) ────────────────────────────────────────────────────
  // FIX: Only filter by isActive — no orderBy — so no composite index needed.
  //      We sort by createdAt in Dart instead.
  Stream<List<MedicationModel>> getMedications(String userId) {
    return _medicationsRef(userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MedicationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Sort by createdAt descending (newest first) — done in Dart, not Firestore
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── READ (all including inactive) ─────────────────────────────────────────
  Stream<List<MedicationModel>> getAllMedications(String userId) {
    return _medicationsRef(userId).snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MedicationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  Future<bool> updateMedication(MedicationModel med) async {
    try {
      await _medicationsRef(med.userId).doc(med.id).update(med.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── SOFT DELETE (sets isActive: false) ────────────────────────────────────
  Future<bool> deleteMedication(String userId, String medicationId) async {
    try {
      await _medicationsRef(userId)
          .doc(medicationId)
          .update({'isActive': false});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── HARD DELETE ───────────────────────────────────────────────────────────
  Future<bool> permanentlyDelete(String userId, String medicationId) async {
    try {
      await _medicationsRef(userId).doc(medicationId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── LOG TAKEN ─────────────────────────────────────────────────────────────
  Future<void> logMedicationTaken(String userId, String medicationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medicationLogs')
          .add({
        'medicationId': medicationId,
        'takenAt': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().substring(0, 10),
      });
    } catch (e) {
      // Silent fail — not critical
    }
  }
}