/// Logic Tier — Controller
/// Path: lib/logic/controllers/curriculum_controller.dart
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/curriculum_model.dart';
import '../../data/models/assignment_model.dart';
import 'instructor_assignment_controller.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../di/service_locator.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/material_assignment_repository.dart';
import '../helpers/audit_log_helper.dart';

class CurriculumController extends ChangeNotifier {
  final CurriculumRepository _repository;
  final AssignmentRepository _assignmentRepository;
  final UserRepository _userRepository;
  final AuditLogHelper _audit;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CurriculumController(this._repository, this._assignmentRepository, this._userRepository, this._audit) {
    _audit.resolveIdentity();
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    _levels = await _repository.getLevels();
    _isLoading = false;
    notifyListeners();
  }

  // ── State ──────────────────────────────
  List<LevelModel> _levels = [];
  String _search = '';
  final Set<String> _expandedLevels = {};
  final Set<String> _expandedWeeks = {};

  // ── Getters ────────────────────────────
  String get search => _search;
  Set<String> get expandedLevels => _expandedLevels;
  Set<String> get expandedWeeks => _expandedWeeks;

  /// Returns levels filtered by the current search term.
  ///
  /// The filter is case-insensitive and matches against both the item title
  /// and any of its tags. Empty-level and empty-week containers are pruned
  /// so the UI never shows a level/week accordion with no children.
  ///
  /// When [_search] is empty the full unmodified list is returned directly,
  /// avoiding the allocation overhead of building filtered copies.
  List<LevelModel> get levels {
    if (_search.isEmpty) return _levels;
    final term = _search.toLowerCase();
    final filtered = <LevelModel>[];
    for (final level in _levels) {
      final filteredWeeks = <WeekModel>[];
      for (final week in level.weeks) {
        // Keep an item if its title or any tag contains the search term
        final filteredItems = week.items.where((item) =>
          item.title.toLowerCase().contains(term) ||
          item.searchTags.any((t) => t.toLowerCase().contains(term))
        ).toList();
        if (filteredItems.isNotEmpty) {
          filteredWeeks.add(WeekModel(id: week.id, name: week.name, items: filteredItems));
        }
      }
      if (filteredWeeks.isNotEmpty) {
        filtered.add(LevelModel(id: level.id, name: level.name, weeks: filteredWeeks));
      }
    }
    return filtered;
  }

  // When a search is active, force all accordion nodes open so matching items
  // are immediately visible without the user having to expand each level/week.
  bool isLevelExpanded(String id) => _search.isNotEmpty || _expandedLevels.contains(id);
  bool isWeekExpanded(String id) => _search.isNotEmpty || _expandedWeeks.contains(id);

  List<CurriculumSearchResult> get searchResults {
    if (_search.isEmpty) return [];
    final term = _search.toLowerCase();
    final List<CurriculumSearchResult> results = [];
    for (final level in _levels) {
      for (final week in level.weeks) {
        for (final item in week.items) {
          final matchTitle = item.title.toLowerCase().contains(term);
          final matchTag = item.searchTags.any((t) => t.toLowerCase().contains(term));
          if (matchTitle || matchTag) {
            results.add(CurriculumSearchResult(
              item: item,
              levelId: level.id,
              levelName: level.name,
              weekName: week.name,
            ));
          }
        }
      }
    }
    return results;
  }

  // ── Actions ────────────────────────────

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void toggleLevel(String id) {
    if (_expandedLevels.contains(id)) {
      _expandedLevels.remove(id);
    } else {
      _expandedLevels.add(id);
    }
    notifyListeners();
  }

  void toggleWeek(String id) {
    if (_expandedWeeks.contains(id)) {
      _expandedWeeks.remove(id);
    } else {
      _expandedWeeks.add(id);
    }
    notifyListeners();
  }

  Future<int> getStudentCountForLevel(String levelId) =>
      _userRepository.getStudentCountByLevel(levelId);

  Future<int> getActiveGroupsCountForLevel(String levelId) async {
    final snap = await FirebaseFirestore.instance
        .collection('groups')
        .where('isArchived', isEqualTo: false)
        .where('levelIds', arrayContains: levelId)
        .get();
    return snap.docs.length;
  }

  Future<void> editLevel(String levelId, String newName) async {
    if (newName.isEmpty) return;
    final oldName = _levels.firstWhere((l) => l.id == levelId).name;
    for (final level in _levels) {
      if (level.id == levelId) { level.name = newName; break; }
    }
    notifyListeners();
    try {
      await _repository.editLevel(levelId, newName);
      _levels = await _repository.getLevels();
      notifyListeners();
      _audit.log(action: 'Renamed curriculum level', category: 'curriculum', details: '"$oldName" → "$newName"');
    } catch (e) {
      for (final level in _levels) {
        if (level.id == levelId) { level.name = oldName; break; }
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addLevel(String name) async {
    if (name.isEmpty) return;
    try {
      await _repository.addLevel(name);
      _levels = await _repository.getLevels();
      notifyListeners();
      _audit.log(action: 'Created curriculum level', category: 'curriculum', details: name);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLevel(String levelId) async {
    final idx = _levels.indexWhere((l) => l.id == levelId);
    if (idx == -1) return;
    final removed = _levels.removeAt(idx);
    notifyListeners();
    try {
      await _repository.deleteLevel(levelId);
      _levels = await _repository.getLevels();
      notifyListeners();
      _audit.log(action: 'Deleted curriculum level', category: 'curriculum', details: removed.name);
    } catch (e) {
      _levels.insert(idx, removed);
      _levels.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addWeek(String levelId, String name) async {
    if (name.isEmpty) return;
    try {
      await _repository.addWeek(levelId, name);
      _levels = await _repository.getLevels();
      notifyListeners();
      final levelName = _levels.where((l) => l.id == levelId).firstOrNull?.name ?? levelId;
      _audit.log(action: 'Added week to level', category: 'curriculum', details: '$name in $levelName');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> editWeek(String levelId, String weekId, String newName) async {
    if (newName.isEmpty) return;
    String? oldName;
    for (final level in _levels) {
      if (level.id == levelId) {
        for (final week in level.weeks) {
          if (week.id == weekId) {
            oldName = week.name;
            week.name = newName;
            break;
          }
        }
      }
    }
    notifyListeners();
    try {
      await _repository.editWeek(levelId, weekId, newName);
      _levels = await _repository.getLevels();
      notifyListeners();
      _audit.log(action: 'Renamed curriculum week', category: 'curriculum', details: '"$oldName" → "$newName"');
    } catch (e) {
      for (final level in _levels) {
        if (level.id == levelId) {
          for (final week in level.weeks) {
            if (week.id == weekId) {
              if (oldName != null) week.name = oldName;
              break;
            }
          }
        }
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteWeek(String levelId, String weekId) async {
    WeekModel? removed;
    for (final level in _levels) {
      if (level.id == levelId) {
        final idx = level.weeks.indexWhere((w) => w.id == weekId);
        if (idx != -1) {
          removed = level.weeks.removeAt(idx);
          break;
        }
      }
    }
    notifyListeners();
    try {
      await _repository.deleteWeek(levelId, weekId);
      _levels = await _repository.getLevels();
      notifyListeners();
      _audit.log(action: 'Deleted curriculum week', category: 'curriculum', details: removed?.name ?? weekId);
    } catch (e) {
      if (removed != null) {
        for (final level in _levels) {
          if (level.id == levelId) {
            level.weeks.add(removed);
            level.weeks.sort((a, b) => a.name.compareTo(b.name));
            break;
          }
        }
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> addMaterial(
    String levelId,
    String weekId,
    String title, {
    String? content,
    String? deltaJson,
    List<Map<String, String>> attachments = const [],
  }) async {
    if (title.isEmpty) return;
    try {
      await _repository.addMaterial(
        levelId,
        weekId,
        title,
        content: content,
        deltaJson: deltaJson,
        attachments: attachments,
      );
      _levels = await _repository.getLevels();
      notifyListeners();
      
      final level = _levels.firstWhere((l) => l.id == levelId, orElse: () => LevelModel(id: levelId, name: 'Level'));
      final levelName = level.name;

      // Write Audit Log
      _audit.log(action: 'Added material', category: 'curriculum', details: '"$title" in $levelName');
    } catch (e) {
      debugPrint('CurriculumController.addMaterial error: $e');
      rethrow;
    }
  }

  Future<void> assignMaterial({
    required String materialId,
    required String materialTitle,
    required String groupId,
    required String groupName,
    required String levelId,
    required String materialLevelId,
  }) async {
    final materialAssignmentRepo = getIt<MaterialAssignmentRepository>();
    await materialAssignmentRepo.assignMaterial(
      materialId: materialId,
      materialTitle: materialTitle,
      groupId: groupId,
      groupName: groupName,
      levelId: levelId,
      materialLevelId: materialLevelId,
    );

    // Write Audit Log
    _audit.log(
      action: 'Assigned material',
      category: 'curriculum',
      details: '"$materialTitle" | Group: $groupName | Level: $levelId',
    );

    // Notify students of this group AND level
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('groupId', isEqualTo: groupId)
        .where('levelId', isEqualTo: levelId)
        .where('isArchived', isEqualTo: false)
        .get();
    final studentUids = snap.docs.map((d) => d.id).toList();

    if (studentUids.isNotEmpty) {
      final notif = AppNotification(
        id: '',
        title: 'New Lesson Revealed',
        body: 'Your instructor revealed a new lesson: "$materialTitle".',
        type: 'material',
        relatedId: levelId,
        createdAt: DateTime.now(),
        recipientUid: '',
      );

      final notifRepo = getIt<NotificationRepository>();
      for (final uid in studentUids) {
        await notifRepo.addNotification(AppNotification(
          id: '',
          title: notif.title,
          body: notif.body,
          type: notif.type,
          relatedId: notif.relatedId,
          createdAt: notif.createdAt,
          recipientUid: uid,
        ));
      }
    }
  }

  Future<void> unassignMaterial({
    required String assignmentId,
    required String materialTitle,
    required String groupName,
  }) async {
    final materialAssignmentRepo = getIt<MaterialAssignmentRepository>();
    await materialAssignmentRepo.deleteAssignment(assignmentId);

    _audit.log(
      action: 'Unassigned material',
      category: 'curriculum',
      details: '"$materialTitle" from Group: $groupName',
    );
  }

  Future<void> addAssignment(
    String levelId,
    String weekId,
    String title, {
    String? content,
    String? assignmentType,
    List<String>? choices,
    String? groupId,
    String? groupName,
    String? assignedLevelId,
    DateTime? deadline,
  }) async {
    if (title.isEmpty) return;
    try {
      final id = 'ca_${DateTime.now().millisecondsSinceEpoch}';
      await _repository.addAssignment(levelId, weekId, title, content: content, id: id, assignmentType: assignmentType, choices: choices);
      await _assignmentRepository.addCentralAssignment(
        id,
        title,
        content: content,
        levelId: levelId,
        assignmentType: assignmentType == 'multipleChoice' ? AssignmentType.multipleChoice : AssignmentType.text,
        choices: choices,
        deadline: deadline,
      );

      if (groupId != null && assignedLevelId != null && deadline != null) {
        final instructorAssignmentController = getIt<InstructorAssignmentController>();
        await instructorAssignmentController.addAssignment(
          title,
          deadline: deadline,
          textContent: content,
          type: 'central',
          assignmentType: assignmentType == 'multipleChoice' ? AssignmentType.multipleChoice : AssignmentType.text,
          choices: choices,
          groupId: groupId,
          groupName: groupName,
          levelId: assignedLevelId,
          curriculumItemId: id,
        );
      }

      _levels = await _repository.getLevels();
      notifyListeners();
      final levelName = _levels.where((l) => l.id == levelId).firstOrNull?.name ?? levelId;
      _audit.log(action: 'Added curriculum assignment', category: 'curriculum', details: '"$title" in $levelName');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleVisibility(String levelId, String weekId, String itemId) async {
    try {
      for (final level in _levels) {
        if (level.id == levelId) {
          for (final week in level.weeks) {
            if (week.id == weekId) {
              for (final item in week.items) {
                if (item.id == itemId) {
                  item.visible = !item.visible;
                  break;
                }
              }
            }
          }
        }
      }
      notifyListeners();
      await _repository.toggleVisibility(levelId, weekId, itemId);
      _levels = await _repository.getLevels();
      notifyListeners();
    } catch (e) {
      for (final level in _levels) {
        if (level.id == levelId) {
          for (final week in level.weeks) {
            if (week.id == weekId) {
              for (final item in week.items) {
                if (item.id == itemId) {
                  item.visible = !item.visible;
                  break;
                }
              }
            }
          }
        }
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(
    String levelId,
    String weekId,
    String itemId,
    String title,
    String content, {
    String? deltaJson,
    List<Map<String, String>> attachments = const [],
    String? assignmentType,
    List<String>? choices,
    String? groupId,
    String? groupName,
    String? assignedLevelId,
    DateTime? deadline,
  }) async {
    try {
      await _repository.updateItem(
        levelId,
        weekId,
        itemId,
        title,
        content,
        deltaJson: deltaJson,
        attachments: attachments,
        assignmentType: assignmentType,
        choices: choices,
      );
      // Update central assignment in assignments collection if it exists
      final docRef = FirebaseFirestore.instance.collection('assignments').doc(itemId);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        await docRef.update({
          'title': title,
          'content': content,
          'assignmentType': assignmentType,
          'choices': choices,
          if (deadline != null) 'deadline': deadline,
        });
      }

      if (groupId != null && assignedLevelId != null && deadline != null) {
        final instructorAssignmentController = getIt<InstructorAssignmentController>();
        final querySnap = await FirebaseFirestore.instance
            .collection('assignments')
            .where('curriculumItemId', isEqualTo: itemId)
            .where('groupId', isEqualTo: groupId)
            .where('levelId', isEqualTo: assignedLevelId)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          final docId = querySnap.docs.first.id;
          await instructorAssignmentController.updateContent(
            docId,
            title,
            content,
            assignmentType == 'multipleChoice' ? AssignmentType.multipleChoice : AssignmentType.text,
            choices ?? [],
            groupId: groupId,
            groupName: groupName,
            levelId: assignedLevelId,
          );
          await instructorAssignmentController.updateDeadline(docId, deadline);
        } else {
          await instructorAssignmentController.addAssignment(
            title,
            deadline: deadline,
            textContent: content,
            type: 'central',
            assignmentType: assignmentType == 'multipleChoice' ? AssignmentType.multipleChoice : AssignmentType.text,
            choices: choices,
            groupId: groupId,
            groupName: groupName,
            levelId: assignedLevelId,
            curriculumItemId: itemId,
          );
        }
      }

      _levels = await _repository.getLevels();
      notifyListeners();
      _audit.log(action: 'Updated curriculum item', category: 'curriculum', details: '"$title"');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteItem(String levelId, String weekId, String itemId) async {
    CurriculumItem? removedItem;
    for (final level in _levels) {
      if (level.id == levelId) {
        for (final week in level.weeks) {
          if (week.id == weekId) {
            final idx = week.items.indexWhere((i) => i.id == itemId);
            if (idx != -1) {
              removedItem = week.items.removeAt(idx);
              break;
            }
          }
        }
      }
    }
    notifyListeners();

    try {
      await _repository.deleteItem(levelId, weekId, itemId);
      if (itemId.startsWith('ca_')) {
        await _assignmentRepository.deleteAssignment(itemId);
      }
      _levels = await _repository.getLevels();
      notifyListeners();
    } catch (e) {
      if (removedItem != null) {
        for (final level in _levels) {
          if (level.id == levelId) {
            for (final week in level.weeks) {
              if (week.id == weekId) {
                week.items.add(removedItem);
                week.items.sort((a, b) => a.title.compareTo(b.title));
                break;
              }
            }
          }
        }
        notifyListeners();
      }
      rethrow;
    }
  }
}
