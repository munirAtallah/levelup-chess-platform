/// Data Tier — Repository
/// Path: lib/data/repositories/audit_log_repository.dart
///
/// Real Firestore implementation — replaces all hardcoded mock data.
/// Every write uses serverTimestamp so ordering is consistent.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audit_log_model.dart';

class AuditLogRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('audit_logs');

  // ─────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────

  /// Returns all logs ordered by time descending (newest first), limited to 500.
  Future<List<AuditLog>> getAllLogs() async {
    final snap = await _col
        .orderBy('time', descending: true)
        .limit(500)
        .get();
    return snap.docs
        .map((d) => AuditLog.fromMap(d.data(), d.id))
        .toList();
  }

  /// Returns the most recent N logs.
  Future<List<AuditLog>> getRecentLogs({int count = 5}) async {
    final snap = await _col
        .orderBy('time', descending: true)
        .limit(count)
        .get();
    return snap.docs
        .map((d) => AuditLog.fromMap(d.data(), d.id))
        .toList();
  }

  /// Returns logs performed by the currently signed-in user (instructor view).
  Future<List<AuditLog>> getInstructorLogs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final snap = await _col
        .where('performedBy', isEqualTo: uid)
        .orderBy('time', descending: true)
        .limit(200)
        .get();
    return snap.docs
        .map((d) => AuditLog.fromMap(d.data(), d.id))
        .toList();
  }

  // ─────────────────────────────────────────────
  // WRITE
  // ─────────────────────────────────────────────

  /// Writes a single audit log entry to Firestore.
  /// Uses serverTimestamp for the canonical 'time' field so ordering is reliable.
  Future<void> addLog(AuditLog log) async {
    final data = log.toMap();
    // Override with server timestamp for consistent ordering
    data['time'] = FieldValue.serverTimestamp();
    data['preciseTimestamp'] = FieldValue.serverTimestamp();
    await _col.add(data);
  }
}
