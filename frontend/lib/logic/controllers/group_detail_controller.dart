/// Logic Tier — Controller
/// Path: lib/logic/controllers/group_detail_controller.dart
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/curriculum_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../helpers/audit_log_helper.dart';

class GroupDetailController extends ChangeNotifier {
  final String groupId;
  final GroupRepository _groupRepository;
  final UserRepository _userRepository;
  final CurriculumRepository _curriculumRepository;
  final AuditLogHelper _audit;

  late GroupModel group;
  List<UserModel> _allInstructors = [];
  List<UserModel> _allStudents = [];
  List<LevelModel> _levels = [];
  StreamSubscription<GroupModel?>? _groupSub;

  UserRole? _currentUserRole;
  List<String> _currentUserAssignedLevels = [];
  Map<String, String> _groupIdToName = {};

  UserRole? get currentUserRole => _currentUserRole;
  List<String> get currentUserAssignedLevels => _currentUserAssignedLevels;

  String? getGroupName(String? id) => id != null ? _groupIdToName[id] : null;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<LevelModel> get levels => List.unmodifiable(_levels);

  GroupDetailController(this.groupId, this._groupRepository, this._userRepository, this._curriculumRepository, this._audit) {
    _audit.resolveIdentity();
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      UserModel? currentUser;
      if (uid != null) {
        currentUser = await _userRepository.getStudentById(uid);
      }
      _currentUserRole = currentUser?.role;
      _currentUserAssignedLevels = currentUser?.assignedLevels ?? [];

      final results = await Future.wait([
        _groupRepository.getGroupById(groupId),
        _userRepository.getInstructors(),
        _userRepository.getStudents(),
        _curriculumRepository.getLevels(),
        _groupRepository.getGroups(),
      ]);
      group = (results[0] as GroupModel?) ??
          GroupModel(id: groupId, serialNumber: 0, name: 'Unknown Group', instructorIds: [], students: [], createdAt: DateTime.now());
      _allInstructors = results[1] as List<UserModel>;
      
      final rawStudents = results[2] as List<UserModel>;
      final rawLevels = results[3] as List<LevelModel>;
      final allGroups = results[4] as List<GroupModel>;
      _groupIdToName = { for (var g in allGroups) g.id : g.name };

      if (_currentUserRole == UserRole.instructor) {
        _allStudents = rawStudents.where((s) => _currentUserAssignedLevels.contains(s.levelId)).toList();
        _levels = rawLevels.where((l) => _currentUserAssignedLevels.contains(l.id)).toList();
      } else {
        _allStudents = rawStudents;
        _levels = rawLevels;
      }

      _groupSub?.cancel();
      _groupSub = _groupRepository.streamGroupById(groupId).listen((updatedGroup) {
        if (updatedGroup != null) {
          group = updatedGroup;
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('GroupDetailController: group stream error: $e');
      });
    } catch (e) {
      debugPrint('GroupDetailController._init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── State ──────────────────────────────
  String _search = '';
  String _availableInstructorsSearch = '';
  String _availableStudentsSearch = '';
  String? _selectedLevelFilter;

  final Set<String> _bulkSelectedStudentIds = {};

  // ── Getters ────────────────────────────
  String get search => _search;
  String get availableInstructorsSearch => _availableInstructorsSearch;
  String get availableStudentsSearch => _availableStudentsSearch;
  String? get selectedLevelFilter => _selectedLevelFilter;

  Set<String> get bulkSelectedStudentIds => Set.unmodifiable(_bulkSelectedStudentIds);
  int get bulkSelectionCount => _bulkSelectedStudentIds.length;

  List<UserModel> get groupInstructors {
    return _allInstructors.where((i) => group.instructorIds.contains(i.id)).toList();
  }

  List<UserModel> get availableInstructors {
    final available = _allInstructors.where((i) {
      if (group.instructorIds.contains(i.id)) return false;
      // Filter: only show instructors whose assignedLevels has at least one level in common with group's levelIds (Rule 3)
      final hasCommonLevel = i.assignedLevels.any((l) => group.levelIds.contains(l));
      return hasCommonLevel;
    }).toList();
    if (_availableInstructorsSearch.isEmpty) return available;
    final term = _availableInstructorsSearch.toLowerCase();
    return available.where((i) => i.name.toLowerCase().contains(term) || (i.email ?? '').toLowerCase().contains(term)).toList();
  }

  Map<String, List<UserModel>> get studentsByLevel {
    final Map<String, List<UserModel>> result = {};

    for (final entry in group.studentLevels.entries) {
      final studentId = entry.key;
      final levelId = entry.value;

      if (_currentUserRole == UserRole.instructor && !_currentUserAssignedLevels.contains(levelId)) {
        continue;
      }

      final user = _allStudents.where((s) => s.id == studentId).firstOrNull;
      if (user == null) continue;

      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final matchesName = user.name.toLowerCase().contains(q);
        final matchesUsername = (user.username ?? '').toLowerCase().contains(q);
        final matchesStudentNum = (user.studentNumber ?? '').toLowerCase().contains(q);
        if (!matchesName && !matchesUsername && !matchesStudentNum) continue;
      }

      if (_selectedLevelFilter != null && _selectedLevelFilter != levelId) {
        continue;
      }

      result.putIfAbsent(levelId, () => []);
      result[levelId]!.add(user);
    }

    final sorted = Map.fromEntries(
      result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

  List<UserModel> get allGroupStudents {
    return _allStudents.where((s) => group.studentLevels.containsKey(s.id)).toList();
  }

  List<UserModel> get availableStudents {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    var list = _allStudents.where((s) {
      if (group.studentLevels.containsKey(s.id)) return false;
      return s.levelId != null && group.levelIds.contains(s.levelId);
    }).toList();

    if (_currentUserRole == UserRole.instructor && uid != null) {
      list = list.where((s) => s.createdBy == uid).toList();
    }
    
    if (_availableStudentsSearch.isEmpty) return list;
    
    final term = _availableStudentsSearch.toLowerCase();
    return list.where((s) =>
      s.name.toLowerCase().contains(term) ||
      (s.username ?? '').toLowerCase().contains(term) ||
      (s.studentNumber ?? '').toLowerCase().contains(term)
    ).toList();
  }

  // ── Actions ────────────────────────────
  void setSearch(String value) { _search = value; notifyListeners(); }
  void setLevelFilter(String? levelId) { _selectedLevelFilter = levelId; notifyListeners(); }
  void setAvailableInstructorsSearch(String value) { _availableInstructorsSearch = value; notifyListeners(); }
  void setAvailableStudentsSearch(String value) { _availableStudentsSearch = value; notifyListeners(); }

  void toggleBulkStudent(String studentId) {
    if (_bulkSelectedStudentIds.contains(studentId)) {
      _bulkSelectedStudentIds.remove(studentId);
    } else {
      _bulkSelectedStudentIds.add(studentId);
    }
    notifyListeners();
  }

  void clearBulkSelection() {
    _bulkSelectedStudentIds.clear();
    notifyListeners();
  }

  Future<bool> deleteGroup() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _groupRepository.deleteGroup(groupId);
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _initQuietly() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      UserModel? currentUser;
      if (uid != null) {
        currentUser = await _userRepository.getStudentById(uid);
      }
      _currentUserRole = currentUser?.role;
      _currentUserAssignedLevels = currentUser?.assignedLevels ?? [];

      final results = await Future.wait([
        _groupRepository.getGroupById(groupId),
        _userRepository.getInstructors(),
        _userRepository.getStudents(),
        _curriculumRepository.getLevels(),
        _groupRepository.getGroups(),
      ]);
      group = (results[0] as GroupModel?) ??
          GroupModel(id: groupId, serialNumber: 0, name: 'Unknown Group', instructorIds: [], students: [], createdAt: DateTime.now());
      _allInstructors = results[1] as List<UserModel>;
      
      final rawStudents = results[2] as List<UserModel>;
      final rawLevels = results[3] as List<LevelModel>;
      final allGroups = results[4] as List<GroupModel>;
      _groupIdToName = { for (var g in allGroups) g.id : g.name };

      if (_currentUserRole == UserRole.instructor) {
        _allStudents = rawStudents.where((s) => _currentUserAssignedLevels.contains(s.levelId)).toList();
        _levels = rawLevels.where((l) => _currentUserAssignedLevels.contains(l.id)).toList();
      } else {
        _allStudents = rawStudents;
        _levels = rawLevels;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('GroupDetailController._initQuietly error: $e');
    }
  }

  Future<void> addInstructor(String instructorId) async {
    try {
      await _groupRepository.addInstructorToGroup(groupId, instructorId);
      _availableInstructorsSearch = '';
      await _initQuietly();
      final instructor = _allInstructors.where((i) => i.id == instructorId).firstOrNull;
      _audit.log(action: 'Added instructor to group', category: 'groups', targetPersonName: instructor?.name, details: group.name);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeInstructor(String instructorId) async {
    final instructor = _allInstructors.where((i) => i.id == instructorId).firstOrNull;
    try {
      await _groupRepository.removeInstructorFromGroup(groupId, instructorId);
      await _initQuietly();
      _audit.log(action: 'Removed instructor from group', category: 'groups', targetPersonName: instructor?.name, details: group.name);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addStudent(String studentId, String levelId) async {
    if (_currentUserRole == UserRole.instructor && !_currentUserAssignedLevels.contains(levelId)) {
      throw Exception('Unauthorized: You can only assign students to your assigned levels.');
    }
    if (!group.levelIds.contains(levelId)) {
      throw Exception('Validation failed: Student level does not match group levels.');
    }
    final student = _allStudents.where((s) => s.id == studentId).firstOrNull;
    if (student == null) throw Exception('Student not found');

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserRole == UserRole.instructor && currentUid != null) {
      if (student.createdBy != currentUid) {
        throw Exception('Unauthorized: Instructors can only add students they created.');
      }
    }

    try {
      await _groupRepository.addStudentToGroup(
        groupId,
        studentId,
        levelId,
        name: student.name,
        oldGroupId: student.groupId,
      );
      _availableStudentsSearch = '';
      await _initQuietly();
      _audit.log(action: 'Added student to group', category: 'groups', targetPersonName: student.name, targetStudentNumber: student.studentNumber, details: group.name);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> bulkAddStudents(String levelId) async {
    if (_currentUserRole == UserRole.instructor && !_currentUserAssignedLevels.contains(levelId)) {
      throw Exception('Unauthorized: You can only assign students to your assigned levels.');
    }
    if (!group.levelIds.contains(levelId)) {
      throw Exception('Validation failed: Student level does not match group levels.');
    }
    if (_bulkSelectedStudentIds.isEmpty) return;
    final idsToAdd = List<String>.from(_bulkSelectedStudentIds);
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      for (final studentId in idsToAdd) {
        final student = _allStudents.where((s) => s.id == studentId).firstOrNull;
        if (student == null) continue;
        if (_currentUserRole == UserRole.instructor && currentUid != null) {
          if (student.createdBy != currentUid) {
            throw Exception('Unauthorized: Instructors can only add students they created.');
          }
        }
        await _groupRepository.addStudentToGroup(
          groupId,
          studentId,
          levelId,
          name: student.name,
          oldGroupId: student.groupId,
        );
      }
      _bulkSelectedStudentIds.clear();
      _availableStudentsSearch = '';
      await _initQuietly();
      _audit.log(action: 'Bulk added ${idsToAdd.length} students to group', category: 'groups', details: group.name);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addLevelToGroup(String levelId) async {
    await _groupRepository.addLevelToGroup(groupId, levelId);
    await _initQuietly();
    _audit.log(action: 'Added level to group', category: 'groups', details: 'Level $levelId in ${group.name}');
  }

  Future<void> removeLevelFromGroup(String levelId) async {
    // Rule 6: check if any student currently in the group has this level
    final count = group.students.where((s) => s.level == levelId).length;
    if (count > 0) {
      throw Exception('Cannot remove level — $count student(s) are still assigned to this level.');
    }
    await _groupRepository.removeLevelFromGroup(groupId, levelId);
    await _initQuietly();
    _audit.log(action: 'Removed level from group', category: 'groups', details: 'Level $levelId in ${group.name}');
  }

  Future<void> renameGroup(String newName) async {
    final oldName = group.name;
    await _groupRepository.updateGroup(groupId, newName);
    await _initQuietly();
    _audit.log(action: 'Renamed group', category: 'groups', details: '"$oldName" → "$newName"');
  }

  Future<List<GroupModel>> getTransferTargetGroups(String studentLevelId) async {
    final allGroups = await _groupRepository.getGroups();
    return allGroups
        .where((g) => g.id != groupId && g.levelIds.contains(studentLevelId))
        .toList();
  }

  Future<void> transferStudent(String studentId, String targetGroupId) async {
    final student = _allStudents.where((s) => s.id == studentId).firstOrNull;
    if (student == null) throw Exception('Student not found');
    final levelId = student.levelId;
    if (levelId == null) throw Exception('Student has no level assigned');

    await _groupRepository.addStudentToGroup(
      targetGroupId,
      studentId,
      levelId,
      name: student.name,
      oldGroupId: groupId,
    );
    await _initQuietly();
    _audit.log(
      action: 'Transferred student',
      category: 'groups',
      targetPersonName: student.name,
      targetStudentNumber: student.studentNumber,
      details: 'From group $groupId to $targetGroupId',
    );
  }

  /// Creates a new student, then adds them to this group.
  Future<UserModel> createStudent(
    String fullName,
    String levelId, {
    required String username,
    required String pinCode,
    String? gender,
    DateTime? dateOfBirth,
    String? location,
  }) async {
    if (_currentUserRole == UserRole.instructor && !_currentUserAssignedLevels.contains(levelId)) {
      throw Exception('Unauthorized: You can only create students for your assigned levels.');
    }
    try {
      final actualUsername = username.trim();
      final actualPinCode = pinCode.trim();

      final result = await _userRepository.addStudent(
        name: fullName,
        username: actualUsername,
        pinCode: actualPinCode,
        levelId: levelId,
        gender: gender,
        dateOfBirth: dateOfBirth,
        location: location,
      );

      await _groupRepository.addStudentToGroup(
        groupId,
        result.uid,
        levelId,
        name: fullName,
      );

      if (!group.levelIds.contains(levelId)) {
        await _groupRepository.addLevelToGroup(groupId, levelId);
      }

      await _initQuietly();

      final created = UserModel(
        id: result.uid,
        userNumber: result.userNumber,
        name: fullName,
        email: '${actualUsername.replaceAll('_', '').replaceAll('.', '')}@levelup.edu',
        role: UserRole.student,
        studentNumber: '#${result.userNumber}',
        username: actualUsername,
        pinCode: actualPinCode,
        lastActive: null,
        gender: gender,
        dateOfBirth: dateOfBirth,
        location: location,
      );
      _audit.log(action: 'Created and added student to group', category: 'users', targetPersonName: fullName, targetStudentNumber: '#${result.userNumber}', details: 'Group: ${group.name} | Level: $levelId');
      return created;
    } catch (e) {
      rethrow;
    }
  }

  /// Creates multiple students, then adds them all to this group.
  /// Each entry must include: name, username (manually entered), levelId.
  Future<List<UserModel>> bulkCreateStudents(
      List<({
        String name,
        String username,
        String levelId,
        String? gender,
        DateTime? dateOfBirth,
        String? location
      })> entries) async {
    final created = <UserModel>[];
    try {
      for (final e in entries) {
        if (_currentUserRole == UserRole.instructor && !_currentUserAssignedLevels.contains(e.levelId)) {
          throw Exception('Unauthorized: You can only create students for your assigned levels.');
        }
        final pinCode = (100000 + Random().nextInt(900000)).toString();
        final u = e.username.toLowerCase().trim();

        final result = await _userRepository.addStudent(
          name: e.name,
          username: u,
          pinCode: pinCode,
          levelId: e.levelId,
          gender: e.gender,
          dateOfBirth: e.dateOfBirth,
          location: e.location,
        );

        await _groupRepository.addStudentToGroup(
          groupId,
          result.uid,
          e.levelId,
          name: e.name,
        );

        if (!group.levelIds.contains(e.levelId)) {
          await _groupRepository.addLevelToGroup(groupId, e.levelId);
        }

        created.add(UserModel(
          id: result.uid,
          userNumber: result.userNumber,
          name: e.name,
          email: '${u.replaceAll('_', '').replaceAll('.', '')}@levelup.edu',
          role: UserRole.student,
          studentNumber: '#${result.userNumber}',
          username: u,
          pinCode: pinCode,
          lastActive: null,
          gender: e.gender,
          dateOfBirth: e.dateOfBirth,
          location: e.location,
        ));
      }
      await _initQuietly();
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeStudent(String studentId) async {
    final student = _allStudents.where((s) => s.id == studentId).firstOrNull;
    try {
      await _groupRepository.removeStudentFromGroup(groupId, studentId);
      await _initQuietly();
      _audit.log(action: 'Removed student from group', category: 'groups', targetPersonName: student?.name, targetStudentNumber: student?.studentNumber, details: group.name);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStudent(String studentId) async {
    final student = _allStudents.where((s) => s.id == studentId).firstOrNull;
    try {
      await _userRepository.deleteStudent(studentId);
      await _groupRepository.removeStudentFromGroup(group.id, studentId);
      group = await _groupRepository.getGroupById(group.id) ?? group;
      final rawStudents = await _userRepository.getStudents();
      if (_currentUserRole == UserRole.instructor) {
        _allStudents = rawStudents.where((s) => _currentUserAssignedLevels.contains(s.levelId)).toList();
      } else {
        _allStudents = rawStudents;
      }
      notifyListeners();
      _audit.log(action: 'Archived student from group', category: 'users', targetPersonName: student?.name, targetStudentNumber: student?.studentNumber, details: group.name);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> usernameExists(String username) => _userRepository.usernameExists(username);

  /// Generates a new 6-digit PIN, persists it to Firebase Auth (via Cloud Function),
  /// the Firestore user doc, and the embedded student array in the group document.
  Future<String> resetStudentPin(String studentId) async {
    final newPin = (100000 + Random().nextInt(900000)).toString();

    await _userRepository.resetStudentPin(studentId, newPin);

    final index = _allStudents.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final old = _allStudents[index];
      _allStudents[index] = old.copyWith(pinCode: newPin);
      notifyListeners();
      _audit.log(action: 'Reset student PIN', category: 'users', targetPersonName: old.name, targetStudentNumber: old.studentNumber, details: group.name);
    }

    return newPin;
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    super.dispose();
  }
}
