// Dependency Injection — Service Locator
/// Path: lib/di/service_locator.dart
library;

import 'package:get_it/get_it.dart';

// Repositories
import '../data/repositories/auth_repository.dart';
import '../data/repositories/curriculum_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/group_repository.dart';
import '../data/repositories/assignment_repository.dart';
import '../data/repositories/audit_log_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/student_profile_repository.dart';
import '../data/repositories/submission_repository.dart';
import '../data/repositories/material_assignment_repository.dart';
import '../data/repositories/instructor_material_repository.dart';

// Helpers
import '../logic/helpers/audit_log_helper.dart';

// Controllers — Auth
import '../logic/controllers/auth_controller.dart';

// Controllers — Admin
import '../logic/controllers/admin_dashboard_controller.dart';
import '../logic/controllers/admin_statistics_controller.dart';
import '../logic/controllers/curriculum_controller.dart';
import '../logic/controllers/user_controller.dart';
import '../logic/controllers/group_controller.dart';
import '../logic/controllers/audit_log_controller.dart';
import '../logic/controllers/admin_assignments_controller.dart';

// Controllers — Instructor
import '../logic/controllers/instructor_dashboard_controller.dart';
import '../logic/controllers/instructor_assignment_controller.dart';
import '../logic/controllers/instructor_group_controller.dart';
import '../logic/controllers/instructor_log_controller.dart';
import '../logic/controllers/instructor_material_controller.dart';

// Controllers — Student
import '../logic/controllers/student_dashboard_controller.dart';
import '../logic/controllers/student_assignment_controller.dart';
import '../logic/controllers/student_notification_controller.dart';
import '../logic/controllers/student_profile_controller.dart';

// Controllers — Details
import '../logic/controllers/assignment_detail_controller.dart';
import '../logic/controllers/group_detail_controller.dart';
import '../logic/controllers/lesson_detail_controller.dart';
import '../logic/controllers/student_detail_controller.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // ──────────────────────────────────────
  // Data Tier — Repositories (lazy singletons)
  // ──────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<CurriculumRepository>(() => CurriculumRepository());
  getIt.registerLazySingleton<UserRepository>(() => UserRepository());
  getIt.registerLazySingleton<GroupRepository>(() => GroupRepository());
  getIt.registerLazySingleton<AssignmentRepository>(() => AssignmentRepository());
  getIt.registerLazySingleton<AuditLogRepository>(() => AuditLogRepository());
  getIt.registerLazySingleton<NotificationRepository>(() => NotificationRepository());
  getIt.registerLazySingleton<StudentProfileRepository>(() => StudentProfileRepository());
  getIt.registerLazySingleton<SubmissionRepository>(() => SubmissionRepository());
  getIt.registerLazySingleton<MaterialAssignmentRepository>(() => MaterialAssignmentRepository());
  getIt.registerLazySingleton<AuditLogHelper>(() => AuditLogHelper(getIt<AuditLogRepository>()));
  getIt.registerLazySingleton<InstructorMaterialRepository>(() => InstructorMaterialRepository());

  // ──────────────────────────────────────
  // Logic Tier — Controllers: Auth
  // ──────────────────────────────────────
  getIt.registerLazySingleton<AuthController>(
    () => AuthController(getIt<AuthRepository>()),
  );

  // ──────────────────────────────────────
  // Logic Tier — Controllers: Admin
  // ──────────────────────────────────────
  getIt.registerLazySingleton<AdminDashboardController>(
    () => AdminDashboardController(
      getIt<AuditLogRepository>(),
      getIt<UserRepository>(),
      getIt<GroupRepository>(),
      getIt<CurriculumRepository>(),
    ),
  );
  getIt.registerLazySingleton<AdminStatisticsController>(
    () => AdminStatisticsController(getIt<UserRepository>(), getIt<CurriculumRepository>()),
  );
  getIt.registerLazySingleton<CurriculumController>(
    () => CurriculumController(getIt<CurriculumRepository>(), getIt<AssignmentRepository>(), getIt<UserRepository>(), getIt<AuditLogHelper>()),
  );
  getIt.registerLazySingleton<UserController>(
    () => UserController(getIt<UserRepository>(), getIt<GroupRepository>(), getIt<CurriculumRepository>(), getIt<AuditLogHelper>()),
  );
  getIt.registerLazySingleton<GroupController>(
    () => GroupController(getIt<GroupRepository>(), getIt<UserRepository>(), getIt<AuditLogHelper>()),
  );
  getIt.registerLazySingleton<AuditLogController>(
    () => AuditLogController(getIt<AuditLogRepository>()),
  );
  getIt.registerLazySingleton<AdminAssignmentsController>(
    () => AdminAssignmentsController(),
  );

  // ──────────────────────────────────────
  // Logic Tier — Controllers: Instructor
  // ──────────────────────────────────────
  getIt.registerLazySingleton<InstructorDashboardController>(
    () => InstructorDashboardController(getIt<AssignmentRepository>(), getIt<GroupRepository>(), getIt<UserRepository>()),
  );
  getIt.registerLazySingleton<InstructorAssignmentController>(
    () => InstructorAssignmentController(getIt<AssignmentRepository>(), getIt<AuditLogHelper>()),
  );
  getIt.registerLazySingleton<InstructorGroupController>(
    () => InstructorGroupController(getIt<GroupRepository>(), getIt<UserRepository>()),
  );
  getIt.registerLazySingleton<InstructorLogController>(
    () => InstructorLogController(getIt<AuditLogRepository>()),
  );
  getIt.registerLazySingleton<InstructorMaterialController>(
    () => InstructorMaterialController(getIt<InstructorMaterialRepository>()),
  );

  // ──────────────────────────────────────
  // Logic Tier — Controllers: Student
  // ──────────────────────────────────────
  getIt.registerLazySingleton<StudentDashboardController>(
    () => StudentDashboardController(),
  );
  getIt.registerLazySingleton<StudentAssignmentController>(
    () => StudentAssignmentController(),
  );
  getIt.registerLazySingleton<StudentNotificationController>(
    () => StudentNotificationController(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton<StudentProfileController>(
    () => StudentProfileController(getIt<StudentProfileRepository>()),
  );

  // ──────────────────────────────────────
  // Logic Tier — Controllers: Details (Factories)
  // ──────────────────────────────────────
  getIt.registerFactoryParam<AssignmentDetailController, String, void>(
    (id, _) => AssignmentDetailController(
      id,
      getIt<AssignmentRepository>(),
      getIt<AuthController>(),
      getIt<SubmissionRepository>(),
      getIt<UserRepository>(),
      getIt<CurriculumRepository>(),
      getIt<AuditLogHelper>(),
    ),
  );
  getIt.registerFactoryParam<GroupDetailController, String, void>(
    (id, _) => GroupDetailController(id, getIt<GroupRepository>(), getIt<UserRepository>(), getIt<CurriculumRepository>(), getIt<AuditLogHelper>()),
  );
  getIt.registerFactoryParam<LessonDetailController, String, void>(
    (id, _) => LessonDetailController(id, getIt<CurriculumRepository>()),
  );
  getIt.registerFactoryParam<StudentDetailController, String, void>(
    (id, _) => StudentDetailController(id, getIt<StudentProfileRepository>()),
  );
}
