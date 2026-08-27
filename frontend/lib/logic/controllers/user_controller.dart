/// Logic Tier — Controller
/// Path: lib/logic/controllers/user_controller.dart
library;

import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/curriculum_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../helpers/audit_log_helper.dart';

class UserController extends ChangeNotifier {
  final UserRepository _repository;
  final GroupRepository _groupRepository;
  final CurriculumRepository _curriculumRepository;
  final AuditLogHelper _audit;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<UserModel> _instructors = [];
  List<UserModel> _students = [];
  List<UserModel> _archivedUsers = [];
  List<GroupModel> _archivedGroups = [];
  List<LevelModel> _levels = [];

  List<LevelModel> get levels => List.unmodifiable(_levels);

  UserController(this._repository, this._groupRepository, this._curriculumRepository, this._audit) {
    _audit.resolveIdentity();
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getInstructors(),
        _repository.getStudents(),
        _curriculumRepository.getLevels(),
      ]);
      _instructors = results[0] as List<UserModel>;
      _students = results[1] as List<UserModel>;
      _levels = results[2] as List<LevelModel>;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── State ──────────────────────────────
  String _search = '';

  // ── Getters ────────────────────────────
  String get search => _search;

  List<UserModel> get instructors {
    if (_search.isEmpty) return _instructors;
    return _instructors.where((i) =>
      i.name.toLowerCase().contains(_search.toLowerCase()) ||
      (i.email ?? '').toLowerCase().contains(_search.toLowerCase())
    ).toList();
  }

  List<UserModel> get students {
    if (_search.isEmpty) return _students;
    final q = _search.toLowerCase();
    return _students.where((s) =>
      s.name.toLowerCase().contains(q) ||
      (s.username ?? '').toLowerCase().contains(q) ||
      (s.studentNumber ?? '').toLowerCase().contains(q)
    ).toList();
  }

  List<UserModel> get archivedUsers => _archivedUsers;
  List<GroupModel> get archivedGroups => _archivedGroups;

  // ── Actions ────────────────────────────

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  /// Adds an instructor. Optimistic: adds placeholder row instantly, replaces with
  /// real doc once the Cloud Function returns the UID.
  Future<void> addInstructor(String name, String email, String? phoneNumber, List<String> assignedLevels, {
    String? gender,
    DateTime? dateOfBirth,
    String? location,
    String? idNumber,
  }) async {
    if (name.isEmpty) return;

    // Optimistic placeholder
    final placeholder = UserModel(
      id: '__optimistic__${DateTime.now().millisecondsSinceEpoch}',
      userNumber: 0,
      name: name,
      email: email,
      role: UserRole.instructor,
      assignedLevels: assignedLevels,
      lastActive: null,
      gender: gender,
      dateOfBirth: dateOfBirth,
      location: location,
      idNumber: idNumber,
    );
    _instructors = [..._instructors, placeholder];
    notifyListeners();

    try {
      final generatedUsername = _generateUsername(email);
      await _repository.addInstructor(name, email, phoneNumber, assignedLevels, username: generatedUsername, gender: gender, dateOfBirth: dateOfBirth, location: location, idNumber: idNumber);
      final fresh = await _repository.getInstructors();
      _instructors = fresh;
      notifyListeners();
      _audit.log(action: 'Added instructor', category: 'users', details: email, targetPersonName: name);
    } catch (e) {
      _instructors = _instructors.where((i) => i.id != placeholder.id).toList();
      notifyListeners();
      rethrow;
    }
  }

  /// Generates a clean, lowercase, URL-safe username from an email address.
  String _generateUsername(String email) {
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    }
    final suffix = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    return 'instructor_$suffix';
  }

  /// Updates instructor levels. Optimistic: reflects change locally immediately.
  Future<void> updateInstructorLevels(String instructorId, List<String> levels) async {
    final old = _instructors.firstWhere((i) => i.id == instructorId, orElse: () => throw Exception('Not found'));
    _instructors = _instructors.map((i) {
      if (i.id != instructorId) return i;
      return UserModel(
        id: i.id, userNumber: i.userNumber, name: i.name, email: i.email,
        role: i.role, assignedLevels: levels, lastActive: i.lastActive,
        phoneNumber: i.phoneNumber,
      );
    }).toList();
    notifyListeners();

    try {
      await _repository.updateInstructorLevels(instructorId, levels);
      _audit.log(action: 'Updated instructor levels', category: 'users', targetPersonName: old.name, details: levels.join(', '));
    } catch (e) {
      _instructors = _instructors.map((i) => i.id == instructorId ? old : i).toList();
      notifyListeners();
      rethrow;
    }
  }

  /// Updates instructor profile. Optimistic: reflects name/email change locally.
  Future<void> updateInstructorProfile(String instructorId, String name, String email, String? phoneNumber, {
    String? gender,
    DateTime? dateOfBirth,
    String? location,
    String? idNumber,
  }) async {
    final old = _instructors.firstWhere((i) => i.id == instructorId, orElse: () => throw Exception('Not found'));
    _instructors = _instructors.map((i) {
      if (i.id != instructorId) return i;
      return UserModel(
        id: i.id, userNumber: i.userNumber, name: name, email: email,
        role: i.role, assignedLevels: i.assignedLevels, lastActive: i.lastActive,
        phoneNumber: phoneNumber,
        gender: gender, dateOfBirth: dateOfBirth, location: location,
        idNumber: idNumber ?? i.idNumber, // preserve existing idNumber if not explicitly changed
      );
    }).toList();
    notifyListeners();

    try {
      await _repository.updateInstructorProfile(instructorId, name, email, phoneNumber, gender: gender, dateOfBirth: dateOfBirth, location: location, idNumber: idNumber);
      _audit.log(action: 'Updated instructor profile', category: 'users', targetPersonName: name, details: email);
    } catch (e) {
      _instructors = _instructors.map((i) => i.id == instructorId ? old : i).toList();
      notifyListeners();
      rethrow;
    }
  }

  /// Archives instructor. Optimistic: removes from active list instantly.
  Future<void> deleteInstructor(String instructorId) async {
    final removed = _instructors.firstWhere((i) => i.id == instructorId, orElse: () => throw Exception('Not found'));
    _instructors = _instructors.where((i) => i.id != instructorId).toList();
    notifyListeners();

    try {
      await _repository.deleteInstructor(instructorId);
      _archivedUsers = await _repository.getArchivedUsers();
      notifyListeners();
    } catch (e) {
      _instructors = [..._instructors, removed];
      notifyListeners();
      rethrow;
    }
  }

  /// Archives student. Optimistic: removes from active list instantly.
  Future<void> deleteStudent(String studentId) async {
    final removed = _students.firstWhere((s) => s.id == studentId, orElse: () => throw Exception('Not found'));
    _students = _students.where((s) => s.id != studentId).toList();
    notifyListeners();

    try {
      await _repository.deleteStudent(studentId);
      _archivedUsers = await _repository.getArchivedUsers();
      notifyListeners();
    } catch (e) {
      _students = [..._students, removed];
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> emailExists(String email) => _repository.emailExists(email);

  Future<bool> usernameExists(String username) => _repository.usernameExists(username);

  /// Creates a student. Optimistic: appends placeholder immediately,
  /// replaces with real doc after Cloud Function returns.
  Future<UserModel> addStudent({
    required String name,
    required String username,
    required String pinCode,
    required String levelId,
    String? gender,
    DateTime? dateOfBirth,
    String? location,
  }) async {
    final u = username.toLowerCase().trim();

    final placeholder = UserModel(
      id: '__optimistic__${DateTime.now().millisecondsSinceEpoch}',
      userNumber: 0,
      name: name,
      email: '$u@levelup.edu',
      role: UserRole.student,
      studentNumber: '#…',
      username: u,
      pinCode: pinCode,
      lastActive: null,
      gender: gender,
      dateOfBirth: dateOfBirth,
      location: location,
    );
    _students = [..._students, placeholder];
    notifyListeners();

    try {
      final result = await _repository.addStudent(
        name: name,
        username: u,
        pinCode: pinCode,
        levelId: levelId,
        gender: gender,
        dateOfBirth: dateOfBirth,
        location: location,
      );
      final created = UserModel(
        id: result.uid,
        userNumber: result.userNumber,
        name: name,
        email: '${u.replaceAll('_', '').replaceAll('.', '')}@levelup.edu',
        role: UserRole.student,
        studentNumber: '#${result.userNumber}',
        username: u,
        pinCode: pinCode,
        lastActive: null,
        gender: gender,
        dateOfBirth: dateOfBirth,
        location: location,
      );
      _students = _students.map((s) => s.id == placeholder.id ? created : s).toList();
      _audit.log(action: 'Added student', category: 'users', targetPersonName: name, targetStudentNumber: '#${result.userNumber}', details: 'Username: $u | Level: $levelId');
      return created;
    } catch (e) {
      _students = _students.where((s) => s.id != placeholder.id).toList();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Creates multiple students sequentially.
  /// Each map in [students] must have keys: 'name', 'username', 'pin', 'levelId' and optionally: 'gender', 'dateOfBirth', 'location'.
  Future<List<UserModel>> bulkAddStudents(List<Map<String, dynamic>> students) async {
    final created = <UserModel>[];

    // Add optimistic placeholders for all rows at once
    final placeholders = students.map((s) {
      final u = (s['username'] as String).toLowerCase().trim();
      return UserModel(
        id: '__optimistic__${DateTime.now().millisecondsSinceEpoch}_${s['username']}',
        userNumber: 0,
        name: s['name'] as String,
        email: '$u@levelup.edu',
        role: UserRole.student,
        studentNumber: '#…',
        username: u,
        pinCode: s['pin'] as String,
        lastActive: null,
        gender: s['gender'] as String?,
        dateOfBirth: s['dateOfBirth'] as DateTime?,
        location: s['location'] as String?,
      );
    }).toList();

    _students = [..._students, ...placeholders];
    notifyListeners();

    try {
      for (int i = 0; i < students.length; i++) {
        final s = students[i];
        final u = (s['username'] as String).toLowerCase().trim();
        final result = await _repository.addStudent(
          name: s['name'] as String,
          username: u,
          pinCode: s['pin'] as String,
          levelId: s['levelId'] as String,
          gender: s['gender'] as String?,
          dateOfBirth: s['dateOfBirth'] as DateTime?,
          location: s['location'] as String?,
        );
        final model = UserModel(
          id: result.uid,
          userNumber: result.userNumber,
          name: s['name'] as String,
          email: '${u.replaceAll('_', '').replaceAll('.', '')}@levelup.edu',
          role: UserRole.student,
          studentNumber: '#${result.userNumber}',
          username: u,
          pinCode: s['pin'] as String,
          lastActive: null,
          gender: s['gender'] as String?,
          dateOfBirth: s['dateOfBirth'] as DateTime?,
          location: s['location'] as String?,
        );
        created.add(model);
        // Replace this placeholder with the real model
        _students = _students.map((st) => st.id == placeholders[i].id ? model : st).toList();
        
        // Write audit log for the added student
        _audit.log(
          action: 'Added student',
          category: 'users',
          targetPersonName: s['name'] as String,
          targetStudentNumber: '#${result.userNumber}',
          details: 'Username: $u | Level: ${s['levelId'] as String}',
        );
      }
      return created;
    } catch (e) {
      // Roll back all remaining placeholders
      final placeholderIds = placeholders.map((p) => p.id).toSet();
      _students = _students.where((s) => !placeholderIds.contains(s.id)).toList();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Resets student PIN. Optimistic: updates pinCode in local list immediately.
  Future<String> resetStudentPin(String studentId) async {
    final newPin = (100000 + Random().nextInt(900000)).toString();
    final old = _students.firstWhere((s) => s.id == studentId, orElse: () => throw Exception('Not found'));

    _students = _students.map((s) {
      if (s.id != studentId) return s;
      return s.copyWith(pinCode: newPin);
    }).toList();
    notifyListeners();

    try {
      final callable = _functions.httpsCallable('resetStudentPin');
      await callable.call({'studentId': studentId, 'newPin': newPin});
      _audit.log(action: 'Reset student PIN', category: 'users', targetPersonName: old.name, targetStudentNumber: old.studentNumber);
      return newPin;
    } catch (e) {
      _students = _students.map((s) => s.id == studentId ? old : s).toList();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resendWelcomeEmail(String instructorId) async {
    final callable = _functions.httpsCallable('resendWelcomeEmail');
    await callable.call({'instructorId': instructorId});
  }

  Future<void> getArchivedUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _archivedUsers = await _repository.getArchivedUsers();
      _archivedGroups = await _groupRepository.getArchivedGroups();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restores archived user. Optimistic: removes from archive instantly, adds back to active list.
  Future<void> restoreUser(String uid) async {
    final removed = _archivedUsers.firstWhere((u) => u.id == uid, orElse: () => throw Exception('Not found'));
    _archivedUsers = _archivedUsers.where((u) => u.id != uid).toList();
    if (removed.role == UserRole.instructor) {
      _instructors = [..._instructors, removed];
    } else {
      _students = [..._students, removed];
    }
    notifyListeners();

    try {
      await _repository.restoreUser(uid);
      _audit.log(action: 'Restored user', category: 'users', targetPersonName: removed.name, details: removed.role.name);
    } catch (e) {
      _archivedUsers = [..._archivedUsers, removed];
      if (removed.role == UserRole.instructor) {
        _instructors = _instructors.where((i) => i.id != uid).toList();
      } else {
        _students = _students.where((s) => s.id != uid).toList();
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Permanently deletes archived user. Optimistic: removes from archive instantly.
  Future<void> permanentlyDeleteUser(String uid) async {
    final removed = _archivedUsers.firstWhere((u) => u.id == uid, orElse: () => throw Exception('Not found'));
    _archivedUsers = _archivedUsers.where((u) => u.id != uid).toList();
    notifyListeners();

    try {
      await _repository.permanentlyDeleteUser(uid);
    } catch (e) {
      _archivedUsers = [..._archivedUsers, removed];
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restoreGroup(String groupId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _groupRepository.restoreGroup(groupId);
      _archivedGroups = await _groupRepository.getArchivedGroups();
      _audit.log(action: 'Restored group', category: 'groups', details: groupId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> permanentlyDeleteGroup(String groupId) async {
    final removed = _archivedGroups.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Not found'));
    _archivedGroups = _archivedGroups.where((g) => g.id != groupId).toList();
    notifyListeners();

    try {
      await _groupRepository.permanentlyDeleteGroup(groupId);
      _audit.log(action: 'Permanently deleted group', category: 'groups', targetPersonName: removed.name, details: groupId);
    } catch (e) {
      _archivedGroups = [..._archivedGroups, removed];
      notifyListeners();
      rethrow;
    }
  }
}
