// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/consultation_model.dart
// PURPOSE: Patient–doctor consultation booking and clinical notes.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

enum ConsultationStatus { active, completed, cancelled }

extension ConsultationStatusX on ConsultationStatus {
  String get value => name;

  static ConsultationStatus fromString(String? raw) {
    switch (raw) {
      case 'completed':
        return ConsultationStatus.completed;
      case 'cancelled':
        return ConsultationStatus.cancelled;
      default:
        return ConsultationStatus.active;
    }
  }
}

class ConsultationModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final DateTime consultationDate;
  final ConsultationStatus status;
  final String notes;
  final String diagnosis;
  final String followUpDate;
  final DateTime createdAt;

  const ConsultationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.consultationDate,
    required this.status,
    this.notes = '',
    this.diagnosis = '',
    this.followUpDate = '',
    required this.createdAt,
  });

  factory ConsultationModel.fromMap(Map<String, dynamic> map, String id) {
    final consultationDateRaw = map['consultationDate'];
    final createdAtRaw = map['createdAt'];
    final fallbackDate = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.now();

    return ConsultationModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      consultationDate: consultationDateRaw is Timestamp
          ? consultationDateRaw.toDate()
          : fallbackDate,
      status: ConsultationStatusX.fromString(map['status'] as String?),
      notes: map['notes'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      followUpDate: map['followUpDate'] ?? '',
      createdAt: fallbackDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'consultationDate': Timestamp.fromDate(consultationDate),
      'status': status.value,
      'notes': notes,
      'diagnosis': diagnosis,
      'followUpDate': followUpDate,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
