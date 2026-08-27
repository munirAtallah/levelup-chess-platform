/// Data Tier — Model
/// Path: lib/data/models/curriculum_model.dart
library;

enum CurriculumItemType { material, assignment }

class CurriculumItem {
  final String id;
  final CurriculumItemType type;
  String title;
  String? content;
  List<String> searchTags;
  bool visible;
  bool isActive;
  String deadlineText;
  final String? imageUrl;
  String? deltaJson;
  List<Map<String, String>> attachments;

  // New fields for Central Assignments MCQ support
  final String? assignmentType; // 'text' or 'multipleChoice'
  final List<String>? choices;

  CurriculumItem({
    this.id = '',
    required this.type,
    required this.title,
    this.content,
    this.searchTags = const [],
    this.visible = true,
    this.isActive = true,
    this.deadlineText = 'No deadline',
    this.imageUrl,
    this.deltaJson,
    this.attachments = const [],
    this.assignmentType,
    this.choices,
  });

  factory CurriculumItem.fromMap(Map<String, dynamic> map) {
    return CurriculumItem(
      id: map['id'] ?? '',
      type: map['type'] == 'assignment' ? CurriculumItemType.assignment : CurriculumItemType.material,
      title: map['title'] ?? '',
      content: map['content'],
      searchTags: List<String>.from(map['searchTags'] ?? []),
      visible: map['visible'] ?? true,
      isActive: map['isActive'] ?? true,
      deadlineText: map['deadlineText'] ?? 'No deadline',
      imageUrl: map['imageUrl'],
      deltaJson: map['deltaJson'],
      attachments: map['attachments'] != null
          ? (map['attachments'] as List<dynamic>)
              .map((a) => Map<String, String>.from(a as Map))
              .toList()
          : (map['attachmentPath'] != null
              ? [{'path': map['attachmentPath'] as String, 'name': map['attachmentName'] as String? ?? '', 'type': map['attachmentType'] as String? ?? 'pdf'}]
              : []),
      assignmentType: map['assignmentType'],
      choices: map['choices'] != null ? List<String>.from(map['choices']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'searchTags': searchTags,
      'visible': visible,
      'isActive': isActive,
      'deadlineText': deadlineText,
      'imageUrl': imageUrl,
      'deltaJson': deltaJson,
      'attachments': attachments.map((a) => a).toList(),
      'assignmentType': assignmentType,
      'choices': choices,
    };
  }
}

class WeekModel {
  final String id;
  String name;
  final List<CurriculumItem> items;

  WeekModel({
    required this.id,
    required this.name,
    List<CurriculumItem>? items,
  }) : items = items ?? [];

  factory WeekModel.fromMap(Map<String, dynamic> map, String documentId) {
    return WeekModel(
      id: documentId,
      name: map['name'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => CurriculumItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,   // always persist id so it survives Firestore round-trips
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}

class LevelModel {
  final String id;
  String name;
  final List<WeekModel> weeks;

  LevelModel({
    required this.id,
    required this.name,
    List<WeekModel>? weeks,
  }) : weeks = weeks ?? [];

  factory LevelModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawWeeks = (map['weeks'] as List<dynamic>?) ?? [];
    return LevelModel(
      id: documentId,
      name: map['name'] ?? '',
      // Use stored id when available; fall back to a stable index-based id for
      // manually-imported documents that don't have 'id' in their week objects.
      weeks: rawWeeks.asMap().entries.map((entry) {
        final idx = entry.key;
        final week = entry.value as Map<String, dynamic>;
        final storedId = (week['id'] as String?);
        final weekId = (storedId != null && storedId.isNotEmpty)
            ? storedId
            : '${documentId}_w$idx';
        return WeekModel.fromMap(week, weekId);
      }).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weeks': weeks.map((week) => week.toMap()).toList(),
    };
  }
}

/// Wraps a CurriculumItem with its parent Level and Week names for search results.
class CurriculumSearchResult {
  final CurriculumItem item;
  final String levelId;
  final String levelName;
  final String weekName;

  const CurriculumSearchResult({
    required this.item,
    required this.levelId,
    required this.levelName,
    required this.weekName,
  });

  String get contextLabel => '$levelName • $weekName';
}
