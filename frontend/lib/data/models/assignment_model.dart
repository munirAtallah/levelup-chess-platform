/// Data Tier — Model
/// Path: lib/data/models/assignment_model.dart
///
/// SECURITY REQUIREMENT: All assignments are text-based only.
/// No file-upload parameters are permitted in this model.
library;

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentType { text, multipleChoice }

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

String _extractTitle(String? content) {
  if (content == null || content.isEmpty) return 'Untitled Assignment';
  try {
    final decoded = jsonDecode(content);
    if (decoded is List && decoded.isNotEmpty) {
      final firstOp = decoded.first;
      if (firstOp is Map && firstOp.containsKey('insert')) {
        final text = firstOp['insert'] as String;
        final firstLine = text.split('\n').first;
        if (firstLine.trim().isNotEmpty) {
          return firstLine.trim();
        }
      }
    }
  } catch (_) {
    final firstLine = content.split('\n').first;
    if (firstLine.trim().isNotEmpty) {
      return firstLine.trim();
    }
  }
  return 'Untitled Assignment';
}

String _extractBody(String? content) {
  if (content == null || content.isEmpty) return '';
  try {
    final decoded = jsonDecode(content);
    if (decoded is List && decoded.length > 1) {
      final remainingOps = decoded.skip(1).toList();
      return jsonEncode(remainingOps);
    }
  } catch (_) {
    final lines = content.split('\n');
    if (lines.length > 1) {
      return lines.skip(1).join('\n').trim();
    }
  }
  return content;
}

String _mergeTitleAndContent(String title, String? body) {
  try {
    if (body != null && body.isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is List) {
        final titleOp = {
          'insert': '$title\n',
          'attributes': {'header': 1}
        };
        final merged = [titleOp, ...decoded];
        return jsonEncode(merged);
      }
    }
  } catch (_) {}
  return '$title\n${body ?? ""}';
}

class AssignmentModel {
  final String id;
  String title;
  String type; // 'central' or 'custom'
  bool isActive;
  String? groupName; // Display name (kept for UI convenience)
  String? groupId; // Firestore group document reference
  String? instructorId; // Firestore instructor uid reference
  String? levelId; // Firestore level reference (assigned target level)
  int pendingCount;
  int gradedCount;

  // New fields for Assignment System Specification
  final bool isVisible;        // admin can show/hide central assignments
  final String? imageUrl;      // optional image uploaded to Firebase Storage
  final int totalStudents;     // total students in the assigned group+level
  final int submittedCount;    // how many submitted
  final int correctCount;      // how many graded correct
  final int incorrectCount;    // how many graded incorrect
  final String? curriculumItemId; // original curriculum item id for central assignments

  /// Search tags for segmented-array Firestore queries.
  final List<String> searchTags;

  /// The date the assignment was created.
  final DateTime createdAt;

  /// The deadline for submission.
  final DateTime deadline;

  /// Text-based assignment content (the assignment prompt/body).
  final String? textContent;

  /// The type of assignment (text or multipleChoice).
  final AssignmentType assignmentType;

  /// The choices for a multiple choice assignment.
  final List<String>? choices;

  AssignmentModel({
    required this.id,
    required this.title,
    this.type = 'central',
    this.isActive = true,
    this.groupName,
    this.groupId,
    this.instructorId,
    this.levelId,
    this.pendingCount = 0,
    this.gradedCount = 0,
    this.isVisible = true,
    this.imageUrl,
    this.totalStudents = 0,
    this.submittedCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.curriculumItemId,
    this.searchTags = const [],
    required this.createdAt,
    required this.deadline,
    this.textContent,
    this.assignmentType = AssignmentType.text,
    this.choices,
  });

  /// Returns true if the deadline has passed.
  bool get isOverdue => DateTime.now().isAfter(deadline);

  /// Human-readable deadline label relative to now.
  String get deadlineText {
    final now = DateTime.now();
    final todayMidnight = DateTime.utc(now.year, now.month, now.day);
    final deadlineMidnight = DateTime.utc(deadline.year, deadline.month, deadline.day);
    final diffDays = deadlineMidnight.difference(todayMidnight).inDays;

    final timeStr = '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';

    if (deadline.isBefore(now)) {
      if (diffDays.abs() == 0) {
        return 'Overdue (today)';
      }
      return 'Overdue by ${diffDays.abs()}d';
    }

    if (diffDays == 0) {
      return 'Due today, $timeStr';
    }
    if (diffDays == 1) {
      return 'Tomorrow, $timeStr';
    }
    if (diffDays < 7) {
      return 'In $diffDays days';
    }
    return 'In ${(diffDays / 7).ceil()} weeks';
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawContent = map['content']?.toString() ?? map['textContent']?.toString() ?? '';
    final deadlineVal = _parseDate(map['deadline']) ?? DateTime.now();
    final createdAtVal = _parseDate(map['createdAt']) ?? DateTime.now();

    return AssignmentModel(
      id: documentId,
      title: map['title'] ?? _extractTitle(rawContent),
      type: map['type'] ?? (documentId.startsWith('ca_') ? 'central' : 'custom'),
      isActive: map['isActive'] ?? DateTime.now().isBefore(deadlineVal),
      groupName: map['groupName'],
      groupId: map['groupId'],
      instructorId: map['instructorId'],
      levelId: map['levelId'],
      pendingCount: map['pendingCount']?.toInt() ?? 0,
      gradedCount: map['gradedCount']?.toInt() ?? 0,
      isVisible: map['isVisible'] ?? true,
      imageUrl: map['imageUrl'],
      totalStudents: map['totalStudents']?.toInt() ?? 0,
      submittedCount: map['submittedCount']?.toInt() ?? 0,
      correctCount: map['correctCount']?.toInt() ?? 0,
      incorrectCount: map['incorrectCount']?.toInt() ?? 0,
      curriculumItemId: map['curriculumItemId'],
      searchTags: List<String>.from(map['searchTags'] ?? []),
      createdAt: createdAtVal,
      deadline: deadlineVal,
      textContent: _extractBody(rawContent),
      assignmentType: map['assignmentType'] == 'multipleChoice'
          ? AssignmentType.multipleChoice
          : AssignmentType.text,
      choices: map['choices'] != null ? List<String>.from(map['choices']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'groupName': groupName,
      'isActive': isActive,
      'groupId': groupId,
      'instructorId': instructorId,
      'levelId': levelId,
      'content': _mergeTitleAndContent(title, textContent),
      'searchTags': searchTags,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'assignmentType': assignmentType.name,
      'choices': choices,
      'isVisible': isVisible,
      'imageUrl': imageUrl,
      'totalStudents': totalStudents,
      'submittedCount': submittedCount,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'curriculumItemId': curriculumItemId,
    };
  }
}
