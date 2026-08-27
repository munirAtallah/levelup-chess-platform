/// Data Tier — Repository
/// Path: lib/data/repositories/user_repository.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../../utils/jerusalem_locations.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');



  // ─────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────

  Future<List<Map<String, String>>> getAvailableLevels() async {
    final snap = await _db.collection('curriculum').get();
    final list = snap.docs.map((d) => {
      'id': d.id,
      'name': (d.data()['name'] as String?) ?? d.id,
    }).toList();
    // Sort by name to maintain consistent alphabetical order
    list.sort((a, b) => a['name']!.compareTo(b['name']!));
    return list;
  }

  Future<List<UserModel>> getInstructors() async {
    final snap = await _users
        .where('role', isEqualTo: 'instructor')
        .where('isArchived', isEqualTo: false)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  Future<List<UserModel>> getStudents() async {
    final snap = await _users
        .where('role', isEqualTo: 'student')
        .where('isArchived', isEqualTo: false)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  Future<UserModel?> getStudentById(String id) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<int> getStudentCountByLevel(String levelId) async {
    final snap = await _users
        .where('role', isEqualTo: 'student')
        .where('isArchived', isEqualTo: false)
        .where('levelId', isEqualTo: levelId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<List<UserModel>> getArchivedUsers() async {
    final snap = await _users
        .where('isArchived', isEqualTo: true)
        .get();
    return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  // ─────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────

  Future<List<UserModel>> searchUsers(String query, {String? role}) async {
    final term = query.toLowerCase().trim();
    if (term.isEmpty) return [];
    var q = _users
        .where('searchKeywords', arrayContains: term)
        .where('isArchived', isEqualTo: false);
    if (role != null) q = q.where('role', isEqualTo: role);
    final snap = await q.limit(20).get();
    return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  // ─────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────

  /// Creates an instructor via the createUser Cloud Function.
  /// This atomically creates the Firebase Auth account, writes the Firestore
  /// user doc, and sends a welcome/set-password email via Nodemailer.
  Future<void> addInstructor(
    String name,
    String email,
    String? phoneNumber,
    List<String> assignedLevels, {
    String? username,
    String? gender,
    DateTime? dateOfBirth,
    String? location,
    String? idNumber,
  }) async {
    final userNumber = await _getNextInstructorNumber();
    final callable = _functions.httpsCallable('createUser');
    await callable.call({
      'role': 'instructor',
      'name': name,
      'email': email.trim().toLowerCase(),
      'phoneNumber': phoneNumber,
      'assignedLevels': assignedLevels,
      'userNumber': userNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'location': location,
      'idNumber': idNumber,
    });
  }

  /// Creates a student via the createUser Cloud Function.
  /// This atomically creates both the Firebase Auth account (so the student can log in)
  /// and the Firestore user doc (with isArchived: false set correctly).
  /// Returns the new Firestore / Auth UID.
  Future<({String uid, int userNumber})> addStudent({
    required String name,
    required String username,
    required String pinCode,
    required String levelId,
    String? gender,
    DateTime? dateOfBirth,
    String? location,
  }) async {
    final userNumber = await _getNextStudentNumber();
    final callable = _functions.httpsCallable('createUser');
    final result = await callable.call({
      'role': 'student',
      'name': name,
      'username': username.toLowerCase(),
      'pinCode': pinCode,
      'levelId': levelId,
      'userNumber': userNumber,
      'studentNumber': '#$userNumber',
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'location': location,
    });
    final uid = result.data['uid'] as String;
    return (uid: uid, userNumber: userNumber);
  }

  // ─────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────

  Future<void> updateInstructorProfile(
    String instructorId,
    String name,
    String email,
    String? phoneNumber, {
    String? gender,
    DateTime? dateOfBirth,
    String? location,
    String? idNumber,
  }) async {
    final newEmail = email.trim().toLowerCase();

    // If the email is changing we must update Firebase Auth as well as Firestore,
    // because Auth is the source of truth for login credentials.
    final currentDoc = await _users.doc(instructorId).get();
    final currentData = currentDoc.data() ?? {};
    final currentEmail = (currentData['email'] as String?)?.toLowerCase();
    if (currentEmail != null && currentEmail != newEmail) {
      final callable = _functions.httpsCallable('updateInstructorEmail');
      await callable.call({'instructorId': instructorId, 'newEmail': newEmail});
    }

    // Preserve idNumber from Firestore if the caller didn't explicitly provide one
    // (the edit-profile dialog has no idNumber field).
    final effectiveIdNumber = idNumber ?? (currentData['idNumber'] as String?);

    final extra = <String>['instructor'];
    if (location != null && location.isNotEmpty) {
      extra.add(location.toLowerCase());
      final match = kJerusalemLocations.firstWhere(
        (l) => l.en.toLowerCase() == location.toLowerCase() || l.ar == location,
        orElse: () => JerusalemLocation(en: location, ar: location),
      );
      extra.add(match.en.toLowerCase());
      extra.add(match.ar.toLowerCase());
    }
    if (gender != null && gender.isNotEmpty) extra.add(gender.toLowerCase());
    await _users.doc(instructorId).update({
      'name': name,
      'displayName': name,
      'email': newEmail,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'location': location,
      'idNumber': effectiveIdNumber,
      'searchKeywords': _buildKeywords(name, extra: extra),
    });
  }

  Future<void> updateInstructorLevels(
      String instructorId, List<String> levels) async {
    await _users.doc(instructorId).update({'assignedLevels': levels});
  }

  Future<void> updateStudentLastActive(String studentId) async {
    await _users.doc(studentId).update({
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStudentProfile(
    String studentId, {
    String? pinCode,
    String? levelId,
  }) async {
    final updates = <String, dynamic>{};
    if (levelId != null) updates['levelId'] = levelId;
    if (pinCode != null) updates['pinCode'] = pinCode;
    
    if (updates.isNotEmpty) {
      await _users.doc(studentId).update(updates);
    }
  }

  Future<void> unassignStudentsFromLevel(String levelId) async {
    final snap = await _users
        .where('role', isEqualTo: 'student')
        .where('isArchived', isEqualTo: false)
        .where('levelId', isEqualTo: levelId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'levelId': null});
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────

  /// Archives an instructor by calling the archiveUser Cloud Function.
  /// Sets isArchived: true and disables their Firebase Auth account.
  /// Use permanentlyDeleteUser() to hard-delete from the archive.
  Future<void> deleteInstructor(String instructorId) async {
    final callable = _functions.httpsCallable('archiveUser');
    await callable.call({'uid': instructorId});
  }

  /// Resets a student's PIN via the resetStudentPin Cloud Function.
  /// Updates both the Firebase Auth password and the Firestore pinCode field.
  Future<void> resetStudentPin(String studentId, String newPin) async {
    final callable = _functions.httpsCallable('resetStudentPin');
    await callable.call({'studentId': studentId, 'newPin': newPin});
  }

  /// Archives a student by calling the archiveUser Cloud Function.
  /// Sets isArchived: true and disables their Firebase Auth account.
  /// Use permanentlyDeleteUser() to hard-delete from the archive.
  Future<void> deleteStudent(String studentId) async {
    final callable = _functions.httpsCallable('archiveUser');
    await callable.call({'uid': studentId});
  }

  /// Permanently deletes a user from Firebase Auth + Firestore.
  /// This is the ONLY path to a true hard delete — must be called from the archive.
  Future<void> permanentlyDeleteUser(String uid) async {
    final callable = _functions.httpsCallable('deleteUserPermanently');
    await callable.call({'uid': uid});
  }

  Future<void> restoreUser(String uid) async {
    final callable = _functions.httpsCallable('restoreUser');
    await callable.call({'uid': uid});
  }

  Future<bool> emailExists(String email) async {
    final snap = await _db.collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> usernameExists(String username) async {
    final snap = await _users
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────



  Future<int> _getNextStudentNumber() async {
    final docRef = _db.collection('counters').doc('students');
    int next = 1001;
    await _db.runTransaction((t) async {
      final snap = await t.get(docRef);
      final last = snap.exists ? (snap.data()?['lastNumber'] as int? ?? 1000) : 1000;
      next = last + 1;
      t.set(docRef, {'lastNumber': next}, SetOptions(merge: true));
    });
    return next;
  }

  Future<int> _getNextInstructorNumber() async {
    final docRef = _db.collection('counters').doc('instructors');
    int next = 101;
    await _db.runTransaction((t) async {
      final snap = await t.get(docRef);
      final last = snap.exists ? (snap.data()?['lastNumber'] as int? ?? 100) : 100;
      next = last + 1;
      t.set(docRef, {'lastNumber': next}, SetOptions(merge: true));
    });
    return next;
  }

  List<String> _buildKeywords(String name, {List<String> extra = const []}) {
    final keywords = <String>{};
    for (final part in name.toLowerCase().trim().split(RegExp(r'\s+'))) {
      for (int i = 1; i <= part.length; i++) {
        keywords.add(part.substring(0, i));
      }
    }
    keywords.addAll(extra);
    return keywords.toList();
  }
}
