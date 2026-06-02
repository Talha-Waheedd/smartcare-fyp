// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/appointment_service.dart
// PURPOSE: CRUD + queries for the `appointments` collection.
//   - Patient creates an appointment request (pending).
//   - Doctor accepts / rejects / reschedules / completes.
//   - Streams scoped by doctor or patient.
//   - Helper to find taken slots for a doctor on a given day (booking UI).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _appts =>
      _db.collection('appointments');

  // ── CREATE (patient request) ───────────────────────────────────────────────
  Future<String> createAppointment(AppointmentModel appointment) async {
    final ref = await _appts.add(appointment.toMap());
    return ref.id;
  }

  // ── DOCTOR'S APPOINTMENTS ──────────────────────────────────────────────────
  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    if (doctorId.isEmpty) return Stream.value([]);
    return _appts
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AppointmentModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.slotDate.compareTo(a.slotDate));
      return list;
    });
  }

  // ── PATIENT'S APPOINTMENTS ──────────────────────────────────────────────────
  Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
    if (patientId.isEmpty) return Stream.value([]);
    return _appts
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AppointmentModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.slotDate.compareTo(a.slotDate));
      return list;
    });
  }

  // ── UPDATE STATUS ───────────────────────────────────────────────────────────
  Future<void> updateStatus(String id, AppointmentStatus status) async {
    await _appts.doc(id).update({
      'status': status.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── RESCHEDULE ────────────────────────────────────────────────────────────
  Future<void> reschedule(
      String id, DateTime newSlotDate, String newSlotLabel) async {
    await _appts.doc(id).update({
      'slotDate': Timestamp.fromDate(newSlotDate),
      'slotLabel': newSlotLabel,
      'status': AppointmentStatus.rescheduled.value,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── TAKEN SLOT LABELS FOR A DOCTOR ON A SPECIFIC DAY ───────────────────────
  /// Returns slot labels already booked (non-rejected/cancelled) for [day].
  Future<Set<String>> getTakenSlotLabels(String doctorId, DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _appts
        .where('doctorId', isEqualTo: doctorId)
        .where('slotDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('slotDate', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs
        .where((d) {
          final status = d.data()['status'] as String?;
          return status != AppointmentStatus.rejected.value &&
              status != AppointmentStatus.cancelled.value;
        })
        .map((d) => (d.data()['slotLabel'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();
  }
}
