/// Data Tier — Repository
/// Path: lib/data/repositories/submission_repository.dart
///
/// SECURITY: All submissions are text-based only — no file uploads.
/// Student answers are strictly plain text; instructor feedback is Delta JSON.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/submission_model.dart';

class SubmissionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('submissions');

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _db.collection('assignments');

  /// Returns all submissions.
  Future<List<SubmissionModel>> getSubmissions() async {
    final snapshot = await _col.get();
    return snapshot.docs
        .map((d) => SubmissionModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Returns submissions for a specific assignment.
  Future<List<SubmissionModel>> getSubmissionsByAssignment(
      String assignmentId) async {
    final snapshot =
        await _col.where('assignmentId', isEqualTo: assignmentId).get();
    return snapshot.docs
        .map((d) => SubmissionModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Returns submissions by a specific student.
  Future<List<SubmissionModel>> getSubmissionsByStudent(
      String studentId) async {
    final snapshot =
        await _col.where('studentId', isEqualTo: studentId).get();
    return snapshot.docs
        .map((d) => SubmissionModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Returns a single submission by ID.
  Future<SubmissionModel?> getSubmissionById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return SubmissionModel.fromMap(doc.data()!, doc.id);
  }

  /// Returns a submission for a specific assignment and student.
  Future<SubmissionModel?> getSubmissionForAssignment(
      String assignmentId, String studentId) async {
    final snapshot = await _col
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final d = snapshot.docs.first;
    return SubmissionModel.fromMap(d.data(), d.id);
  }

  /// Adds a new text-based submission and bumps the parent assignment's
  /// pendingCount and submittedCount by 1. [textContent] is stored as the 'answer' field.
  Future<void> addSubmission({
    required String assignmentId,
    required String studentId,
    required String textContent,
    String? selectedChoice,
  }) async {
    final model = SubmissionModel(
      id: '', // ignored — Firestore generates the ID
      assignmentId: assignmentId,
      studentId: studentId,
      submittedAt: DateTime.now(),
      answer: textContent,
      selectedChoice: selectedChoice,
      status: GradeStatus.pending,
    );
    final batch = _db.batch();
    final newDoc = _col.doc();
    batch.set(newDoc, model.toMap());
    batch.update(_assignments.doc(assignmentId), {
      'pendingCount': FieldValue.increment(1),
      'submittedCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Updates an existing submission's answer (does not affect counters).
  Future<void> updateSubmission({
    required String submissionId,
    required String textContent,
    String? selectedChoice,
  }) async {
    await _col.doc(submissionId).update({
      'answer': textContent,
      'selectedChoice': selectedChoice,
      'submittedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Grades a submission and adjusts the parent assignment's counters.
  /// Runs in a transaction so concurrent grading can't corrupt the counts,
  /// and reads the OLD status first so re-grading never double-counts.
  Future<void> gradeSubmission(
      String submissionId, GradeStatus status, String? feedback) async {
    final subRef = _col.doc(submissionId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(subRef);
      if (!snap.exists) {
        throw Exception('Submission not found: $submissionId');
      }

      final oldStatusStr = (snap.data()?['status'] as String?) ?? 'pending';
      final assignmentId = snap.data()?['assignmentId'] as String?;

      final wasPending = oldStatusStr == 'pending';
      final nowGraded = status != GradeStatus.pending;

      // Write the submission's new status + feedback.
      txn.update(subRef, {
        'status': status.name,
        'feedback': feedback,
      });

      // Only move the counters when crossing the pending -> graded boundary.
      if (assignmentId != null) {
        final Map<String, dynamic> updates = {};

        // 1. Update pendingCount and gradedCount
        if (wasPending && nowGraded) {
          updates['pendingCount'] = FieldValue.increment(-1);
          updates['gradedCount'] = FieldValue.increment(1);
        } else if (!wasPending && !nowGraded) {
          // Graded -> pending (instructor undid a grade).
          updates['pendingCount'] = FieldValue.increment(1);
          updates['gradedCount'] = FieldValue.increment(-1);
        }

        // 2. Update correctCount and incorrectCount
        if (oldStatusStr == 'pending') {
          if (status == GradeStatus.correct) {
            updates['correctCount'] = FieldValue.increment(1);
          } else if (status == GradeStatus.incorrect) {
            updates['incorrectCount'] = FieldValue.increment(1);
          }
        } else if (oldStatusStr == 'correct') {
          if (status == GradeStatus.incorrect) {
            updates['correctCount'] = FieldValue.increment(-1);
            updates['incorrectCount'] = FieldValue.increment(1);
          } else if (status == GradeStatus.pending) {
            updates['correctCount'] = FieldValue.increment(-1);
          }
        } else if (oldStatusStr == 'incorrect') {
          if (status == GradeStatus.correct) {
            updates['incorrectCount'] = FieldValue.increment(-1);
            updates['correctCount'] = FieldValue.increment(1);
          } else if (status == GradeStatus.pending) {
            updates['incorrectCount'] = FieldValue.increment(-1);
          }
        }

        if (updates.isNotEmpty) {
          txn.update(_assignments.doc(assignmentId), updates);
        }
      }
    });
  }
}