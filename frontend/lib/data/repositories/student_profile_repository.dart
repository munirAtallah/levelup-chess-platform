/// Data Tier — Repository
/// Path: lib/data/repositories/student_profile_repository.dart
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_profile_model.dart';
import '../../utils/level_helpers.dart';

class StudentProfileRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the profile of the CURRENTLY LOGGED-IN student.
  /// Uses Firebase Auth to know who's signed in, then reads their user doc.
  Future<StudentProfile> getProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user is currently signed in.');
    }
    final profile = await getProfileById(uid);
    if (profile == null) {
      throw Exception('Profile not found for current user.');
    }
    return profile;
  }

  /// Reads a student's profile by their user document ID (== Auth UID).
  Future<StudentProfile?> getProfileById(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;

    // ── Resolve group name + instructor names from the groups collection ──
    String groupName = '—';
    String instructorNames = '—';

    final groupId = data['groupId'] as String?;
    if (groupId != null) {
      final groupDoc = await _db.collection('groups').doc(groupId).get();
      if (groupDoc.exists && groupDoc.data() != null) {
        final groupData = groupDoc.data()!;
        groupName = groupData['name'] as String? ?? '—';

        final instructorIds =
            List<String>.from(groupData['instructorIds'] as List? ?? []);

        if (instructorIds.isNotEmpty) {
          // Fetch all instructor docs in parallel
          final instructorDocs = await Future.wait(
            instructorIds.map((iid) => _db.collection('users').doc(iid).get()),
          );
          final names = instructorDocs
              .where((d) => d.exists && d.data() != null)
              .map((d) => (d.data()!['name'] as String?) ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
          if (names.isNotEmpty) instructorNames = names.join(', ');
        }
      }
    }

    final submissionsSnap = await _db
        .collection('submissions')
        .where('studentId', isEqualTo: id)
        .get();
    final submissionsList = submissionsSnap.docs;
    final submissionsCount = submissionsList.length;
    final gradedCount = submissionsList.where((s) => s.data()['status'] != 'pending').length;
    final correctCount = submissionsList.where((s) => s.data()['status'] == 'correct').length;

    return StudentProfile(
      id: doc.id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      studentId: data['studentNumber'] ?? '',
      level: levelDisplayName(data['levelId'] as String?),
      group: groupName,
      instructorName: instructorNames,
      submissions: submissionsCount,
      graded: gradedCount,
      correct: correctCount,
      studentNumber: data['studentNumber'],
      pinCode: data['pinCode'],
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] is Timestamp
              ? (data['lastActive'] as Timestamp).toDate()
              : DateTime.tryParse(data['lastActive'].toString()))
          : null,
      groupId: groupId,
      levelId: data['levelId'] as String?,
    );
  }
}