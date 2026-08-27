import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/assignment_model.dart';
import '../../data/repositories/assignment_repository.dart';
import '../../di/service_locator.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../helpers/audit_log_helper.dart';

class InstructorAssignmentController extends ChangeNotifier {
  final AssignmentRepository _repository;
  final AuditLogHelper _audit;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AssignmentModel> _allAssignments = [];
  StreamSubscription<QuerySnapshot>? _assignmentsSub;

  InstructorAssignmentController(this._repository, this._audit) {
    _audit.resolveIdentity();
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    _allAssignments = await _repository.getInstructorAssignments();
    _isLoading = false;
    notifyListeners();

    _assignmentsSub?.cancel();
    _assignmentsSub = FirebaseFirestore.instance
        .collection('assignments')
        .snapshots()
        .skip(1)
        .listen((_) async {
      try {
        _allAssignments = await _repository.getInstructorAssignments();
        notifyListeners();
      } catch (e) {
        debugPrint('InstructorAssignmentController assignments stream error: $e');
      }
    });
  }

  // ── State ──────────────────────────────
  String _tab = 'active'; // 'active' or 'past'
  String _search = '';
  String _filter = 'all'; // 'all', 'overdue', 'central', 'custom'

  // ── Getters ────────────────────────────
  String get tab => _tab;
  String get search => _search;
  String get filter => _filter;

  List<AssignmentModel> get assignments {
    List<AssignmentModel> list = _allAssignments;

    // Tab filter
    if (_tab == 'active') {
      list = list.where((a) => !a.isOverdue).toList();
    } else {
      list = list.where((a) => a.isOverdue).toList();
    }

    // Chip filter
    switch (_filter) {
      case 'central':
        list = list.where((a) => a.type == 'central').toList();
        break;
      case 'custom':
        list = list.where((a) => a.type == 'custom').toList();
        break;
    }

    // Search
    if (_search.isNotEmpty) {
      final term = _search.toLowerCase();
      list = list.where((a) => 
        a.title.toLowerCase().contains(term) || 
        (a.textContent?.toLowerCase().contains(term) ?? false)
      ).toList();
    }

    return list;
  }

  List<AssignmentModel> get allAssignments => _allAssignments;

  // ── Actions ────────────────────────────

  void switchTab(String tab) {
    _tab = tab;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  Future<void> addAssignment(
    String title, {
    DateTime? deadline,
    String? textContent,
    String type = 'custom',
    AssignmentType assignmentType = AssignmentType.text,
    List<String>? choices,
    String? groupId,
    String? groupName,
    String? levelId,
    String? curriculumItemId,
    String? imageUrl,
  }) async {
    if (title.isEmpty) return;
    
    // Check for central assignment duplicate in Firestore
    if (type == 'central' && curriculumItemId != null) {
      final querySnap = await FirebaseFirestore.instance
          .collection('assignments')
          .where('curriculumItemId', isEqualTo: curriculumItemId)
          .where('groupId', isEqualTo: groupId)
          .where('levelId', isEqualTo: levelId)
          .limit(1)
          .get();
      if (querySnap.docs.isNotEmpty) {
        throw Exception('This assignment is already assigned to this group and level.');
      }
    }

    _isLoading = true;
    notifyListeners();
    try {
      // Fetch total students in this group + level combination
      int totalStudents = 0;
      if (groupId != null && levelId != null) {
        final studentSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('groupId', isEqualTo: groupId)
            .where('levelId', isEqualTo: levelId)
            .where('isArchived', isEqualTo: false)
            .get();
        totalStudents = studentSnap.docs.length;
      }

      final assignmentId = await _repository.addInstructorAssignment(
        title,
        deadline: deadline,
        textContent: textContent,
        type: type,
        assignmentType: assignmentType,
        choices: choices,
        groupId: groupId,
        groupName: groupName,
        levelId: levelId,
        curriculumItemId: curriculumItemId,
        imageUrl: imageUrl,
        totalStudents: totalStudents,
      );
      _allAssignments = await _repository.getInstructorAssignments();

      // Resolve instructor name
      final instructorUid = FirebaseAuth.instance.currentUser?.uid;
      String instructorName = 'An instructor';
      if (instructorUid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(instructorUid).get();
        if (doc.exists) {
          instructorName = doc.data()?['displayName'] ?? doc.data()?['name'] ?? 'An instructor';
        }
      }

      final now = DateTime.now();
      final dueDays = deadline != null
          ? DateTime.utc(deadline.year, deadline.month, deadline.day)
              .difference(DateTime.utc(now.year, now.month, now.day))
              .inDays
          : 7;
      final dueText = deadline != null
          ? (dueDays == 0
              ? 'Due today.'
              : dueDays == 1
                  ? 'Due tomorrow.'
                  : 'Due in $dueDays days.')
          : 'Due in 7 days.';
      await _notifyStudents(
        title: 'New Assignment Assigned',
        body: '$instructorName assigned "$title". $dueText',
        type: 'assignment',
        relatedId: assignmentId,
        groupId: groupId,
        levelId: levelId,
      );

      // Audit Log
      _audit.log(
        action: type == 'central' ? 'Assigned central template' : 'Created custom assignment',
        category: 'assignments',
        details: '"$title" | Group: ${groupName ?? '-'} | Level: ${levelId ?? '-'}',
      );
    } catch (e) {
      debugPrint('InstructorAssignmentController.addAssignment error/notify: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAssignment(String id) async {
    final assignment = _allAssignments.where((a) => a.id == id).firstOrNull;
    _isLoading = true;
    notifyListeners();
    await _repository.deleteAssignment(id);
    _allAssignments = await _repository.getInstructorAssignments();
    _isLoading = false;
    notifyListeners();
    _audit.log(action: 'Deleted assignment', category: 'assignments', details: '"${assignment?.title ?? id}"');
  }



  Future<void> updateDeadline(String id, DateTime newDeadline) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateAssignmentDeadline(id, newDeadline);
      final assignment = _allAssignments.firstWhere((a) => a.id == id);

      await _notifyStudents(
        title: 'Assignment Updated',
        body: 'The deadline for "${assignment.title}" has been extended.',
        type: 'assignment',
        relatedId: id,
        groupId: assignment.groupId,
        levelId: assignment.levelId,
      );

      // Audit Log
      _audit.log(
        action: 'Updated assignment deadline',
        category: 'assignments',
        details: '"${assignment.title}" → ${newDeadline.toLocal().toString().split('.').first}',
      );
    } catch (e) {
      debugPrint('InstructorAssignmentController.updateDeadline notification error: $e');
    } finally {
      _allAssignments = await _repository.getInstructorAssignments();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateContent(String id, String title, String textContent,
      AssignmentType assignmentType, List<String> choices,
      {String? groupId, String? groupName, String? levelId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateAssignmentContent(id, title, textContent, assignmentType, choices,
          groupId: groupId, groupName: groupName, levelId: levelId);
      final assignment = _allAssignments.firstWhere((a) => a.id == id);

      await _notifyStudents(
        title: 'Assignment Updated',
        body: 'The instructions for "${assignment.title}" have been updated.',
        type: 'assignment',
        relatedId: id,
        groupId: groupId ?? assignment.groupId,
        levelId: levelId ?? assignment.levelId,
      );

      // Audit Log
      _audit.log(
        action: 'Updated assignment content',
        category: 'assignments',
        details: '"$title"',
      );
    } catch (e) {
      debugPrint('InstructorAssignmentController.updateContent notification/audit error: $e');
    } finally {
      _allAssignments = await _repository.getInstructorAssignments();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper to send in-app notifications to all active students in a group/level.
  Future<void> _notifyStudents({
    required String title,
    required String body,
    required String type,
    required String relatedId,
    String? groupId,
    String? levelId,
  }) async {
    final List<String> studentUids = [];
    if (groupId != null && groupId.isNotEmpty) {
      var query = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('groupId', isEqualTo: groupId)
          .where('isArchived', isEqualTo: false);
      if (levelId != null && levelId.isNotEmpty) {
        query = query.where('levelId', isEqualTo: levelId);
      }
      final snap = await query.get();
      studentUids.addAll(snap.docs.map((d) => d.id));
    } else if (levelId != null && levelId.isNotEmpty) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('levelId', isEqualTo: levelId)
          .where('isArchived', isEqualTo: false)
          .get();
      studentUids.addAll(snap.docs.map((d) => d.id));
    }

    if (studentUids.isNotEmpty) {
      final notifRepo = getIt<NotificationRepository>();
      for (final uid in studentUids) {
        final notif = AppNotification(
          id: '',
          title: title,
          body: body,
          type: type,
          relatedId: relatedId,
          createdAt: DateTime.now(),
          recipientUid: uid,
        );
        await notifRepo.addNotification(notif);
      }
    }
  }

  /// Cancel active Firestore stream subscription.
  void cancelSubscriptions() {
    _assignmentsSub?.cancel();
    _assignmentsSub = null;
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
