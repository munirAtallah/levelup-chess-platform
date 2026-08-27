/// Data Tier — Repository
/// Path: lib/data/repositories/assignment_repository.dart
///
/// SECURITY: All assignments are text-based only — no file uploads.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/assignment_model.dart';

class AssignmentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Convenience handle to the top-level 'assignments' collection.
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('assignments');

  /// Fetch assignments belonging to the currently signed-in instructor.
  Future<List<AssignmentModel>> getInstructorAssignments() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user is currently signed in.');
    }
    final snapshot =
        await _col.where('instructorId', isEqualTo: uid).get();
    return snapshot.docs
        .map((doc) => AssignmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Fetch assignments assigned to the currently signed-in student's group and level.
  Future<List<AssignmentModel>> getStudentAssignments() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user is currently signed in.');
    }
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists || userDoc.data() == null) {
      return [];
    }
    final groupId = userDoc.data()?['groupId'] as String?;
    final levelId = userDoc.data()?['levelId'] as String?;
    if ((groupId == null || groupId.isEmpty) && (levelId == null || levelId.isEmpty)) {
      return [];
    }

    final List<Future<QuerySnapshot<Map<String, dynamic>>>> queries = [];
    if (groupId != null && groupId.isNotEmpty) {
      queries.add(_col.where('groupId', isEqualTo: groupId).get());
    }

    final snapshots = await Future.wait(queries);
    final Map<String, AssignmentModel> uniqueAssignments = {};

    for (var snapshot in snapshots) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final model = AssignmentModel.fromMap(data, doc.id);
        
        final matchesGroup = groupId != null && groupId.isNotEmpty && model.groupId == groupId &&
            (model.levelId == null || model.levelId!.isEmpty || model.levelId == levelId);

        if (matchesGroup) {
          uniqueAssignments[model.id] = model;
        }
      }
    }

    final list = uniqueAssignments.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Fetch a single assignment by its document ID.
  Future<AssignmentModel?> getAssignmentById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return AssignmentModel.fromMap(doc.data()!, doc.id);
  }

  /// Copy a central curriculum assignment into the instructor's pool,
  /// reusing the curriculum-generated [id] as the document ID so the
  /// AssignmentDetailScreen can look it up by the same key.
  Future<void> addCentralAssignment(String id, String title,
      {String? content, String? levelId, String? imageUrl, bool isVisible = true, AssignmentType assignmentType = AssignmentType.text, List<String>? choices, DateTime? deadline}) async {
    final model = AssignmentModel(
      id: id,
      title: title,
      type: 'central',
      isActive: true,
      pendingCount: 0,
      gradedCount: 0,
      isVisible: isVisible,
      imageUrl: imageUrl,
      totalStudents: 0,
      submittedCount: 0,
      correctCount: 0,
      incorrectCount: 0,
      curriculumItemId: id,
      searchTags: const [],
      createdAt: DateTime.now(),
      deadline: deadline ?? DateTime.now().add(const Duration(days: 7)),
      textContent: content,
      levelId: levelId,
      assignmentType: assignmentType,
      choices: choices,
    );
    // Use set() with an explicit ID (not add()) so the curriculum ID is preserved.
    await _col.doc(id).set(model.toMap());
  }

  /// Create a new custom or central assignment document (auto-generated ID).
  Future<String> addInstructorAssignment(
    String title, {
    DateTime? deadline,
    String? textContent,
    String type = 'custom',
    AssignmentType assignmentType = AssignmentType.text,
    List<String>? choices,
    String? groupId,
    String? groupName,
    String? levelId,
    bool isVisible = true,
    String? imageUrl,
    int totalStudents = 0,
    String? curriculumItemId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user is currently signed in.');
    }
    final model = AssignmentModel(
      id: '', // ignored — Firestore generates the ID via add()
      title: title,
      type: type,
      isActive: true,
      groupName: groupName,
      groupId: groupId,
      instructorId: uid,
      levelId: levelId,
      pendingCount: 0,
      gradedCount: 0,
      isVisible: isVisible,
      imageUrl: imageUrl,
      totalStudents: totalStudents,
      submittedCount: 0,
      correctCount: 0,
      incorrectCount: 0,
      curriculumItemId: curriculumItemId,
      searchTags: const [],
      createdAt: DateTime.now(),
      deadline: deadline ?? DateTime.now().add(const Duration(days: 7)),
      textContent: textContent,
      assignmentType: assignmentType,
      choices: choices,
    );
    final docRef = await _col.add(model.toMap());
    return docRef.id;
  }

  /// Delete an assignment document.
  /// NOTE: related submissions are NOT cascaded here. A Cloud Function
  /// (onDelete trigger) should clean up submissions where assignmentId == id.
  Future<void> deleteAssignment(String id) async {
    await _col.doc(id).delete();
  }

  /// Update only the deadline field.
  Future<void> updateAssignmentDeadline(String id, DateTime newDeadline) async {
    await _col.doc(id).update({
      'deadline': newDeadline.toIso8601String(),
    });
  }

  /// Update title, content, type, and choices of an existing assignment.
  Future<void> updateAssignmentContent(
    String id,
    String title,
    String textContent,
    AssignmentType assignmentType,
    List<String> choices, {
    String? groupId,
    String? groupName,
    String? levelId,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'textContent': textContent,
      'assignmentType': assignmentType.name,
      'choices': choices,
    };
    // Only overwrite group fields when the caller actually provided them.
    if (groupId != null) data['groupId'] = groupId;
    if (groupName != null) data['groupName'] = groupName;
    if (levelId != null) data['levelId'] = levelId;
    await _col.doc(id).update(data);
  }
}
