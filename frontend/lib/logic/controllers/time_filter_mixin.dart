/// Logic Tier — Mixin
/// Path: lib/logic/controllers/time_filter_mixin.dart
library;

import 'package:flutter/material.dart';
import '../../data/models/audit_log_model.dart';

mixin TimeFilterMixin on ChangeNotifier {
  String _timeFilter = 'all';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  TimeOfDay? _customStartTime;
  TimeOfDay? _customEndTime;

  String get timeFilter => _timeFilter;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  TimeOfDay? get customStartTime => _customStartTime;
  TimeOfDay? get customEndTime => _customEndTime;

  List<Map<String, String>> get timeFilters => [
        {'label': 'All Time', 'value': 'all'},
        {'label': 'Today', 'value': 'today'},
        {'label': '7 Days', 'value': '7days'},
        {'label': '30 Days', 'value': '30days'},
        {'label': 'Custom Range...', 'value': 'custom'},
      ];

  void setTimeFilter(String value) {
    _timeFilter = value;
    notifyListeners();
  }

  void setCustomRange({
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    _customStartDate = startDate;
    _customEndDate = endDate;
    _customStartTime = startTime;
    _customEndTime = endTime;
    _timeFilter = 'custom';
    notifyListeners();
  }

  bool matchesTimeFilter(AuditLog log) {
    if (_timeFilter == 'all') return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(
      log.preciseTimestamp.year,
      log.preciseTimestamp.month,
      log.preciseTimestamp.day,
    );
    final diff = today.difference(logDay).inDays;

    switch (_timeFilter) {
      case 'today':
        return logDay == today;
      case '7days':
        return diff <= 7;
      case '30days':
        return diff <= 30;
      case 'custom':
        if (_customStartDate == null ||
            _customEndDate == null ||
            _customStartTime == null ||
            _customEndTime == null) {
          return true;
        }
        final start = DateTime(
          _customStartDate!.year,
          _customStartDate!.month,
          _customStartDate!.day,
          _customStartTime!.hour,
          _customStartTime!.minute,
        );
        final end = DateTime(
          _customEndDate!.year,
          _customEndDate!.month,
          _customEndDate!.day,
          _customEndTime!.hour,
          _customEndTime!.minute,
          59,
          999,
        );
        return !log.preciseTimestamp.isBefore(start) &&
            !log.preciseTimestamp.isAfter(end);
      default:
        return true;
    }
  }
}
