import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MaterialAssignmentModel {
  final String id;
  final String materialId;
  final String materialTitle;
  final String groupId;
  final String groupName;
  final String levelId; 
  final String instructorId;
  final DateTime assignedAt;

  MaterialAssignmentModel({
    required this.id,
    required this.materialId,
    required this.materialTitle,
    required this.groupId,
    required this.groupName,
    required this.levelId,
    required this.instructorId,
    required this.assignedAt,
  });

  factory MaterialAssignmentModel.fromMap(Map<String, dynamic> map, String docId) {
    return MaterialAssignmentModel(
      id: docId,
      materialId: map['materialId'] ?? '',
      materialTitle: map['materialTitle'] ?? '',
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      levelId: map['levelId'] ?? '',
      instructorId: map['instructorId'] ?? '',
      assignedAt: map['assignedAt'] != null
          ? (map['assignedAt'] is Timestamp
              ? (map['assignedAt'] as Timestamp).toDate()
              : DateTime.parse(map['assignedAt']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'materialTitle': materialTitle,
      'groupId': groupId,
      'groupName': groupName,
      'levelId': levelId,
      'instructorId': instructorId,
      'assignedAt': assignedAt.toIso8601String(),
    };
  }
}

class MaterialAssignmentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('assigned_materials');

  /// Assign a material to a group and level, with level compatibility and duplicate prevention checks.
  Future<void> assignMaterial({
    required String materialId,
    required String materialTitle,
    required String groupId,
    required String groupName,
    required String levelId,
    required String materialLevelId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user is currently signed in.');
    }

    // 1. Level check
    final targetNum = _extractLevelNum(levelId);
    final materialNum = _extractLevelNum(materialLevelId);
    if (targetNum != null && materialNum != null && targetNum < materialNum) {
      throw Exception('level_lower_error'); // Throw key code so the UI can translate it
    }

    // 2. Duplicate check
    final dupSnap = await _col
        .where('materialId', isEqualTo: materialId)
        .where('groupId', isEqualTo: groupId)
        .where('levelId', isEqualTo: levelId)
        .get();

    if (dupSnap.docs.isNotEmpty) {
      throw Exception('already_assigned_error');
    }

    // 3. Save assignment
    final model = MaterialAssignmentModel(
      id: '',
      materialId: materialId,
      materialTitle: materialTitle,
      groupId: groupId,
      groupName: groupName,
      levelId: levelId,
      instructorId: uid,
      assignedAt: DateTime.now(),
    );

    await _col.add(model.toMap());
  }

  /// Get current assignments for a material.
  Future<List<MaterialAssignmentModel>> getAssignmentsForMaterial(
      String materialId) async {
    final snap = await _col.where('materialId', isEqualTo: materialId).get();
    return snap.docs
        .map((doc) => MaterialAssignmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Remove a material assignment.
  Future<void> deleteAssignment(String assignmentId) async {
    await _col.doc(assignmentId).delete();
  }

  int? _extractLevelNum(String levelId) {
    final match = RegExp(r'\d+').firstMatch(levelId);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
}
