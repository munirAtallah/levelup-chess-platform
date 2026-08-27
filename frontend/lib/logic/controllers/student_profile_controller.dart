/// Logic Tier — Controller
/// Path: lib/logic/controllers/student_profile_controller.dart
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/student_profile_model.dart';
import '../../data/repositories/student_profile_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfileController extends ChangeNotifier {
  final StudentProfileRepository _repository;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<QuerySnapshot>? _submissionsSub;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StudentProfile? _profile;

  StudentProfileController(this._repository) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToUserDoc(user.uid);
      } else {
        _unsubscribe();
      }
    });
  }

  String? _error;
  String? get error => _error;

  void _subscribeToUserDoc(String uid) {
    _isLoading = _profile == null;
    _error = null;
    notifyListeners();

    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
      _refreshProfile(uid);
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });

    _submissionsSub?.cancel();
    _submissionsSub = FirebaseFirestore.instance
        .collection('submissions')
        .where('studentId', isEqualTo: uid)
        .snapshots()
        .listen((snap) async {
      _refreshProfile(uid);
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _refreshProfile(String uid) async {
    try {
      final profile = await _repository.getProfileById(uid);
      if (profile != null) {
        _profile = profile;
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('StudentProfileController user stream error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _unsubscribe() {
    _userSub?.cancel();
    _userSub = null;
    _submissionsSub?.cancel();
    _submissionsSub = null;
    _profile = null;
    notifyListeners();
  }

  // ── Getters ────────────────────────────
  StudentProfile get profile => _profile ?? StudentProfile(
        id: '',
        name: '',
        username: '',
        studentId: '',
        level: '',
        group: '',
        instructorName: '',
        submissions: 0,
        graded: 0,
        correct: 0,
      );

  /// Cancel all active Firestore stream subscriptions without disposing the
  /// controller. Called by the logout helper before FirebaseAuth.signOut().
  void cancelSubscriptions() {
    _authSub?.cancel();
    _authSub = null;
    _userSub?.cancel();
    _userSub = null;
    _submissionsSub?.cancel();
    _submissionsSub = null;
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
