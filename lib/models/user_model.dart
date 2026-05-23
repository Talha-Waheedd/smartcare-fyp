// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/user_model.dart
// PURPOSE: Defines the UserModel data class and UserRole enum used throughout
//          the app. Roles are fetched from Firestore after login — users NEVER
//          select their own role (RBAC requirement from SRS Section 7).
// ─────────────────────────────────────────────────────────────────────────────

/// Enum representing the three roles defined in the SRS.
/// - patient  → self-registered, limited access
/// - doctor   → added by Admin only, clinical access
/// - admin    → full system access
enum UserRole { patient, doctor, admin }

/// Extension to convert a Firestore role string → UserRole enum
extension UserRoleExtension on String {
  UserRole toUserRole() {
    switch (toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }
}

/// Core user model stored in Firestore → collection: `users`
class UserModel {
  final String uid;          // Firebase Auth UID (primary key)
  final String name;         // Full name
  final String email;        // Email address
  final UserRole role;       // Assigned role (patient / doctor / admin)
  final DateTime createdAt;  // Account creation timestamp
  final bool isActive;       // Admin can deactivate accounts

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  /// Create a UserModel from a Firestore document snapshot
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: (map['role'] as String? ?? 'patient').toUserRole(),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Convert UserModel → Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,           // Stores "patient", "doctor", or "admin"
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  /// Helper: human-readable role label
  String get roleLabel {
    switch (role) {
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.admin:
        return 'Admin';
      case UserRole.patient:
        return 'Patient';
    }
  }

  /// Create a copy with updated fields (useful for profile editing)
  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}