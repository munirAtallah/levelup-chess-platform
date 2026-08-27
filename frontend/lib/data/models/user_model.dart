/// Data Tier — Model
/// Path: lib/data/models/user_model.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, instructor, student }

class UserModel {
  final String id;
  final String _userNumberStr;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final UserRole role;
  final List<String> assignedLevels;
  final List<String> searchKeywords;
  final String? levelId;
  final String? studentNumber;
  final String? username;
  final String? pinCode;
  final DateTime? lastActive;
  final bool isArchived;
  final DateTime? createdAt;
  final String? groupId;
  final String? createdBy;
  final String? gender;        // 'male' or 'female'
  final DateTime? dateOfBirth;
  final String? location;      // city/neighborhood name
  final String? idNumber;      // instructors only, 9 digits

  UserModel({
    required this.id,
    int? userNumber,
    String? userNumberStr,
    String? name,
    String? displayName,
    this.email,
    this.phoneNumber,
    required this.role,
    this.assignedLevels = const [],
    this.searchKeywords = const [],
    this.levelId,
    this.studentNumber,
    this.username,
    this.pinCode,
    this.lastActive,
    this.isArchived = false,
    this.createdAt,
    this.groupId,
    this.createdBy,
    this.gender,
    this.dateOfBirth,
    this.location,
    this.idNumber,
  }) : _userNumberStr = userNumberStr ?? userNumber?.toString() ?? '0',
       displayName = displayName ?? name ?? '';

  // Backward-compatibility getters to prevent breaking the rest of the application
  String get name => displayName;
  int get userNumber => int.tryParse(_userNumberStr) ?? 0;

  bool get isOnline {
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive!).inMinutes < 5;
  }

  String get lastActiveLabel {
    if (lastActive == null) return 'Never';
    final diff = DateTime.now().difference(lastActive!);
    if (diff.inMinutes < 5) return 'Online';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    UserRole parsedRole = UserRole.student;
    if (map['role'] == 'admin') parsedRole = UserRole.admin;
    if (map['role'] == 'instructor') parsedRole = UserRole.instructor;

    final userNumStr = map['userNumber']?.toString() ?? '0';

    return UserModel(
      id: documentId,
      userNumberStr: userNumStr,
      displayName: map['displayName'] ?? map['name'] ?? '',
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      role: parsedRole,
      assignedLevels: List<String>.from(map['assignedLevels'] ?? []),
      searchKeywords: List<String>.from(map['searchKeywords'] ?? []),
      levelId: map['levelId'],
      studentNumber: map['studentNumber'] ?? '#$userNumStr',
      username: map['username'],
      pinCode: map['pinCode'],
      lastActive: _parseTimestamp(map['lastActive']),
      isArchived: map['isArchived'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      groupId: map['groupId'] as String?,
      createdBy: map['createdBy'] as String?,
      gender: map['gender'] as String?,
      dateOfBirth: _parseTimestamp(map['dateOfBirth']),
      location: map['location'] as String?,
      idNumber: map['idNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'phoneNumber': phoneNumber,
      'userNumber': _userNumberStr,
      'email': email,
      'displayName': displayName,
      'username': username,
      'searchKeywords': searchKeywords,
      'levelId': levelId,
      'pinCode': pinCode,
      'assignedLevels': assignedLevels,
      'studentNumber': studentNumber,
      'lastActive': lastActive?.toIso8601String(),
      'isArchived': isArchived,
      'createdAt': createdAt?.toIso8601String(),
      'groupId': groupId,
      'createdBy': createdBy,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'location': location,
      'idNumber': idNumber,
    };
  }

  UserModel copyWith({
    String? id,
    String? userNumberStr,
    String? name,
    String? displayName,
    String? email,
    String? phoneNumber,
    UserRole? role,
    List<String>? assignedLevels,
    List<String>? searchKeywords,
    String? levelId,
    String? studentNumber,
    String? username,
    String? pinCode,
    DateTime? lastActive,
    bool? isArchived,
    DateTime? createdAt,
    String? groupId,
    String? createdBy,
    String? gender,
    DateTime? dateOfBirth,
    String? location,
    String? idNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      userNumberStr: userNumberStr ?? _userNumberStr,
      displayName: displayName ?? this.displayName,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      assignedLevels: assignedLevels ?? this.assignedLevels,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      levelId: levelId ?? this.levelId,
      studentNumber: studentNumber ?? this.studentNumber,
      username: username ?? this.username,
      pinCode: pinCode ?? this.pinCode,
      lastActive: lastActive ?? this.lastActive,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      idNumber: idNumber ?? this.idNumber,
    );
  }
}

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}
