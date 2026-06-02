// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/review_model.dart
// PURPOSE: A patient's rating + comment for a doctor, left after a consultation.
//          Stored in the top-level `reviews` collection. A cached aggregate
//          (avgRating, reviewCount) is maintained on the doctor's users doc.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final int rating;          // 1–5
  final String comment;
  final String consultationId;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.rating,
    required this.comment,
    this.consultationId = '',
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    final createdRaw = map['createdAt'];
    return ReviewModel(
      id: id,
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] ?? '',
      consultationId: map['consultationId'] ?? '',
      createdAt: createdRaw is Timestamp ? createdRaw.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'patientId': patientId,
        'patientName': patientName,
        'rating': rating,
        'comment': comment,
        'consultationId': consultationId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
