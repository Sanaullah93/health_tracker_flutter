import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String age;
  final String gender;
  final String height;
  final String weight;
  final String activityLevel;
  final String healthGoals;
  final String signInMethod;
  final String? photoURL;
  final String? phone; // Nullable
  final DateTime? lastLogin; // Nullable
  final bool isEmailVerified;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.healthGoals,
    this.signInMethod = 'email',
    this.photoURL,
    this.phone, // Optional
    DateTime? lastLogin, // Optional
    this.isEmailVerified = false, // Default false
    DateTime? updatedAt, // Optional
  }) : lastLogin = lastLogin ?? createdAt,
       updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'healthGoals': healthGoals,
      'signInMethod': signInMethod,
      'photoURL': photoURL,
      'phone': phone,
      'lastLogin': lastLogin,
      'isEmailVerified': isEmailVerified,
      'updatedAt': updatedAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      age: map['age'] ?? '',
      gender: map['gender'] ?? 'Male',
      height: map['height'] ?? '',
      weight: map['weight'] ?? '',
      activityLevel: map['activityLevel'] ?? 'Moderate',
      healthGoals: map['healthGoals'] ?? 'Weight Loss',
      signInMethod: map['signInMethod'] ?? 'email',
      photoURL: map['photoURL'],
      phone: map['phone'],
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
      isEmailVerified: map['isEmailVerified'] ?? false,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? createdAt,
    String? age,
    String? gender,
    String? height,
    String? weight,
    String? activityLevel,
    String? healthGoals,
    String? signInMethod,
    String? photoURL,
    String? phone,
    DateTime? lastLogin,
    bool? isEmailVerified,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      healthGoals: healthGoals ?? this.healthGoals,
      signInMethod: signInMethod ?? this.signInMethod,
      photoURL: photoURL ?? this.photoURL,
      phone: phone ?? this.phone,
      lastLogin: lastLogin ?? this.lastLogin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to check if profile is complete
  bool get isProfileComplete {
    return age.isNotEmpty &&
        gender.isNotEmpty &&
        height.isNotEmpty &&
        weight.isNotEmpty;
  }

  // Convert to display string
  @override
  String toString() {
    return 'UserModel{uid: $uid, name: $name, email: $email}';
  }

  // For Firestore queries
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'healthGoals': healthGoals,
      'signInMethod': signInMethod,
      'photoURL': photoURL,
      'phone': phone,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isEmailVerified': isEmailVerified,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Static method to create empty user
  static UserModel empty() {
    return UserModel(
      uid: '',
      name: '',
      email: '',
      createdAt: DateTime.now(),
      age: '',
      gender: 'Male',
      height: '',
      weight: '',
      activityLevel: 'Moderate',
      healthGoals: 'Weight Loss',
      signInMethod: 'email',
      phone: null,
      lastLogin: null,
      isEmailVerified: false,
      updatedAt: DateTime.now(),
    );
  }
}
