/// Data Tier — Model
/// Path: lib/data/models/group_model.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Embedded student object stored inside a GroupModel document.
class GroupStudentEmbed {
  final String id;
  final String name;
  final String level; // levelId, e.g. 'l1'
  final DateTime? lastActive;

  const GroupStudentEmbed({
    required this.id,
    required this.name,
    required this.level,
    this.lastActive,
  });

  factory GroupStudentEmbed.fromMap(Map<String, dynamic> map) {
    return GroupStudentEmbed(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      level: map['level'] ?? '',
      lastActive: _parseDate(map['lastActive']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'lastActive': lastActive?.toIso8601String(),
    };
  }
}

/// Safely parses a date value that may be a Firestore Timestamp, a String, or null.
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

class GroupModel {
  final String id;
  final String _groupNumberStr;
  final String name;
  final List<String> instructorIds;
  final DateTime createdAt;
  final bool isArchived;
  final DateTime? archivedAt;

  /// Embedded student objects for optimised local reads.
  final List<GroupStudentEmbed> students;

  /// Curriculum material IDs shared with this group by the instructor.
  final List<String> sharedMaterialIds;

  /// Academic level IDs explicitly set on this group.
  final List<String> levelIds;

  GroupModel({
    required this.id,
    int? serialNumber,
    String? groupNumber,
    required this.name,
    required this.createdAt,
    this.isArchived = false,
    this.archivedAt,
    this.instructorIds = const [],
    this.students = const [],
    this.sharedMaterialIds = const [],
    this.levelIds = const [],
  }) : _groupNumberStr = groupNumber ?? serialNumber?.toString() ?? '0';

  // Backward-compatibility getter
  int get serialNumber => int.tryParse(_groupNumberStr) ?? 0;

  /// Derived map of studentId → levelId for backward-compatible lookups.
  Map<String, String> get studentLevels =>
      Map.fromEntries(students.map((s) => MapEntry(s.id, s.level)));

  /// All student IDs in this group.
  List<String> get studentIds => students.map((s) => s.id).toList();

  /// The distinct levels present in this group.
  Set<String> get activeLevels => students.map((s) => s.level).toSet();

  factory GroupModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GroupModel(
      id: documentId,
      groupNumber: map['groupNumber']?.toString() ?? map['serialNumber']?.toString() ?? '0',
      name: map['name'] ?? '',
      instructorIds: List<String>.from(map['instructorIds'] ?? []),
      students: (map['students'] as List<dynamic>?)
              ?.map((s) => GroupStudentEmbed.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      sharedMaterialIds: List<String>.from(map['sharedMaterialIds'] ?? []),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: _parseDate(map['archivedAt']),
      levelIds: List<String>.from(map['levelIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupNumber': _groupNumberStr,
      'name': name,
      'instructorIds': instructorIds,
      'students': students.map((s) => s.toMap()).toList(),
      'sharedMaterialIds': sharedMaterialIds,
      'createdAt': createdAt.toIso8601String(),
      'isArchived': isArchived,
      if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
      'levelIds': levelIds,
    };
  }
}
