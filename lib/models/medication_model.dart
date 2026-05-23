// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/medication_model.dart
// PURPOSE: Data model for a patient's medication entry stored in Firestore.
// ─────────────────────────────────────────────────────────────────────────────

class MedicationModel {
  final String id;           // Firestore document ID
  final String userId;       // Patient UID (owner)
  final String name;         // e.g. "Paracetamol"
  final String dosage;       // e.g. "500mg"
  final String frequency;    // e.g. "Twice a day"
  final List<String> times;  // e.g. ["08:00", "20:00"]
  final String instructions; // e.g. "Take after meal"
  final bool isActive;       // false = stopped/completed
  final DateTime createdAt;

  const MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.instructions,
    required this.isActive,
    required this.createdAt,
  });

  /// Build from Firestore document
  factory MedicationModel.fromMap(Map<String, dynamic> map, String id) {
    return MedicationModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      times: List<String>.from(map['times'] ?? []),
      instructions: map['instructions'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'])?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'instructions': instructions,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  MedicationModel copyWith({
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    String? instructions,
    bool? isActive,
  }) {
    return MedicationModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}