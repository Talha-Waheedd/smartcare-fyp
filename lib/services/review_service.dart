// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/review_service.dart
// PURPOSE: CRUD + queries for the `reviews` collection.
//   - Patient submits a review (1–5 stars + comment) for a doctor.
//   - A transaction updates the cached aggregate (avgRating, reviewCount) on
//     the doctor's users doc.
//   - Admin lists all reviews; patients/doctors list per-doctor reviews.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');

  // ── SUBMIT A REVIEW (with aggregate update) ───────────────────────────────
  Future<void> addReview(ReviewModel review) async {
    final reviewRef = _reviews.doc();
    final doctorRef = _db.collection('users').doc(review.doctorId);

    await _db.runTransaction((txn) async {
      final doctorSnap = await txn.get(doctorRef);
      final data = doctorSnap.data() ?? {};
      final currentCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
      final currentAvg = (data['avgRating'] as num?)?.toDouble() ?? 0;

      final newCount = currentCount + 1;
      final newAvg =
          ((currentAvg * currentCount) + review.rating) / newCount;

      txn.set(reviewRef, review.toMap());
      txn.update(doctorRef, {
        'avgRating': double.parse(newAvg.toStringAsFixed(2)),
        'reviewCount': newCount,
      });
    });
  }

  // ── HAS THE PATIENT ALREADY REVIEWED THIS CONSULTATION? ────────────────────
  Future<bool> hasReviewedConsultation(
      String patientId, String consultationId) async {
    if (consultationId.isEmpty) return false;
    final snap = await _reviews
        .where('patientId', isEqualTo: patientId)
        .where('consultationId', isEqualTo: consultationId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── ALL REVIEWS (admin) ────────────────────────────────────────────────────
  Stream<List<ReviewModel>> getAllReviews() {
    return _reviews.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ReviewModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── REVIEWS FOR ONE DOCTOR ──────────────────────────────────────────────────
  Stream<List<ReviewModel>> getDoctorReviews(String doctorId) {
    return _reviews
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ReviewModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
