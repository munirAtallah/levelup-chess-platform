/// Data Tier — Model
/// Path: lib/data/models/student_profile_model.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDate(dynamic value) {
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

class StudentProfile {
  final String id;
  final String name;
  final String username;
  final String studentId;
  final String level;
  final String group;
  final String instructorName;
  final int submissions;
  final int graded;
  final int correct;

  /// Student-specific fields added for Phase 1.
  final String? studentNumber; // e.g., "#1005"
  final String? pinCode; // e.g., "9575"
  final DateTime? lastActive; // Tracks online status

  // New fields for detailed lookup
  final String? groupId;
  final String? levelId;

  StudentProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.studentId,
    required this.level,
    required this.group,
    required this.instructorName,
    this.submissions = 0,
    this.graded = 0,
    this.correct = 0,
    this.studentNumber,
    this.pinCode,
    this.lastActive,
    this.groupId,
    this.levelId,
  });

  /// Returns true if the student was active within the last 5 minutes.
  bool get isOnline {
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive!).inMinutes < 5;
  }

  /// Returns a human-readable label for the student's last activity.
  String get lastActiveLabel {
    if (lastActive == null) return 'Never';
    final diff = DateTime.now().difference(lastActive!);
    if (diff.inMinutes < 5) return 'Online';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return StudentProfile(
      id: documentId,
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      studentId: map['studentId'] ?? '',
      level: map['level'] ?? '',
      group: map['group'] ?? '',
      instructorName: map['instructorName'] ?? 'Unknown Instructor',
      submissions: map['submissions']?.toInt() ?? 0,
      graded: map['graded']?.toInt() ?? 0,
      correct: map['correct']?.toInt() ?? 0,
      studentNumber: map['studentNumber'],
      pinCode: map['pinCode'],
      lastActive: _parseDate(map['lastActive']),
      groupId: map['groupId'],
      levelId: map['levelId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'studentId': studentId,
      'level': level,
      'group': group,
      'submissions': submissions,
      'graded': graded,
      'correct': correct,
      'studentNumber': studentNumber,
      'pinCode': pinCode,
      'lastActive': lastActive?.toIso8601String(),
      'groupId': groupId,
      'levelId': levelId,
    };
  }

  /// Returns the first letters of the name for avatar display.
  String get initials {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}
