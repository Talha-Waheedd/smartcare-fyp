// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/consultation_model.dart
// PURPOSE: Represents a consultation note written by a doctor for a patient.
// ─────────────────────────────────────────────────────────────────────────────

class ConsultationModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String notes;           // Doctor's clinical notes
  final String diagnosis;       // Diagnosis summary
  final String followUpDate;    // e.g. "2025-02-15"
  final DateTime createdAt;

  const ConsultationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.notes,
    required this.diagnosis,
    required this.followUpDate,
    required this.createdAt,
  });

  factory ConsultationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConsultationModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      notes: map['notes'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      followUpDate: map['followUpDate'] ?? '',
      createdAt: (map['createdAt'])?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'notes': notes,
      'diagnosis': diagnosis,
      'followUpDate': followUpDate,
      'createdAt': createdAt,
    };
  }
}