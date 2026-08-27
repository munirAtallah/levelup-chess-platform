import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential?> loginStaff(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> loginStudent(String username, String pin) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .where('pin', isEqualTo: pin.trim())
          .where('role', isEqualTo: 'student')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      } else {
        return null;
      }
    } catch (_) { 
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}