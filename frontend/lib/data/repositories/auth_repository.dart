/// Data Tier — Repository
/// Path: lib/data/repositories/auth_repository.dart
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _studentEmailDomain = '@students.levelup-26.local';

  String _studentEmailFor(String username) =>
      '${username.trim().toLowerCase()}$_studentEmailDomain';

  Future<String?> authenticateStaff(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) return null;

      final role = await _roleForUid(uid);

      if (role == 'admin' || role == 'instructor') {
        // Update lastActive on login
        _db.collection('users').doc(uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        }).catchError((_) {});
        return role;
      }
      await _auth.signOut();
      return null;
    } on FirebaseAuthException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> authenticateStudent(String username, String pin) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _studentEmailFor(username),
        password: pin,
      );
      final uid = cred.user?.uid;
      if (uid == null) return null;

      final role = await _roleForUid(uid);

      if (role == 'student') {
        // Update lastActive on login
        _db.collection('users').doc(uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        }).catchError((_) {});
        return 'student';
      }
      await _auth.signOut();
      return null;
    } on FirebaseAuthException {
      return null;
    }
  }
  /// Returns true if the email belongs to an admin/instructor in our system
  /// and a reset link was sent. Returns false otherwise.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      final searchEmail = email.trim().toLowerCase();
      if (searchEmail.isEmpty) return false;

      // Verify the email belongs to an admin/instructor in our Firestore users collection.
      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('checkEmailInSystem')
          .call({'email': searchEmail});
      if (result.data['found'] != true) return false;

      await _auth.sendPasswordResetEmail(email: searchEmail);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('sendPasswordResetEmail FirebaseAuthException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('sendPasswordResetEmail error: $e');
      return false;
    }
  }
  Future<void> signOut() => _auth.signOut();

  /// Returns the `assignedLevels` list for the currently signed-in user.
  Future<List<String>> getCurrentAssignedLevels() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return [];
    return List<String>.from(doc.data()?['assignedLevels'] ?? []);
  }

  Future<String?> _roleForUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['role'] as String?;
  }
}