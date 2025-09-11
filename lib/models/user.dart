// lib/models/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String username;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final DateTime? lastProfileImageChange;
  final String? bio;
  final bool isActive;
  final bool isVerified;
  final bool hasPendingVerification;

  User({
    required this.uid,
    required this.email,
    required this.username,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.lastProfileImageChange,
    this.bio,
    this.isActive = true,
    this.isVerified = false,
    this.hasPendingVerification = false,
  });

  // Erstelle User aus Firestore-Daten
  factory User.fromMap(Map<String, dynamic> data, String documentId) {
    return User(
      uid: data['uid'] ?? documentId,
      email: data['email'] ?? '',
      username: data['username'] ?? 'Anonymous',
      profileImageUrl: data['profileImageUrl'],
      createdAt: data['createdAt'] is Timestamp 
          ? data['createdAt'].toDate() 
          : data['createdAt'],
      updatedAt: data['updatedAt'] is Timestamp 
          ? data['updatedAt'].toDate() 
          : data['updatedAt'],
      lastLogin: data['lastLogin'] is Timestamp 
          ? data['lastLogin'].toDate() 
          : data['lastLogin'],
      lastProfileImageChange: data['lastProfileImageChange'] is Timestamp 
          ? data['lastProfileImageChange'].toDate() 
          : data['lastProfileImageChange'],
      bio: data['bio'],
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      hasPendingVerification: data['hasPendingVerification'] ?? false,
    );
  }

  // Konvertiere User zu Map für Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'lastProfileImageChange': lastProfileImageChange != null 
          ? Timestamp.fromDate(lastProfileImageChange!) 
          : null,
      'bio': bio,
      'isActive': isActive,
      'isVerified': isVerified,
      'hasPendingVerification': hasPendingVerification,
    };
  }

  // Kopiere User mit neuen Werten (für Updates)
  User copyWith({
    String? uid,
    String? email,
    String? username,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    DateTime? lastProfileImageChange,
    String? bio,
    bool? isActive,
    bool? isVerified,
    bool? hasPendingVerification,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      lastProfileImageChange: lastProfileImageChange ?? this.lastProfileImageChange,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      hasPendingVerification: hasPendingVerification ?? this.hasPendingVerification,
    );
  }
}