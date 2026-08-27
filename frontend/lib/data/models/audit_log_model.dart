/// Data Tier — Model
/// Path: lib/data/models/audit_log_model.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

class AuditLog {
  final String id;
  final String action;
  final String? details;

  /// Display name of the actor (UI convenience field).
  final String performerName;

  /// Role of the actor (UI convenience field).
  final String performerRole; // 'admin', 'instructor', 'student'

  /// UID or document reference of the actor (schema canonical field).
  final String performedBy;

  /// Schema canonical timestamp used for Firestore ordering and queries.
  final DateTime time;

  /// High-precision timestamp kept for display purposes.
  final DateTime preciseTimestamp;

  final String serialNumber;

  /// The name of the person the action was performed on (if applicable).
  final String? targetPersonName;

  /// The student number of the target (e.g., "#1005"), if applicable.
  final String? targetStudentNumber;

  /// Broad category for UI filtering.
  /// One of: 'users', 'groups', 'curriculum', 'assignments', 'grading', 'submissions', 'auth'
  final String actionCategory;

  AuditLog({
    required this.id,
    required this.action,
    this.details,
    required this.performerName,
    required this.performerRole,
    required this.performedBy,
    required this.time,
    required this.preciseTimestamp,
    required this.serialNumber,
    this.targetPersonName,
    this.targetStudentNumber,
    this.actionCategory = 'general',
  });

  factory AuditLog.fromMap(Map<String, dynamic> map, String documentId) {
    final parsedTime = _parseDate(map['time']) ??
        _parseDate(map['preciseTimestamp']) ??
        DateTime.now();

    return AuditLog(
      id: documentId,
      action: map['action'] ?? '',
      details: map['details'],
      performerName: map['performerName'] ?? 'System User',
      performerRole: map['performerRole'] ?? 'admin',
      performedBy: map['performedBy'] ?? '',
      time: parsedTime,
      preciseTimestamp: parsedTime,
      serialNumber: map['serialNumber']?.toString() ?? '0',
      targetPersonName: map['targetPersonName'] as String?,
      targetStudentNumber: map['targetStudentNumber'] as String?,
      actionCategory: map['actionCategory'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'details': details,
      'performerName': performerName,
      'performerRole': performerRole,
      'performedBy': performedBy,
      'time': Timestamp.fromDate(time),
      'preciseTimestamp': Timestamp.fromDate(preciseTimestamp),
      'serialNumber': serialNumber,
      if (targetPersonName != null) 'targetPersonName': targetPersonName,
      if (targetStudentNumber != null) 'targetStudentNumber': targetStudentNumber,
      'actionCategory': actionCategory,
    };
  }
}
