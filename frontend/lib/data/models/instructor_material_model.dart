/// Data Tier — Model
/// Path: lib/data/models/instructor_material_model.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class InstructorMaterialModel {
  final String id;
  final String title;
  final String? content;       // Quill delta JSON
  final String? deltaJson;     // same as content, kept for compat
  final List<Map<String, String>> attachments;
  final String instructorId;
  final String groupId;
  final String levelId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVisible;
  final List<String> searchKeywords;

  const InstructorMaterialModel({
    required this.id,
    required this.title,
    this.content,
    this.deltaJson,
    this.attachments = const [],
    required this.instructorId,
    required this.groupId,
    required this.levelId,
    required this.createdAt,
    required this.updatedAt,
    this.isVisible = true,
    this.searchKeywords = const [],
  });

  factory InstructorMaterialModel.fromMap(Map<String, dynamic> map, String id) {
    return InstructorMaterialModel(
      id: id,
      title: map['title'] as String? ?? '',
      content: map['content'] as String?,
      deltaJson: map['deltaJson'] as String? ?? map['content'] as String?,
      attachments: map['attachments'] != null
          ? (map['attachments'] as List<dynamic>)
              .map((a) => Map<String, String>.from(a as Map))
              .toList()
          : const [],
      instructorId: map['instructorId'] as String? ?? '',
      groupId: map['groupId'] as String? ?? '',
      levelId: map['levelId'] as String? ?? '',
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(map['updatedAt']) ?? DateTime.now(),
      isVisible: map['isVisible'] as bool? ?? true,
      searchKeywords: List<String>.from(map['searchKeywords'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content ?? deltaJson,
      'deltaJson': deltaJson ?? content,
      'attachments': attachments,
      'instructorId': instructorId,
      'groupId': groupId,
      'levelId': levelId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVisible': isVisible,
      'searchKeywords': searchKeywords,
    };
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
