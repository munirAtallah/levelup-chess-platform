/// Logic Tier — Controller
/// Path: lib/logic/controllers/auth_controller.dart
library;

import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  AuthController(this._repository);

  // ── State ──────────────────────────────
  String _mode = 'student'; // 'staff' or 'student'
  bool _isLoading = false;
  String _error = '';
  String? _authenticatedRole;

  // ── Getters ────────────────────────────
  String get mode => _mode;
  bool get isLoading => _isLoading;
  String get error => _error;
  String? get authenticatedRole => _authenticatedRole;

  // ── Actions ────────────────────────────

  void switchMode(String mode) {
    _mode = mode;
    _error = '';
    _authenticatedRole = null;
    notifyListeners();
  }

  /// Sends a password reset email. Returns true if sent, false if not found.
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final sent = await _repository.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return sent; // true = email found & sent, false = email not found
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to send password reset email. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Attempts login and returns the route to navigate to, or null on failure.
  ///
  /// Two completely separate authentication paths exist depending on [_mode]:
  /// - 'staff': email + password via [AuthRepository.authenticateStaff] (admin & instructor)
  /// - 'student': username + PIN via [AuthRepository.authenticateStudent]
  ///
  /// On success the resolved role string ('admin' | 'instructor' | 'student') is
  /// stored in [_authenticatedRole] so callers can read it after navigation.
  Future<String?> login({
    required String email,
    required String password,
    required String username,
    required String pin,
  }) async {
    _error = '';
    _isLoading = true;
    notifyListeners();

    // Delegate to the correct authentication path; unused params are silently ignored
    String? role;
    if (_mode == 'staff') {
      role = await _repository.authenticateStaff(email, password);
    } else {
      role = await _repository.authenticateStudent(username, pin);
    }

    _isLoading = false;

    if (role == null) {
      _error = 'Invalid credentials. Please try again.';
      notifyListeners();
      return null;
    }

    _authenticatedRole = role;
    notifyListeners();

    // Map the role string to a named route; unknown roles return null so the
    // login screen stays visible and displays the error state.
    switch (role) {
      case 'admin':
        return '/admin';
      case 'instructor':
        return '/instructor';
      case 'student':
        return '/student';
      default:
        return null;
    }
  }

  Future<List<String>> getCurrentAssignedLevels() =>
      _repository.getCurrentAssignedLevels();

  /// Resets the controller state (e.g., on logout).
  void reset() {
    _mode = 'student';
    _isLoading = false;
    _error = '';
    _authenticatedRole = null;
    notifyListeners();
  }
}
