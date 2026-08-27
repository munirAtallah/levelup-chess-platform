/// Logic Tier — Controller
/// Path: lib/logic/controllers/student_dashboard_controller.dart
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/curriculum_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/assignment_model.dart';
import '../../di/service_locator.dart';
import 'student_assignment_controller.dart';
import 'student_notification_controller.dart';
import '../../data/models/notification_model.dart';

class StudentDashboardController extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _search = '';
  String _studentName = '';
  String _levelLabel = '';
  String _groupLabel = '—';
  String _instructorName = '—';
  int _myGroupsCount = 0;
  int _classmatesCount = 0;
  List<CurriculumItem> _allLessons = [];
  List<GroupModel> _myGroups = [];

  StreamSubscription<User?>? _authSub;
  late final StudentAssignmentController _assignmentController;
  late final StudentNotificationController _notificationController;

  StreamSubscription<DocumentSnapshot>? _userDocSub;
  StreamSubscription<DocumentSnapshot>? _curriculumSub;
  StreamSubscription<QuerySnapshot>? _assignedMaterialsSub;
  StreamSubscription<DocumentSnapshot>? _groupSub;

  Set<String> _assignedMaterialIds = {};
  LevelModel? _currentLevel;

  String? _subscribedGroupId;
  String? _subscribedAssignedMaterialsGroupId;
  String? _subscribedAssignedMaterialsLevelId;

  StudentDashboardController() {
    _assignmentController = getIt<StudentAssignmentController>();
    _notificationController = getIt<StudentNotificationController>();
    _assignmentController.addListener(notifyListeners);
    _notificationController.addListener(notifyListeners);

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _load();
      } else {
        _clear();
      }
    });
  }

  void _clear() {
    _studentName = '';
    _levelLabel = '';
    _groupLabel = '—';
    _instructorName = '—';
    _myGroupsCount = 0;
    _classmatesCount = 0;
    _allLessons = [];
    _myGroups = [];
    _subscribedGroupId = null;
    _subscribedAssignedMaterialsGroupId = null;
    _subscribedAssignedMaterialsLevelId = null;
    _userDocSub?.cancel();
    _curriculumSub?.cancel();
    _assignedMaterialsSub?.cancel();
    _groupSub?.cancel();
    _assignedMaterialIds = {};
    _currentLevel = null;
    notifyListeners();
  }

  // ── Initial load ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    await _fetchAll();
    _isLoading = false;
    notifyListeners();
    _startStreams();
  }

  Future<void> _fetchAll() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final db = FirebaseFirestore.instance;
      String? levelId;
      String? groupId;

      // 1. User document — display name, levelId, and groupId
      final userDoc = await db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _studentName = data['name'] as String? ?? '';
        levelId = data['levelId'] as String?;
        groupId = data['groupId'] as String?;
      }

      // 2. Fetch Group document directly (authorized by security rules)
      Map<String, dynamic>? groupData;
      final List<GroupModel> myGroups = [];
      int myGroupsCount = 0;
      int classmatesCount = 0;

      if (groupId != null && groupId.isNotEmpty) {
        final doc = await db.collection('groups').doc(groupId).get();
        if (doc.exists && doc.data() != null) {
          groupData = doc.data();
          final groupModel = GroupModel.fromMap(groupData!, doc.id);
          myGroups.add(groupModel);
          myGroupsCount = 1;
          
          // Find matching student embed inside group to extract level fallback
          final matchingStudent = groupModel.students.firstWhere(
            (s) => s.id == uid,
            orElse: () => const GroupStudentEmbed(id: '', name: '', level: ''),
          );
          
          if (matchingStudent.id.isNotEmpty) {
            if (levelId == null || levelId.isEmpty) {
              levelId = matchingStudent.level;
              debugPrint('StudentDashboardController: Fallback levelId from group student embed: $levelId');
            }
          }
          
          classmatesCount = groupModel.students.length;
        }
      }

      _myGroups = myGroups;
      _myGroupsCount = myGroupsCount;
      _classmatesCount = classmatesCount;

      if (groupData != null) {
        _groupLabel = groupData['name'] as String? ?? '—';
        final instructorIds =
            List<String>.from(groupData['instructorIds'] as List? ?? []);
        if (instructorIds.isNotEmpty) {
          final instDoc =
              await db.collection('users').doc(instructorIds.first).get();
          _instructorName = instDoc.data()?['name'] as String? ?? '—';
        }
      }
      debugPrint('StudentDashboardController: Final resolved levelId: $levelId, groupId: $groupId');

      if (groupId != null && groupId.isNotEmpty) {
        _subscribeToGroup(groupId);
      }

      // 3. Level name and visible lesson library
      if (levelId != null && levelId.isNotEmpty) {
        final levelDoc =
            await db.collection('curriculum').doc(levelId).get();
        if (levelDoc.exists) {
          _levelLabel = levelDoc.data()?['name'] as String? ?? levelId;
        } else {
          _levelLabel = levelId;
        }
      }

      if (groupId != null && groupId.isNotEmpty && levelId != null && levelId.isNotEmpty) {
        _subscribeToAssignedMaterials(groupId, levelId);
      }
    } catch (e) {
      debugPrint('StudentDashboardController._fetchAll error: $e');
    }
  }

  // ── Real-time streams ──────────────────────────────────────────────────────

  void _startStreams() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .skip(1) // skip the first event which duplicates the initial load
        .listen((snap) async {
      if (!snap.exists || snap.data() == null) return;
      await _fetchAll();
      notifyListeners();
    }, onError: (e) {
      debugPrint('StudentDashboardController: user doc stream error: $e');
    });
  }

  void _subscribeToGroup(String groupId) {
    if (_subscribedGroupId == groupId) return;
    _subscribedGroupId = groupId;
    _groupSub?.cancel();
    _groupSub = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .skip(1)
        .listen((snap) async {
      await _fetchAll();
      notifyListeners();
    }, onError: (e) {
      debugPrint('StudentDashboardController: group stream error: $e');
    });
  }

  void _subscribeToAssignedMaterials(String groupId, String levelId) {
    if (_subscribedAssignedMaterialsGroupId == groupId && _subscribedAssignedMaterialsLevelId == levelId) return;
    _subscribedAssignedMaterialsGroupId = groupId;
    _subscribedAssignedMaterialsLevelId = levelId;

    _assignedMaterialsSub?.cancel();
    _curriculumSub?.cancel();

    // 1. Subscribe to assigned materials
    _assignedMaterialsSub = FirebaseFirestore.instance
        .collection('assigned_materials')
        .where('groupId', isEqualTo: groupId)
        .where('levelId', isEqualTo: levelId)
        .snapshots()
        .listen((snap) {
      _assignedMaterialIds = snap.docs.map((doc) => doc.data()['materialId'] as String).toSet();
      _updateLessons();
    }, onError: (e) {
      debugPrint('StudentDashboardController: assigned_materials stream error: $e');
    });

    // 2. Subscribe to curriculum level document
    _curriculumSub = FirebaseFirestore.instance
        .collection('curriculum')
        .doc(levelId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        _currentLevel = LevelModel.fromMap(snap.data()!, snap.id);
        _levelLabel = _currentLevel!.name;
      } else {
        _currentLevel = null;
        _levelLabel = levelId;
      }
      _updateLessons();
    }, onError: (e) {
      debugPrint('StudentDashboardController: curriculum level stream error: $e');
    });
  }

  void _updateLessons() {
    if (_currentLevel == null) {
      _allLessons = [];
      notifyListeners();
      return;
    }

    final List<CurriculumItem> lessons = [];
    for (final week in _currentLevel!.weeks) {
      for (final item in week.items) {
        // Show item if it's a material, not starting with ca_, visible, and assigned
        if (item.type == CurriculumItemType.material &&
            !item.id.startsWith('ca_') &&
            item.visible &&
            _assignedMaterialIds.contains(item.id)) {
          lessons.add(item);
        }
      }
    }
    _allLessons = lessons;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────


  // ── Dispose ────────────────────────────────────────────────────────────────

  /// Cancel all active Firestore stream subscriptions without disposing the
  /// controller. Called by the logout helper before FirebaseAuth.signOut().
  void cancelSubscriptions() {
    _authSub?.cancel();
    _authSub = null;
    _userDocSub?.cancel();
    _userDocSub = null;
    _curriculumSub?.cancel();
    _curriculumSub = null;
    _assignedMaterialsSub?.cancel();
    _assignedMaterialsSub = null;
    _groupSub?.cancel();
    _groupSub = null;
  }

  @override
  void dispose() {
    _assignmentController.removeListener(notifyListeners);
    _notificationController.removeListener(notifyListeners);
    cancelSubscriptions();
    super.dispose();
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  String get search => _search;
  String get studentName => _studentName;
  String get levelLabel => _levelLabel;
  String get groupLabel => _groupLabel;
  String get instructorName => _instructorName;
  int get lessonCount => _allLessons.length;
  int get tasksDue => _assignmentController.pendingCount;
  int get newNotifications => _notificationController.unreadCount;
  int get myGroupsCount => _myGroupsCount;
  int get classmatesCount => _classmatesCount;
  int get pendingReviewCount => _assignmentController.pendingReviewCount;
  List<AssignmentModel> get activeAssignments => _assignmentController.pendingAssignments;
  List<GroupModel> get myGroups => _myGroups;
  AppNotification? get latestNotification =>
      _notificationController.notifications.isNotEmpty
          ? _notificationController.notifications.first
          : null;

  List<CurriculumItem> get lessons {
    if (_search.isEmpty) return _allLessons;
    final term = _search.toLowerCase();
    return _allLessons.where((l) {
      final matchTitle = l.title.toLowerCase().contains(term);
      final matchTag = l.searchTags.any((t) => t.toLowerCase().contains(term));
      return matchTitle || matchTag;
    }).toList();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }
}
