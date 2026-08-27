/// Data Tier — Model
/// Path: lib/data/models/submission_model.dart
///
/// SECURITY REQUIREMENT: Submissions are text-based only.
/// No file-upload parameters are permitted in this model.
/// Student answers are strictly plain text; instructor feedback is Delta JSON.
library;

/// Possible grading statuses for a submission.
import 'package:cloud_firestore/cloud_firestore.dart';

/// Possible grading statuses for a submission.
enum GradeStatus { pending, correct, incorrect }

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

class SubmissionModel {
  final String id;

  /// The ID of the assignment this submission belongs to.
  final String assignmentId;

  /// The student ID who submitted this work.
  final String studentId;

  /// The date and time the student submitted.
  final DateTime submittedAt;

  /// The student's plain-text answer (strictly no rich text / no file uploads).
  final String answer;

  /// The student's selected choice for MCQ assignments.
  final String? selectedChoice;

  /// Optional Delta JSON feedback left by the instructor after grading.
  String? feedback;

  /// The current grading status of this submission.
  GradeStatus status;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.submittedAt,
    required this.answer,
    this.selectedChoice,
    this.feedback,
    this.status = GradeStatus.pending,
  });

  /// Human-readable label for the grade status.
  String get gradeStatusLabel {
    switch (status) {
      case GradeStatus.pending:
        return 'Pending';
      case GradeStatus.correct:
        return 'Correct';
      case GradeStatus.incorrect:
        return 'Incorrect';
    }
  }

  factory SubmissionModel.fromMap(Map<String, dynamic> map, String documentId) {
    GradeStatus parsedStatus = GradeStatus.pending;
    final statusStr = map['status'] as String? ?? 'pending';
    if (statusStr == 'correct') parsedStatus = GradeStatus.correct;
    if (statusStr == 'incorrect') parsedStatus = GradeStatus.incorrect;

    return SubmissionModel(
      id: documentId,
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      submittedAt: _parseDate(map['submittedAt']) ?? DateTime.now(),
      answer: map['answer'] ?? '',
      selectedChoice: map['selectedChoice'] ?? map['answer'],
      feedback: map['feedback'],
      status: parsedStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'submittedAt': submittedAt.toIso8601String(),
      'answer': answer,
      'selectedChoice': selectedChoice,
      'feedback': feedback,
      'status': status.name,
    };
  }
}
