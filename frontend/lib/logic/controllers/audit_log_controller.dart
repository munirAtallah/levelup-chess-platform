/// Logic Tier — Controller
/// Path: lib/logic/controllers/audit_log_controller.dart
library;

import 'package:flutter/foundation.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/repositories/audit_log_repository.dart';
import 'time_filter_mixin.dart';

class AuditLogController extends ChangeNotifier with TimeFilterMixin {
  final AuditLogRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AuditLog> _allLogs = [];

  AuditLogController(this._repository) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    _allLogs = await _repository.getAllLogs();
    _isLoading = false;
    notifyListeners();
  }

  /// Reload logs from Firestore — called to refresh the list.
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    _allLogs = await _repository.getAllLogs();
    _isLoading = false;
    notifyListeners();
  }

  // ── State ──────────────────────────────
  String _search = '';
  String _roleFilter = 'all';
  String _categoryFilter = 'all';

  // ── Getters ────────────────────────────
  String get search => _search;
  String get roleFilter => _roleFilter;
  String get categoryFilter => _categoryFilter;

  /// Role filter options for the UI chips.
  List<Map<String, String>> get roleFilters => const [
        {'label': 'All Roles', 'value': 'all'},
        {'label': 'Admin', 'value': 'admin'},
        {'label': 'Instructor', 'value': 'instructor'},
        {'label': 'Student', 'value': 'student'},
      ];

  /// Category filter options for the UI chips.
  List<Map<String, String>> get categoryFilters => const [
        {'label': 'All', 'value': 'all'},
        {'label': 'Users', 'value': 'users'},
        {'label': 'Groups', 'value': 'groups'},
        {'label': 'Curriculum', 'value': 'curriculum'},
        {'label': 'Assignments', 'value': 'assignments'},
        {'label': 'Grading', 'value': 'grading'},
        {'label': 'Submissions', 'value': 'submissions'},
      ];

  /// Filtered logs based on current search, role, time, and category filters.
  /// Search covers: action, performer name, details, and target person name.
  List<AuditLog> get filteredLogs {
    return _allLogs.where((log) {
      // Role filter
      final matchRole = _roleFilter == 'all' || log.performerRole == _roleFilter;

      // Category filter
      final matchCategory = _categoryFilter == 'all' || log.actionCategory == _categoryFilter;

      // Search — covers action, performer, details, and target
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          log.action.toLowerCase().contains(q) ||
          log.performerName.toLowerCase().contains(q) ||
          (log.details?.toLowerCase().contains(q) ?? false) ||
          (log.targetPersonName?.toLowerCase().contains(q) ?? false) ||
          (log.targetStudentNumber?.toLowerCase().contains(q) ?? false);

      return matchRole && matchCategory && matchSearch && matchesTimeFilter(log);
    }).toList();
  }

  // ── Actions ────────────────────────────

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setRoleFilter(String value) {
    _roleFilter = value;
    notifyListeners();
  }

  void setCategoryFilter(String value) {
    _categoryFilter = value;
    notifyListeners();
  }
}
