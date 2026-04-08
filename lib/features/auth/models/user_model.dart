import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String studentId;
  final String role;
  final String email;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.studentId,
    required this.role,
    required this.email,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '??';
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      studentId: data['studentId'] ?? '',
      role: data['role'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'studentId': studentId,
        'role': role,
        'email': email,
      };

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? studentId,
    String? role,
    String? email,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        fullName: fullName ?? this.fullName,
        studentId: studentId ?? this.studentId,
        role: role ?? this.role,
        email: email ?? this.email,
      );
}
