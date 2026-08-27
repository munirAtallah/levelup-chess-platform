/// Data Tier — Model
/// Path: lib/data/models/group_model.dart
library;

/// Embedded student object stored inside a GroupModel document.
/// Optimises local reads by avoiding a separate users collection lookup
/// for basic group-roster information.
class GroupStudentEmbed {
  final String id;
  final String name;
  final String level; // levelId, e.g. 'l1'
  final String pin;
  final DateTime? lastActive;

  const GroupStudentEmbed({
    required this.id,
    required this.name,
    required this.level,
    required this.pin,
    this.lastActive,
  });

  factory GroupStudentEmbed.fromMap(Map<String, dynamic> map) {
    return GroupStudentEmbed(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      level: map['level'] ?? '',
      pin: map['pin'] ?? '',
      lastActive: map['lastActive'] != null
          ? DateTime.parse(map['lastActive'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'pin': pin,
      'lastActive': lastActive?.toIso8601String(),
    };
  }
}

class GroupModel {
  final String id;
  final int serialNumber; // groupNumber in schema
  final String name;
  final List<String> instructorIds;
  final DateTime createdAt;

  /// Embedded student objects for optimised local reads.
  final List<GroupStudentEmbed> students;

  GroupModel({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.createdAt,
    this.instructorIds = const [],
    this.students = const [],
  });

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
      serialNumber: map['serialNumber'] ?? 0,
      name: map['name'] ?? '',
      instructorIds: List<String>.from(map['instructorIds'] ?? []),
      students: (map['students'] as List<dynamic>?)
              ?.map((s) => GroupStudentEmbed.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serialNumber': serialNumber,
      'name': name,
      'instructorIds': instructorIds,
      'students': students.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
