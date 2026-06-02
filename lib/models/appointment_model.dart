// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/appointment_model.dart
// PURPOSE: A scheduled appointment between a patient and a doctor. Stored in the
//          top-level `appointments` collection. The lifecycle is:
//            pending -> accepted | rejected | rescheduled -> completed | cancelled
//          A linked clinical-notes `consultations` doc may be created on accept.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  accepted,
  rejected,
  rescheduled,
  completed,
  cancelled,
}

extension AppointmentStatusX on AppointmentStatus {
  String get value => name;

  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.accepted:
        return 'Accepted';
      case AppointmentStatus.rejected:
        return 'Rejected';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  static AppointmentStatus fromString(String? raw) {
    switch (raw) {
      case 'accepted':
        return AppointmentStatus.accepted;
      case 'rejected':
        return AppointmentStatus.rejected;
      case 'rescheduled':
        return AppointmentStatus.rescheduled;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'pending':
      default:
        return AppointmentStatus.pending;
    }
  }
}

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final DateTime slotDate;       // date + start time of the slot
  final String slotLabel;        // e.g. "09:00 - 09:30"
  final AppointmentStatus status;
  final String reason;           // patient's reason for visit
  final String consultationId;   // optional linked clinical-notes doc
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.slotDate,
    required this.slotLabel,
    required this.status,
    this.reason = '',
    this.consultationId = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    final slotRaw = map['slotDate'];
    final createdRaw = map['createdAt'];
    final updatedRaw = map['updatedAt'];
    final now = DateTime.now();
    return AppointmentModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      slotDate: slotRaw is Timestamp ? slotRaw.toDate() : now,
      slotLabel: map['slotLabel'] ?? '',
      status: AppointmentStatusX.fromString(map['status'] as String?),
      reason: map['reason'] ?? '',
      consultationId: map['consultationId'] ?? '',
      createdAt: createdRaw is Timestamp ? createdRaw.toDate() : now,
      updatedAt: updatedRaw is Timestamp ? updatedRaw.toDate() : now,
    );
  }

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'slotDate': Timestamp.fromDate(slotDate),
        'slotLabel': slotLabel,
        'status': status.value,
        'reason': reason,
        'consultationId': consultationId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
