import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'di/service_locator.dart';
import 'l10n/app_localizations.dart';
import 'logic/controllers/locale_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/widgets/branded_scaffold.dart';

import 'presentation/screens/layouts/admin_layout.dart';
import 'presentation/screens/layouts/instructor_layout.dart';
import 'presentation/screens/layouts/student_layout.dart';

import 'presentation/screens/details/assignment_detail_screen.dart';
import 'presentation/screens/details/group_detail_screen.dart';
import 'presentation/screens/details/lesson_detail_screen.dart';
import 'presentation/screens/details/student_detail_screen.dart';
import 'presentation/screens/details/student_assignment_detail_screen.dart';
import 'data/models/assignment_model.dart';
import 'data/repositories/assignment_repository.dart';
import 'presentation/screens/instructor/group_report_screen.dart';
import 'presentation/screens/admin/admin_assignments_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  setupServiceLocator();

  final localeProvider = LocaleProvider();
  await localeProvider.load();
  
  runApp(
    ChangeNotifierProvider.value(
      value: localeProvider,
      child: const LevelApp(),
    ),
  );
}

class LevelApp extends StatelessWidget {
  const LevelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp.router(
      title: 'LevelUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: localeProvider.locale,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      builder: (context, child) {
        Widget app = child!;

        // Arabic text +10% scale for visual balance with Cairo font
        if (localeProvider.isArabic) {
          app = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.1),
            ),
            child: app,
          );
        }

        final isDesktopWeb = kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.macOS ||
             defaultTargetPlatform == TargetPlatform.windows ||
             defaultTargetPlatform == TargetPlatform.linux);

        if (!isDesktopWeb) {
          return BrandedBackground(child: app);
        }

        return ListenableBuilder(
          listenable: _router.routerDelegate,
          builder: (context, _) {
            final currentPath = _router.routerDelegate.currentConfiguration.uri.path;
            final isLoginScreen = currentPath == '/login' || currentPath == '/';

            if (!isLoginScreen) {
              return BrandedBackground(child: app);
            }

            const double screenWidth = 390.0;
            const double screenHeight = 844.0;

            return ColoredBox(
              color: const Color(0xFFE5E7EB),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Container(
                      width: screenWidth,
                      height: screenHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 24,
                            spreadRadius: 4,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BrandedBackground(child: app),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── NEW: reads the signed-in user's role from Firestore ──────────────────────
Future<String?> _getRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data()?['role'] as String?;
  } catch (_) {
    return null;
  }
}

// ── NEW: tells the router to re-check when login/logout happens ──────────────
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

// ── Router ───────────────────────────────────────────────────────────────────
final GoRouter _router = GoRouter(
  initialLocation: '/login',
  refreshListenable: _AuthNotifier(), // NEW
  redirect: (context, state) async {  // NEW
    final location = state.uri.toString();
    final user = FirebaseAuth.instance.currentUser;

    // Not signed in → send to login
    if (user == null) {
      if (location == '/login') return null;
      return '/login';
    }

    // Signed in → get role
    final role = await _getRole();

    // Role missing → sign out and go to login
    if (role == null) {
      await FirebaseAuth.instance.signOut();
      return '/login';
    }

    // Already on login → send to correct dashboard
    if (location == '/login') {
      return switch (role) {
        'admin'      => '/admin',
        'instructor' => '/instructor',
        _            => '/student',
      };
    }

    // Wrong role trying to access wrong page → redirect
    final allowed = switch (role) {
      'admin'      => ['/admin', '/assignment', '/group', '/lesson', '/student-detail', '/group-report'],
      'instructor' => ['/instructor', '/assignment', '/group', '/lesson', '/student-detail', '/group-report'],
      _            => ['/student', '/student-assignment', '/lesson'],
    };

    // Matches exact path, sub-paths (/p/...), or same path with query params (/p?...)
    bool isAllowed(String loc, List<String> prefixes) {
      for (final p in prefixes) {
        if (loc == p || loc.startsWith('$p/') || loc.startsWith('$p?')) return true;
      }
      return false;
    }

    if (!isAllowed(location, allowed)) {
      return switch (role) {
        'admin'      => '/admin',
        'instructor' => '/instructor',
        _            => '/student',
      };
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminLayout(),
    ),
    GoRoute(
      path: '/instructor',
      builder: (context, state) => const InstructorLayout(),
    ),
    GoRoute(
      path: '/student',
      builder: (context, state) => const StudentLayout(),
    ),
    GoRoute(
      path: '/assignment/:id',
      builder: (context, state) => AssignmentDetailScreen(id: state.pathParameters['id']!, isAdminView: state.extra == 'admin'),
    ),
    GoRoute(
      path: '/group/:id',
      builder: (context, state) => GroupDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/lesson/:id',
      builder: (context, state) => LessonDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/student-detail/:id',
      builder: (context, state) => StudentDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/student-assignment/:id',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is AssignmentModel) {
          return StudentAssignmentDetailScreen(assignment: extra);
        }
        return _AssignmentLoaderScreen(assignmentId: state.pathParameters['id']!);
      },
    ),
    GoRoute(
      path: '/group-report/:id',
      builder: (context, state) => GroupReportScreen(groupId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/assignments',
      builder: (context, state) => const AdminAssignmentsScreen(),
    ),
    GoRoute(
      path: '/admin/assignment/:id',
      builder: (context, state) => AssignmentDetailScreen(id: state.pathParameters['id']!, isAdminView: true),
    ),
  ],
);

class _AssignmentLoaderScreen extends StatefulWidget {
  final String assignmentId;
  const _AssignmentLoaderScreen({required this.assignmentId});

  @override
  State<_AssignmentLoaderScreen> createState() => _AssignmentLoaderScreenState();
}

class _AssignmentLoaderScreenState extends State<_AssignmentLoaderScreen> {
  late final AssignmentRepository _repo = getIt<AssignmentRepository>();
  bool _isLoading = true;
  AssignmentModel? _assignment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getAssignmentById(widget.assignmentId);
    if (mounted) {
      setState(() {
        _assignment = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_assignment == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notFound)),
        body: Center(child: Text(l10n.assignmentNotFound)),
      );
    }
    return StudentAssignmentDetailScreen(assignment: _assignment!);
  }
}