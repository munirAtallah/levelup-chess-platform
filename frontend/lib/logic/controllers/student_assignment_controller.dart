import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/assignment_model.dart';
import '../../data/models/submission_model.dart';

class StudentAssignmentController extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<AssignmentModel> _allAssignments = [];
  List<SubmissionModel> _studentSubmissions = [];

  // ── State ──────────────────────────────
  String _tab = 'pending'; // 'pending' or 'submitted'
  String _search = '';

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userDocSub;
  StreamSubscription<QuerySnapshot>? _assignmentsSub;
  StreamSubscription<QuerySnapshot>? _submissionsSub;

  String? _subscribedGroupId;
  String? _subscribedLevelId;

  StudentAssignmentController() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToStreams(user.uid);
      } else {
        _clear();
      }
    });
  }

  void _clear() {
    _userDocSub?.cancel();
    _assignmentsSub?.cancel();
    _submissionsSub?.cancel();
    _userDocSub = null;
    _assignmentsSub = null;
    _submissionsSub = null;
    _subscribedGroupId = null;
    _subscribedLevelId = null;
    _allAssignments = [];
    _studentSubmissions = [];
    _isLoading = false;
    notifyListeners();
  }

  void _subscribeToStreams(String uid) {
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((userSnap) {
      if (!userSnap.exists) {
        _clear();
        return;
      }
      
      final userData = userSnap.data();
      if (userData == null) return;

      final groupId = userData['groupId'] as String?;
      final levelId = userData['levelId'] as String?;

      // Handle submissions stream
      _submissionsSub ??= FirebaseFirestore.instance
          .collection('submissions')
          .where('studentId', isEqualTo: uid)
          .snapshots()
          .listen((subSnap) {
        _studentSubmissions = subSnap.docs
            .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('StudentAssignmentController: submissions stream error: $e');
        _isLoading = false;
        notifyListeners();
      });

      // Handle assignments stream subscription
      if (_subscribedGroupId != groupId || _subscribedLevelId != levelId) {
        _subscribedGroupId = groupId;
        _subscribedLevelId = levelId;
        _assignmentsSub?.cancel();

        if (groupId != null && groupId.isNotEmpty) {
          _assignmentsSub = FirebaseFirestore.instance
              .collection('assignments')
              .where('groupId', isEqualTo: groupId)
              .snapshots()
              .listen((assignSnap) {
            final list = assignSnap.docs
                .map((doc) => AssignmentModel.fromMap(doc.data(), doc.id))
                .toList();

            // Filter assignments based on levelId in memory (just like getStudentAssignments)
            _allAssignments = list.where((model) {
              return model.levelId == null ||
                  model.levelId!.isEmpty ||
                  model.levelId == levelId;
            }).toList();

            _allAssignments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _isLoading = false;
            notifyListeners();
          }, onError: (e) {
            debugPrint('StudentAssignmentController: assignments stream error: $e');
            _isLoading = false;
            notifyListeners();
          });
        } else {
          _allAssignments = [];
          _isLoading = false;
          notifyListeners();
        }
      }
    }, onError: (e) {
      debugPrint('StudentAssignmentController: user doc stream error: $e');
    });
  }

  // ── Getters ────────────────────────────
  String get tab => _tab;
  String get search => _search;

  SubmissionModel? getSubmissionForAssignment(String assignmentId) {
    try {
      return _studentSubmissions.firstWhere((s) => s.assignmentId == assignmentId);
    } catch (_) {
      return null;
    }
  }

  bool isSubmitted(String assignmentId) {
    return _studentSubmissions.any((s) => s.assignmentId == assignmentId);
  }

  bool isGraded(String assignmentId) {
    final sub = getSubmissionForAssignment(assignmentId);
    return sub != null && sub.status != GradeStatus.pending;
  }

  List<AssignmentModel> get pendingAssignments {
    var list = _allAssignments.where((a) => !isGraded(a.id)).toList();
    if (_search.isNotEmpty) {
      final term = _search.toLowerCase();
      list = list.where((a) => 
        a.title.toLowerCase().contains(term) || 
        (a.textContent?.toLowerCase().contains(term) ?? false)
      ).toList();
    }
    return list;
  }

  List<AssignmentModel> get submittedAssignments {
    var list = _allAssignments.where((a) => isGraded(a.id)).toList();
    if (_search.isNotEmpty) {
      final term = _search.toLowerCase();
      list = list.where((a) => 
        a.title.toLowerCase().contains(term) || 
        (a.textContent?.toLowerCase().contains(term) ?? false)
      ).toList();
    }
    return list;
  }

  int get pendingCount => _allAssignments.where((a) => !isGraded(a.id)).length;
  int get submittedCount => _allAssignments.where((a) => isGraded(a.id)).length;
  int get pendingReviewCount => _studentSubmissions.where((s) => s.status == GradeStatus.pending).length;

  // ── Actions ────────────────────────────

  Future<void> loadAssignments() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _subscribeToStreams(uid);
    }
  }

  void switchTab(String tab) {
    _tab = tab;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  /// Cancel all active Firestore stream subscriptions without disposing the
  /// controller. Called by the logout helper before FirebaseAuth.signOut().
  void cancelSubscriptions() {
    _authSub?.cancel();
    _authSub = null;
    _userDocSub?.cancel();
    _userDocSub = null;
    _assignmentsSub?.cancel();
    _assignmentsSub = null;
    _submissionsSub?.cancel();
    _submissionsSub = null;
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
