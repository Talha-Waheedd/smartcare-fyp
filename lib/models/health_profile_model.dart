// Patient lifestyle and vitals for personalized recommendations.

class HealthProfileModel {
  final double weightKg;
  final double heightCm;
  final String activityLevel; // sedentary, light, moderate, active
  final double sleepHoursPerNight;
  final String smokingStatus; // never, former, current
  final List<String> chronicConditions;

  const HealthProfileModel({
    this.weightKg = 0,
    this.heightCm = 0,
    this.activityLevel = '',
    this.sleepHoursPerNight = 0,
    this.smokingStatus = '',
    this.chronicConditions = const [],
  });

  static const activityLevels = ['sedentary', 'light', 'moderate', 'active'];
  static const smokingStatuses = ['never', 'former', 'current'];

  static const chronicConditionOptions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Heart Disease',
    'Kidney Disease',
    'Anemia',
    'Anxiety',
    'Depression',
    'Other',
  ];

  factory HealthProfileModel.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const HealthProfileModel();
    return HealthProfileModel(
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0,
      activityLevel: map['activityLevel'] as String? ?? '',
      sleepHoursPerNight: (map['sleepHoursPerNight'] as num?)?.toDouble() ?? 0,
      smokingStatus: map['smokingStatus'] as String? ?? '',
      chronicConditions: List<String>.from(map['chronicConditions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'weightKg': weightKg,
        'heightCm': heightCm,
        'activityLevel': activityLevel,
        'sleepHoursPerNight': sleepHoursPerNight,
        'smokingStatus': smokingStatus,
        'chronicConditions': chronicConditions,
      };

  bool get hasVitals => weightKg > 0 && heightCm > 0;
}
