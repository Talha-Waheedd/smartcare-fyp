// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/prescription_model.dart
// PURPOSE: Represents a prescription created by a doctor.
// ⚠️  IMPORTANT: Only doctors can create prescriptions (SRS medical constraint).
//     AI must never generate prescriptions.
// ─────────────────────────────────────────────────────────────────────────────

class PrescribedMedicine {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;    // e.g. "7 days", "1 month"
  final String instructions;

  const PrescribedMedicine({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });

  factory PrescribedMedicine.fromMap(Map<String, dynamic> map) {
    return PrescribedMedicine(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? '',
      instructions: map['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
      };
}

class PrescriptionModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final List<PrescribedMedicine> medicines;
  final String notes;           // General prescription notes
  final String validUntil;      // Date string "YYYY-MM-DD"
  final DateTime createdAt;

  const PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.medicines,
    required this.notes,
    required this.validUntil,
    required this.createdAt,
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> map, String id) {
    final medicinesList = (map['medicines'] as List<dynamic>? ?? [])
        .map((m) => PrescribedMedicine.fromMap(m as Map<String, dynamic>))
        .toList();

    return PrescriptionModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      medicines: medicinesList,
      notes: map['notes'] ?? '',
      validUntil: map['validUntil'] ?? '',
      createdAt: (map['createdAt'])?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'medicines': medicines.map((m) => m.toMap()).toList(),
        'notes': notes,
        'validUntil': validUntil,
        'createdAt': createdAt,
      };
}