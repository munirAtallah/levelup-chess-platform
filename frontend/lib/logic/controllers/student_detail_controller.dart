import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/student_profile_model.dart';
import '../../data/models/submission_model.dart';
import '../../data/repositories/student_profile_repository.dart';

class StudentDetailController extends ChangeNotifier {
  final String studentId;
  final StudentProfileRepository _repository;
  
  late StudentProfile profile;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Stats fields
  int totalAssignments = 0;
  int correctCount = 0;
  int incorrectCount = 0;
  int pendingCount = 0;
  int notSubmittedCount = 0;
  double correctPercent = 0;
  double incorrectPercent = 0;

  StudentDetailController(this.studentId, this._repository) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      profile = await _repository.getProfileById(studentId) ?? 
        StudentProfile(id: studentId, name: 'Unknown Student', username: '', studentId: '', level: '', group: '', instructorName: '');
      
      final groupId = profile.groupId;
      final levelId = profile.levelId;

      // 1. Fetch student submissions
      final submissionsSnap = await FirebaseFirestore.instance
          .collection('submissions')
          .where('studentId', isEqualTo: studentId)
          .get();
      final submissions = submissionsSnap.docs
          .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
          .toList();

      // 2. Fetch assignments assigned to student's group & level
      if (groupId != null && groupId.isNotEmpty && levelId != null && levelId.isNotEmpty) {
        final assignmentsSnap = await FirebaseFirestore.instance
            .collection('assignments')
            .where('groupId', isEqualTo: groupId)
            .where('levelId', isEqualTo: levelId)
            .get();
        totalAssignments = assignmentsSnap.docs.length;
      } else {
        totalAssignments = 0;
      }

      correctCount = submissions.where((s) => s.status == GradeStatus.correct).length;
      incorrectCount = submissions.where((s) => s.status == GradeStatus.incorrect).length;
      pendingCount = submissions.where((s) => s.status == GradeStatus.pending).length;
      
      notSubmittedCount = totalAssignments - submissions.length;
      if (notSubmittedCount < 0) notSubmittedCount = 0;

      correctPercent = totalAssignments > 0 ? (correctCount / totalAssignments) * 100 : 0;
      incorrectPercent = totalAssignments > 0 ? (incorrectCount / totalAssignments) * 100 : 0;
    } catch (e) {
      debugPrint('StudentDetailController._init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
