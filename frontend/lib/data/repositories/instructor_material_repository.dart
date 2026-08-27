/// Data Tier — Repository
/// Path: lib/data/repositories/instructor_material_repository.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/instructor_material_model.dart';

class InstructorMaterialRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'instructor_materials';

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Returns all materials created by this instructor, sorted newest first.
  Future<List<InstructorMaterialModel>> getInstructorMaterials(
      String instructorId) async {
    final snap = await _db
        .collection(_collection)
        .where('instructorId', isEqualTo: instructorId)
        .get();
    final list = snap.docs
        .map((doc) => InstructorMaterialModel.fromMap(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Returns all VISIBLE materials for a specific group+level (students &
  /// co-instructors).  Only documents where isVisible == true are included.
  Future<List<InstructorMaterialModel>> getGroupMaterials(
      String groupId, String levelId) async {
    final snap = await _db
        .collection(_collection)
        .where('groupId', isEqualTo: groupId)
        .where('levelId', isEqualTo: levelId)
        .where('isVisible', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((doc) => InstructorMaterialModel.fromMap(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Returns ALL materials across all groups (admin view).
  Future<List<InstructorMaterialModel>> getAdminAllMaterials() async {
    final snap = await _db.collection(_collection).get();
    final list = snap.docs
        .map((doc) => InstructorMaterialModel.fromMap(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Returns all materials for a specific group (admin group detail view),
  /// including hidden ones.
  Future<List<InstructorMaterialModel>> getGroupAllMaterials(
      String groupId) async {
    final snap = await _db
        .collection(_collection)
        .where('groupId', isEqualTo: groupId)
        .get();
    final list = snap.docs
        .map((doc) => InstructorMaterialModel.fromMap(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Creates a new material and returns its Firestore document ID.
  Future<String> addMaterial({
    required String title,
    required String deltaJson,
    required List<Map<String, String>> attachments,
    required String instructorId,
    required String groupId,
    required String levelId,
  }) async {
    final now = DateTime.now();
    final ref = _db.collection(_collection).doc();
    await ref.set({
      'title': title,
      'content': deltaJson,
      'deltaJson': deltaJson,
      'attachments': attachments,
      'instructorId': instructorId,
      'groupId': groupId,
      'levelId': levelId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'isVisible': true,
      'searchKeywords': _buildKeywords(title),
    });
    return ref.id;
  }

  /// Updates title, content and attachments of an existing material.
  Future<void> updateMaterial(
    String id,
    String title,
    String deltaJson,
    List<Map<String, String>> attachments,
  ) async {
    await _db.collection(_collection).doc(id).update({
      'title': title,
      'content': deltaJson,
      'deltaJson': deltaJson,
      'attachments': attachments,
      'updatedAt': DateTime.now().toIso8601String(),
      'searchKeywords': _buildKeywords(title),
    });
  }

  /// Permanently deletes a material document.
  Future<void> deleteMaterial(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  /// Flips the isVisible flag.  Pass [currentValue] to invert it.
  Future<void> toggleVisibility(String id, bool currentValue) async {
    await _db.collection(_collection).doc(id).update({
      'isVisible': !currentValue,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<String> _buildKeywords(String title) {
    final words = title.toLowerCase().split(RegExp(r'\s+'));
    final keywords = <String>{};
    for (final w in words) {
      if (w.isEmpty) continue;
      keywords.add(w);
      for (int i = 1; i <= w.length; i++) {
        keywords.add(w.substring(0, i));
      }
    }
    return keywords.toList();
  }
}
