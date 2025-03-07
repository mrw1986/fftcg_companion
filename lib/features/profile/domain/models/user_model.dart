import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for storing user data in Firestore
class UserModel {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final Map<String, dynamic> settings;
  final Timestamp createdAt;
  final Timestamp lastLogin;

  UserModel({
    required this.id,
    this.displayName,
    this.email,
    this.photoURL,
    Map<String, dynamic>? settings,
    Timestamp? createdAt,
    Timestamp? lastLogin,
  })  : settings = settings ?? {},
        createdAt = createdAt ?? Timestamp.now(),
        lastLogin = lastLogin ?? Timestamp.now();

  /// Create a UserModel from a Map (usually from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return UserModel(
      id: id,
      displayName: map['displayName'],
      email: map['email'],
      photoURL: map['photoURL'],
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      lastLogin: map['lastLogin'] ?? Timestamp.now(),
    );
  }

  /// Convert UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'settings': settings,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  /// Create a copy of UserModel with some fields updated
  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    Map<String, dynamic>? settings,
    Timestamp? lastLogin,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
