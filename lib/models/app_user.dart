import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String role; // "student" or "staff"
  final bool notifyStatusUpdates;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.notifyStatusUpdates = true,
    this.createdAt,
  });

  bool get isStaff => role == AppConstants.roleStaff;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? AppConstants.roleStudent,
      notifyStatusUpdates: data['notifyStatusUpdates'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toNewUserMap() => {
    'fullName': fullName,
    'email': email,
    'role': role,
    'notifyStatusUpdates': notifyStatusUpdates,
    'createdAt': FieldValue.serverTimestamp(),
  };

  AppUser copyWith({String? fullName, bool? notifyStatusUpdates}) => AppUser(
    uid: uid,
    fullName: fullName ?? this.fullName,
    email: email,
    role: role,
    notifyStatusUpdates: notifyStatusUpdates ?? this.notifyStatusUpdates,
    createdAt: createdAt,
  );
}
