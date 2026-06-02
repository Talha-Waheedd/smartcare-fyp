// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/user_model.dart
// PURPOSE: Defines the UserModel data class and UserRole enum used throughout
//          the app. Roles are fetched from Firestore after login — users NEVER
//          select their own role (RBAC requirement from SRS Section 7).
//
//          The model also carries optional PROFILE fields:
//          - Patient profile: phone, address, dateOfBirth, gender, bloodGroup,
//            allergies, emergencyContact.
//          - Doctor profile: specialization, experienceYears, bio,
//            qualifications, clinicLocation, consultationFee, availability map,
//            slotDurationMinutes, plus cached review aggregate (avgRating,
//            reviewCount).
//          All profile fields are optional for backward compatibility with
//          documents created before profiles existed.
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

  // ── Shared profile ─────────────────────────────────────────────────────────
  final String phone;
  final String photoUrl;

  // ── Patient profile ──────────────────────────────────────────────────────
  final String address;
  final String dateOfBirth;     // Stored as "YYYY-MM-DD" or display string
  final String gender;
  final String bloodGroup;
  final String allergies;       // Comma-separated / free text
  final String emergencyContact;

  // ── Doctor profile ─────────────────────────────────────────────────────────
  final String specialization;
  final int experienceYears;
  final String bio;
  final String qualifications;
  final String clinicLocation;
  final String consultationFee;

  /// Weekly availability map, e.g.
  /// { "mon": {"enabled": true, "start": "09:00", "end": "17:00"}, ... }
  final Map<String, dynamic> availability;
  final int slotDurationMinutes;

  // ── Cached review aggregate (doctors) ───────────────────────────────────────
  final double avgRating;
  final int reviewCount;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.phone = '',
    this.photoUrl = '',
    this.address = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.bloodGroup = '',
    this.allergies = '',
    this.emergencyContact = '',
    this.specialization = '',
    this.experienceYears = 0,
    this.bio = '',
    this.qualifications = '',
    this.clinicLocation = '',
    this.consultationFee = '',
    this.availability = const {},
    this.slotDurationMinutes = 30,
    this.avgRating = 0,
    this.reviewCount = 0,
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
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      address: map['address'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      allergies: map['allergies'] ?? '',
      emergencyContact: map['emergencyContact'] ?? '',
      specialization: map['specialization'] ?? '',
      experienceYears: (map['experienceYears'] as num?)?.toInt() ?? 0,
      bio: map['bio'] ?? '',
      qualifications: map['qualifications'] ?? '',
      clinicLocation: map['clinicLocation'] ?? '',
      consultationFee: map['consultationFee']?.toString() ?? '',
      availability: (map['availability'] as Map<String, dynamic>?) ?? const {},
      slotDurationMinutes: (map['slotDurationMinutes'] as num?)?.toInt() ?? 30,
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
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
      'phone': phone,
      'photoUrl': photoUrl,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'emergencyContact': emergencyContact,
      'specialization': specialization,
      'experienceYears': experienceYears,
      'bio': bio,
      'qualifications': qualifications,
      'clinicLocation': clinicLocation,
      'consultationFee': consultationFee,
      'availability': availability,
      'slotDurationMinutes': slotDurationMinutes,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
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
    String? phone,
    String? photoUrl,
    String? address,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? allergies,
    String? emergencyContact,
    String? specialization,
    int? experienceYears,
    String? bio,
    String? qualifications,
    String? clinicLocation,
    String? consultationFee,
    Map<String, dynamic>? availability,
    int? slotDurationMinutes,
    double? avgRating,
    int? reviewCount,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      specialization: specialization ?? this.specialization,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      qualifications: qualifications ?? this.qualifications,
      clinicLocation: clinicLocation ?? this.clinicLocation,
      consultationFee: consultationFee ?? this.consultationFee,
      availability: availability ?? this.availability,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
