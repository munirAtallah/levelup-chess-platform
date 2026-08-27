/// Logic Tier — Helper
/// Path: lib/logic/helpers/audit_log_helper.dart
///
/// Centralised factory that builds AuditLog entries from the current user's
/// identity. All controllers import this instead of constructing AuditLog
/// objects by hand, ensuring every log is consistent.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/repositories/audit_log_repository.dart';

class AuditLogHelper {
  final AuditLogRepository _repo;

  /// The current actor's cached profile (fetched once on construction).
  String _performerName = 'Unknown';
  String _performerRole = 'admin';
  String _performerNumber = '0';
  bool _identityResolved = false;

  AuditLogHelper(this._repo);

  // ─────────────────────────────────────────────
  // Identity
  // ─────────────────────────────────────────────

  /// Resolves and caches the current user's display info from Firestore.
  /// Safe to call multiple times — re-fetches every time so it stays fresh.
  Future<void> resolveIdentity() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('[AuditLog] resolveIdentity: currentUser is null — skipping');
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) {
        debugPrint('[AuditLog] resolveIdentity: user doc not found for $uid');
        return;
      }
      final data = doc.data()!;
      // User docs can store name under 'displayName' or 'name'
      _performerName = (data['displayName'] as String?)?.isNotEmpty == true
          ? data['displayName']
          : (data['name'] as String?)?.isNotEmpty == true
              ? data['name']
              : 'Unknown';
      _performerRole = data['role'] as String? ?? 'admin';
      _performerNumber = data['userNumber']?.toString() ?? '0';
      _identityResolved = true;
      debugPrint('[AuditLog] Identity resolved: $_performerName ($_performerRole)');
    } catch (e) {
      debugPrint('[AuditLog] resolveIdentity error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Log factory + write
  // ─────────────────────────────────────────────

  /// Creates and persists a log entry.
  /// If identity hasn't been resolved yet, resolves it first.
  Future<void> log({
    required String action,
    required String category,
    String? details,
    String? targetPersonName,
    String? targetStudentNumber,
  }) async {
    // Lazily resolve identity if not done yet
    if (!_identityResolved) {
      await resolveIdentity();
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('[AuditLog] Cannot write log — no authenticated user');
      return;
    }

    final now = DateTime.now();
    final entry = AuditLog(
      id: '',
      action: action,
      details: details,
      performerName: _performerName,
      performerRole: _performerRole,
      performedBy: uid,
      time: now,
      preciseTimestamp: now,
      serialNumber: _performerNumber,
      targetPersonName: targetPersonName,
      targetStudentNumber: targetStudentNumber,
      actionCategory: category,
    );

    debugPrint('[AuditLog] Writing: "$action" by $_performerName ($uid)');

    try {
      await _repo.addLog(entry);
      debugPrint('[AuditLog] ✅ Written successfully');
    } catch (e) {
      // Log the error visibly in debug mode — never crash the app
      debugPrint('[AuditLog] ❌ Write failed: $e');
    }
  }
}
