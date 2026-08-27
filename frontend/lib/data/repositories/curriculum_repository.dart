/// Data Tier — Repository
/// Path: lib/data/repositories/curriculum_repository.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curriculum_model.dart';

class CurriculumRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Local cache updated after every getLevels() call.
  // Provides index-to-ID mapping and avoids redundant full-collection reads
  // in the same request cycle.
  List<LevelModel> _cache = [];

  // ── Reads ──────────────────────────────────────────────────────────────────

  int _compareLevels(LevelModel a, LevelModel b) {
    final reg = RegExp(r'\d+');
    final matchA = reg.firstMatch(a.name);
    final matchB = reg.firstMatch(b.name);
    if (matchA != null && matchB != null) {
      final numA = int.parse(matchA.group(0)!);
      final numB = int.parse(matchB.group(0)!);
      if (numA != numB) {
        return numA.compareTo(numB);
      }
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  /// Returns all levels from Firestore sorted by name (natural numeric order).
  /// Weeks within each level are sorted by name; items within each week by title.
  Future<List<LevelModel>> getLevels() async {
    if (_cache.isNotEmpty) return List<LevelModel>.from(_cache);

    var snap = await _db.collection('curriculum').get();
    _cache = snap.docs
        .map((doc) => _applySorting(LevelModel.fromMap(doc.data(), doc.id)))
        .toList()
      ..sort(_compareLevels);
    return List<LevelModel>.from(_cache);
  }

  /// Deprecated default initializer. No longer used as curriculum starts empty.
  Future<void> initializeIfEmpty() async {}

  /// Finds a single [CurriculumItem] by its [id] across all levels.
  Future<CurriculumItem?> getLessonById(String id) async {
    final levels = await getLevels();
    for (final level in levels) {
      for (final week in level.weeks) {
        for (final item in week.items) {
          if (item.id == id) return item;
        }
      }
    }
    return null;
  }

  // ── Level Operations ────────────────────────────────────────────────────────

  Future<void> editLevel(String levelId, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) return;
    final snap = await _db.collection('curriculum').get();
    for (final doc in snap.docs) {
      if (doc.id == levelId) continue;
      final existingName = (doc.data()['name'] as String?)?.trim();
      if (existingName != null && existingName.toLowerCase() == trimmedName.toLowerCase()) {
        throw Exception('Level "$trimmedName" already exists.');
      }
    }
    await _db.collection('curriculum').doc(levelId).update({'name': trimmedName});
    _cache = [];
  }

  /// Creates a new level document with a sequential ID (e.g. l1, l2...)
  Future<void> addLevel(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final snap = await _db.collection('curriculum').get();
    int maxSeq = 0;
    for (final doc in snap.docs) {
      final existingName = (doc.data()['name'] as String?)?.trim();
      if (existingName != null && existingName.toLowerCase() == trimmedName.toLowerCase()) {
        throw Exception('Level "$trimmedName" already exists.');
      }
      
      final id = doc.id;
      if (id.startsWith('l')) {
        final numPart = id.substring(1);
        final val = int.tryParse(numPart);
        if (val != null && val > maxSeq) {
          maxSeq = val;
        }
      }
    }
    final id = 'l${maxSeq + 1}';

    await _db.collection('curriculum').doc(id).set({
      'name': trimmedName,
      'weeks': <dynamic>[],
    });
    _cache = []; // invalidate cache so next getLevels() fetches fresh data
  }

  /// Deletes a level document.
  Future<void> deleteLevel(String levelId) async {
    await _db.collection('curriculum').doc(levelId).delete();
    _cache = []; // invalidate cache so next getLevels() fetches fresh data
  }

  // ── Week Operations ─────────────────────────────────────────────────────────

  /// Appends a new week to the level identified by [levelId].
  /// Week id format: `{levelId}_w{timestamp}`.
  Future<void> addWeek(String levelId, String name) async {
    final level = await _fetchLevel(levelId);
    final weekId = '${levelId}_w${DateTime.now().millisecondsSinceEpoch}';
    level.weeks.add(WeekModel(id: weekId, name: name));
    await _saveLevel(level);
  }

  Future<void> editWeek(String levelId, String weekId, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) return;
    final level = await _fetchLevel(levelId);
    final week = level.weeks.firstWhere((w) => w.id == weekId);
    week.name = trimmedName;
    await _saveLevel(level);
  }

  Future<void> deleteWeek(String levelId, String weekId) async {
    final level = await _fetchLevel(levelId);
    final week = level.weeks.firstWhere((w) => w.id == weekId);
    final itemIds = week.items.map((i) => i.id).toList();
    level.weeks.removeWhere((w) => w.id == weekId);

    final batch = _db.batch();
    batch.set(_db.collection('curriculum').doc(level.id), level.toMap());

    for (final itemId in itemIds) {
      final assignedSnaps = await _db
          .collection('assigned_materials')
          .where('materialId', isEqualTo: itemId)
          .get();
      for (final doc in assignedSnaps.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
    _cache = [];
  }

  // ── Item Operations ─────────────────────────────────────────────────────────

  /// Appends a material item to the week identified by [weekId] inside [levelId].
  /// Item id format: `mat_{timestamp}`.
  Future<void> addMaterial(
    String levelId,
    String weekId,
    String title, {
    String? content,
    String? deltaJson,
    List<Map<String, String>> attachments = const [],
  }) async {
    final level = await _fetchLevel(levelId);
    final week = level.weeks.firstWhere((w) => w.id == weekId);
    week.items.add(CurriculumItem(
      id: 'mat_${DateTime.now().millisecondsSinceEpoch}',
      type: CurriculumItemType.material,
      title: title,
      content: content,
      deltaJson: deltaJson,
      searchTags: [],
      visible: true,
      attachments: attachments,
    ));
    await _saveLevel(level);
  }

  /// Appends an assignment item to the week identified by [weekId] inside [levelId].
  /// Item id format: `ca_{timestamp}` unless [id] is provided.
  Future<void> addAssignment(
    String levelId,
    String weekId,
    String title, {
    String? content,
    String? id,
    String? assignmentType,
    List<String>? choices,
  }) async {
    final level = await _fetchLevel(levelId);
    final week = level.weeks.firstWhere((w) => w.id == weekId);
    week.items.add(CurriculumItem(
      id: id ?? 'ca_${DateTime.now().millisecondsSinceEpoch}',
      type: CurriculumItemType.assignment,
      title: title,
      content: content,
      isActive: true,
      deadlineText: 'No deadline',
      visible: true,
      assignmentType: assignmentType,
      choices: choices,
    ));
    await _saveLevel(level);
  }

  /// Flips the [visible] flag of the item identified by [itemId].
  Future<void> toggleVisibility(
    String levelId,
    String weekId,
    String itemId,
  ) async {
    final level = await _fetchLevel(levelId);
    final week = level.weeks.firstWhere((w) => w.id == weekId);
    final item = week.items.firstWhere((i) => i.id == itemId);
    item.visible = !item.visible;
    await _saveLevel(level);
  }

  /// Updates the title and content of an existing item.
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
  }) async {
    final level = await _fetchLevel(levelId);
    final week = level.weeks.firstWhere((w) => w.id == weekId);
    final item = week.items.firstWhere((i) => i.id == itemId);
    item.title = title;
    item.content = content;
    if (deltaJson != null) item.deltaJson = deltaJson;
    item.attachments = attachments;
    if (item.type == CurriculumItemType.assignment) {
      final updatedItem = CurriculumItem(
        id: item.id,
        type: item.type,
        title: title,
        content: content,
        deltaJson: deltaJson ?? item.deltaJson,
        searchTags: item.searchTags,
        visible: item.visible,
        isActive: item.isActive,
        deadlineText: item.deadlineText,
        imageUrl: item.imageUrl,
        attachments: attachments,
        assignmentType: assignmentType,
        choices: choices,
      );
      final index = week.items.indexOf(item);
      if (index != -1) {
        week.items[index] = updatedItem;
      }
    }
    await _saveLevel(level);
  }

  /// Removes the item identified by [itemId] from its week.
  Future<void> deleteItem(String levelId, String weekId, String itemId) async {
    final level = await _fetchLevel(levelId);
    final week = level.weeks.firstWhere((w) => w.id == weekId);
    week.items.removeWhere((i) => i.id == itemId);
    
    final batch = _db.batch();
    batch.set(_db.collection('curriculum').doc(level.id), level.toMap());
    
    final assignedSnaps = await _db.collection('assigned_materials')
        .where('materialId', isEqualTo: itemId)
        .get();
    for (final doc in assignedSnaps.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    _cache = [];
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  /// Reads a single level document and returns a mutable [LevelModel].
  /// Weeks and items are sorted before returning.
  /// Throws [StateError] if the document does not exist.
  Future<LevelModel> _fetchLevel(String levelId) async {
    final snap = await _db.collection('curriculum').doc(levelId).get();
    if (!snap.exists || snap.data() == null) {
      throw StateError('Curriculum level "$levelId" not found in Firestore.');
    }
    return _applySorting(LevelModel.fromMap(snap.data()!, levelId));
  }

  /// Writes the full level document back to Firestore.
  Future<void> _saveLevel(LevelModel level) async {
    await _db.collection('curriculum').doc(level.id).set(level.toMap());
    _cache = [];
  }

  /// Sorts weeks by name and items within each week by title, in place.
  LevelModel _applySorting(LevelModel level) {
    level.weeks.sort((a, b) => a.name.compareTo(b.name));
    for (final week in level.weeks) {
      week.items.sort((a, b) => a.title.compareTo(b.title));
    }
    return level;
  }
}
