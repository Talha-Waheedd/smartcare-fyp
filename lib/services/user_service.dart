// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/services/user_service.dart
// PURPOSE: Firestore operations for the `users` collection profile data:
//   - Fetch a single user (stream + one-shot)
//   - Update patient / doctor profile fields
//   - Update doctor weekly availability (schedule)
//   - Query active doctors (for search / booking)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── STREAM A SINGLE USER ─────────────────────────────────────────────────
  Stream<UserModel?> streamUser(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  // ── ONE-SHOT FETCH ────────────────────────────────────────────────────────
  Future<UserModel?> getUser(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // ── UPDATE PROFILE FIELDS ──────────────────────────────────────────────────
  /// Updates only the provided fields on the user document.
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    await _users.doc(uid).update(data);
  }

  // ── UPDATE DOCTOR AVAILABILITY (schedule) ──────────────────────────────────
  Future<void> updateAvailability(
    String uid, {
    required Map<String, dynamic> availability,
    required int slotDurationMinutes,
  }) async {
    if (uid.isEmpty) return;
    await _users.doc(uid).update({
      'availability': availability,
      'slotDurationMinutes': slotDurationMinutes,
    });
  }

  // ── ACTIVE DOCTORS (search / booking) ──────────────────────────────────────
  Stream<List<UserModel>> getActiveDoctors() {
    return _users
        .where('role', isEqualTo: 'doctor')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => UserModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }
}
