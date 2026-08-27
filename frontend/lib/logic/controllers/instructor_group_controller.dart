/// Logic Tier — Controller
/// Path: lib/logic/controllers/instructor_group_controller.dart
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/user_repository.dart';

class InstructorGroupController extends ChangeNotifier {
  final GroupRepository _groupRepository;
  final UserRepository _userRepository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<GroupModel> _groups = [];
  List<UserModel> _allStudents = [];
  List<String> _instructorAssignedLevelIds = [];

  List<String> get instructorAssignedLevelIds => _instructorAssignedLevelIds;

  InstructorGroupController(this._groupRepository, this._userRepository) {
    _init();
  }

  String? _error;
  String? get error => _error;

  Future<void> _init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      UserModel? currentUser;
      if (uid != null) {
        currentUser = await _userRepository.getStudentById(uid);
      }
      final assignedLevels = currentUser?.assignedLevels ?? [];
      _instructorAssignedLevelIds = assignedLevels;

      _groups = await _groupRepository.getGroups();
      final rawStudents = await _userRepository.getStudents();
      _allStudents = rawStudents.where((s) => assignedLevels.contains(s.levelId)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('InstructorGroupController._init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── State ──────────────────────────────
  String _search = '';

  // ── Getters ────────────────────────────
  String get search => _search;

  List<GroupModel> get myGroups {
    if (_search.isEmpty) return _groups;
    final term = _search.toLowerCase();
    return _groups.where((g) => g.name.toLowerCase().contains(term)).toList();
  }

  List<UserModel> get allStudents => _allStudents;

  // ── Actions ────────────────────────────

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  /// Creates a group. Optimistic: adds to list immediately, syncs in background.
  Future<void> addGroup(String name, List<String> levelIds) async {
    final placeholder = GroupModel(
      id: '__optimistic__${DateTime.now().millisecondsSinceEpoch}',
      serialNumber: _groups.isEmpty ? 1 : _groups.last.serialNumber + 1,
      name: name,
      instructorIds: [],
      students: [],
      createdAt: DateTime.now(),
      isArchived: false,
      levelIds: levelIds,
    );
    _groups = [..._groups, placeholder];
    notifyListeners();

    try {
      final created = await _groupRepository.createGroup(name, levelIds);
      _groups = _groups.where((g) => g.id != placeholder.id).toList()
        ..add(created);
      _groups.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    } catch (e) {
      _groups = _groups.where((g) => g.id != placeholder.id).toList();
      notifyListeners();
      rethrow;
    }
  }

  /// Soft-deletes a group. Optimistic: removes from list immediately.
  Future<void> deleteGroup(String id) async {
    final removed = _groups.firstWhere((g) => g.id == id, orElse: () => throw Exception('Group not found'));
    _groups = _groups.where((g) => g.id != id).toList();
    notifyListeners();

    try {
      await _groupRepository.deleteGroup(id);
    } catch (e) {
      _groups = [..._groups, removed]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
      rethrow;
    }
  }

  /// Renames a group. Optimistic: updates name locally right away.
  Future<void> updateGroup(String id, String newName) async {
    final old = _groups.firstWhere((g) => g.id == id, orElse: () => throw Exception('Group not found'));
    _groups = _groups.map((g) {
      if (g.id != id) return g;
      return GroupModel(
        id: g.id,
        serialNumber: g.serialNumber,
        name: newName,
        instructorIds: g.instructorIds,
        students: g.students,
        sharedMaterialIds: g.sharedMaterialIds,
        createdAt: g.createdAt,
        isArchived: g.isArchived,
        archivedAt: g.archivedAt,
      );
    }).toList();
    notifyListeners();

    try {
      await _groupRepository.updateGroup(id, newName);
    } catch (e) {
      _groups = _groups.map((g) => g.id == id ? old : g).toList();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      UserModel? currentUser;
      if (uid != null) {
        currentUser = await _userRepository.getStudentById(uid);
      }
      final assignedLevels = currentUser?.assignedLevels ?? [];
      _instructorAssignedLevelIds = assignedLevels;

      _groups = await _groupRepository.getGroups();
      final rawStudents = await _userRepository.getStudents();
      _allStudents = rawStudents.where((s) => assignedLevels.contains(s.levelId)).toList();
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('InstructorGroupController.refresh error: $e');
    }
  }
}
