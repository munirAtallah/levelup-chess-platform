/// Logic Tier — Controller
/// Path: lib/logic/controllers/instructor_log_controller.dart
library;

import 'package:flutter/foundation.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/repositories/audit_log_repository.dart';
import 'time_filter_mixin.dart';

class InstructorLogController extends ChangeNotifier with TimeFilterMixin {
  final AuditLogRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AuditLog> _allLogs = [];

  InstructorLogController(this._repository) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    _allLogs = await _repository.getInstructorLogs();
    _isLoading = false;
    notifyListeners();
  }

  // ── State ──────────────────────────────
  String _search = '';

  // ── Getters ────────────────────────────
  String get search => _search;

  /// Filtered instructor-scoped logs.
  List<AuditLog> get filteredLogs {
    return _allLogs.where((log) {
      if (!matchesTimeFilter(log)) return false;
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return log.action.toLowerCase().contains(q) ||
          log.performerName.toLowerCase().contains(q) ||
          (log.details ?? '').toLowerCase().contains(q) ||
          (log.targetPersonName ?? '').toLowerCase().contains(q) ||
          (log.targetStudentNumber ?? '').toLowerCase().contains(q);
    }).toList();
  }

  // ── Actions ────────────────────────────

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }
}
