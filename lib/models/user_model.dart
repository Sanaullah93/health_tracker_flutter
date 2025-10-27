import 'dart:convert';

HealthTracker healthTrackerFromJson(String str) =>
    HealthTracker.fromMap(json.decode(str));

String healthTrackerToJson(HealthTracker data) => json.encode(data.toMap());

class HealthTracker {
  String uid;
  String name;
  String email;
  DateTime createdAt;
  String? age;
  String? gender;
  String? height;
  String? weight;
  String? activityLevel;
  String? healthGoals;
  String? allergies;

  HealthTracker({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.healthGoals,
    this.allergies,
  });

  // Firestore me save karne ke liye
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (activityLevel != null) 'activityLevel': activityLevel,
      if (healthGoals != null) 'healthGoals': healthGoals,
      if (allergies != null) 'allergies': allergies,
    };
  }

  // Firestore se read karne ke liye
  factory HealthTracker.fromMap(Map<String, dynamic> map) {
    return HealthTracker(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      createdAt: DateTime.parse(map['createdAt']),
      age: map['age'],
      gender: map['gender'],
      height: map['height'],
      weight: map['weight'],
      activityLevel: map['activityLevel'],
      healthGoals: map['healthGoals'],
      allergies: map['allergies'],
    );
  }

  // JSON conversion ke liye (optional)
  Map<String, dynamic> toJson() => toMap();

  factory HealthTracker.fromJson(Map<String, dynamic> json) =>
      HealthTracker.fromMap(json);
}
