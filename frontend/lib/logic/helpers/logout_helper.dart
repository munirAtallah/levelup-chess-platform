/// Logic Tier — Helper
/// Path: lib/logic/helpers/logout_helper.dart
///
/// Centralized logout that cancels all active Firestore stream subscriptions
/// BEFORE signing out, preventing `permission-denied` errors from lingering
/// listeners that fire after the auth state becomes null.
library;

import 'package:firebase_auth/firebase_auth.dart';
import '../../di/service_locator.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../controllers/instructor_dashboard_controller.dart';
import '../controllers/instructor_assignment_controller.dart';
import '../controllers/student_dashboard_controller.dart';
import '../controllers/student_assignment_controller.dart';
import '../controllers/student_notification_controller.dart';
import '../controllers/student_profile_controller.dart';
import '../controllers/auth_controller.dart';

/// Cancel all active Firestore streams on singleton controllers, reset auth
/// state, then sign out from Firebase. This prevents the race condition where
/// Firestore listeners try to read data after the user is no longer
/// authenticated.
Future<void> performLogout() async {
  // 1. Cancel all Firestore stream subscriptions on singleton controllers.
  //    Use try-catch for each so that an uninitialized (never-accessed) lazy
  //    singleton doesn't break the entire logout flow.
  if (getIt.checkLazySingletonInstanceExists<AdminDashboardController>()) {
    try { getIt<AdminDashboardController>().cancelSubscriptions(); } catch (_) {}
  }
  if (getIt.checkLazySingletonInstanceExists<InstructorDashboardController>()) {
    try { getIt<InstructorDashboardController>().cancelSubscriptions(); } catch (_) {}
  }
  if (getIt.checkLazySingletonInstanceExists<InstructorAssignmentController>()) {
    try { getIt<InstructorAssignmentController>().cancelSubscriptions(); } catch (_) {}
  }
  if (getIt.checkLazySingletonInstanceExists<StudentDashboardController>()) {
    try { getIt<StudentDashboardController>().cancelSubscriptions(); } catch (_) {}
  }
  if (getIt.checkLazySingletonInstanceExists<StudentAssignmentController>()) {
    try { getIt<StudentAssignmentController>().cancelSubscriptions(); } catch (_) {}
  }
  if (getIt.checkLazySingletonInstanceExists<StudentNotificationController>()) {
    try { getIt<StudentNotificationController>().cancelSubscriptions(); } catch (_) {}
  }
  if (getIt.checkLazySingletonInstanceExists<StudentProfileController>()) {
    try { getIt<StudentProfileController>().cancelSubscriptions(); } catch (_) {}
  }

  // 2. Reset all lazy singletons in GetIt. This completely discards the cached
  //    instances and states of all controllers and repositories, ensuring that
  //    when a new user signs in, fresh instances are created with the new credentials.
  try {
    await getIt.resetLazySingletons();
  } catch (_) {}

  // 3. Now sign out — no listeners will fire permission-denied reads
  await FirebaseAuth.instance.signOut();
}
