import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/locale_toggle_button.dart';
import '../../widgets/sidebar_nav_item.dart';
import '../../../di/service_locator.dart';
import '../../../logic/helpers/logout_helper.dart';
import '../../../logic/controllers/student_notification_controller.dart';
import '../../../logic/controllers/student_dashboard_controller.dart';
import '../../../logic/controllers/student_assignment_controller.dart';

import '../student/student_dashboard.dart';
import '../student/assignments_screen.dart';
import '../student/notifications_screen.dart';
import '../student/profile_screen.dart';
import '../../widgets/golden_nav_icon.dart';


class StudentLayout extends StatefulWidget {
  const StudentLayout({super.key});

  @override
  State<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends State<StudentLayout> {
  bool _searchOpen = false;
  final TextEditingController _searchTextCtrl = TextEditingController();

  late final List<Widget> _screens = [
    StudentDashboard(
      onNavigateToAssignments:   () => context.go('/student?tab=1'),
      onNavigateToNotifications: () => context.go('/student?tab=2'),
    ),
    const StudentAssignmentsScreen(),
    StudentNotificationsScreen(
      onNavigateToHome: () => context.go('/student?tab=0'),
    ),
    const StudentProfileScreen(),
  ];

  @override
  void dispose() {
    _searchTextCtrl.dispose();
    super.dispose();
  }

  bool _hasSearch(int index) => const {0, 1}.contains(index);

  void _setSearch(String val) {
    final tabParam = GoRouterState.of(context).uri.queryParameters['tab'];
    final currentIndex = (int.tryParse(tabParam ?? '') ?? 0).clamp(0, 3);
    switch (currentIndex) {
      case 0:
        getIt<StudentDashboardController>().setSearch(val);
      case 1:
        getIt<StudentAssignmentController>().setSearch(val);
    }
  }

  void _closeSearch() {
    _searchTextCtrl.clear();
    _setSearch('');
    if (_searchOpen) setState(() => _searchOpen = false);
  }

  void _clearText() {
    _searchTextCtrl.clear();
    _setSearch('');
  }

  void _toggleSearch() {
    setState(() {
      if (_searchOpen) {
        _searchTextCtrl.clear();
        _setSearch('');
      }
      _searchOpen = !_searchOpen;
    });
  }

  void _goToTab(int index) {
    _closeSearch();
    context.go('/student?tab=$index');
  }

  /// Single-letter avatar fallback, e.g. "Ibrahim" -> "I", or "S" if no name
  /// is resolvable from the current Firebase user.
  String _avatarLetter(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'S';
  }

  Widget _buildSidebar(BuildContext context, AppLocalizations l10n, int currentIndex) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final displayName = firebaseUser?.displayName;
    final photoUrl = firebaseUser?.photoURL;
    final avatarLetter = _avatarLetter(displayName);

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: BorderDirectional(end: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 20),
            child: Row(
              children: [
                Image.asset('assets/images/levelup_mark.png', height: 38, width: 38, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'شطرنج القدس',
                        style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'LevelUp',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListenableBuilder(
              listenable: getIt<StudentNotificationController>(),
              builder: (context, _) {
                final unreadCount = getIt<StudentNotificationController>().unreadCount;
                final navItems = <({IconData icon, String label, int tabIndex, Widget? trailing})>[
                  (icon: Icons.home, label: l10n.navHome, tabIndex: 0, trailing: null),
                  (icon: Icons.check_circle, label: l10n.navTasks, tabIndex: 1, trailing: null),
                  (
                    icon: Icons.notifications,
                    label: l10n.navAlerts,
                    tabIndex: 2,
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                            child: Text('$unreadCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.white)),
                          )
                        : null,
                  ),
                  (icon: Icons.person, label: l10n.navProfile, tabIndex: 3, trailing: null),
                ];
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  children: [
                    for (final item in navItems)
                      SidebarNavItem(
                        icon: item.icon,
                        label: item.label,
                        active: item.tabIndex == currentIndex,
                        onTap: () => _goToTab(item.tabIndex),
                        trailing: item.trailing,
                      ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(avatarLetter, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName?.trim().isNotEmpty == true ? displayName!.trim() : l10n.studentRoleLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.studentRoleLabel,
                        style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text(l10n.statusOnline, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton(AppLocalizations l10n) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final avatarLetter = _avatarLetter(firebaseUser?.displayName);
    final photoUrl = firebaseUser?.photoURL;

    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) async {
        if (value == 'logout') {
          await performLogout();
          if (mounted) context.go('/login');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: AppColors.mutedForeground),
              const SizedBox(width: 10),
              Text(l10n.logoutButton),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(avatarLetter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white))
                  : null,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  static const bool _enableResponsiveDesktopLayout = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabParam = GoRouterState.of(context).uri.queryParameters['tab'];
    final currentIndex = (int.tryParse(tabParam ?? '') ?? 0).clamp(0, 3);
    final bool isWide = _enableResponsiveDesktopLayout && MediaQuery.of(context).size.width > 850;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        leading: _hasSearch(currentIndex)
          ? _searchOpen
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.mutedForeground),
                onPressed: _closeSearch,
              )
            : Center(
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsetsDirectional.only(start: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.search, size: 15, color: AppColors.mutedForeground),
                    onPressed: _toggleSearch,
                  ),
                ),
              )
          : null,
        leadingWidth: (!_searchOpen && _hasSearch(currentIndex)) ? 54 : null,
        centerTitle: true,
        title: _searchOpen
          ? TextField(
              controller: _searchTextCtrl,
              autofocus: true,
              onChanged: _setSearch,
              style: const TextStyle(fontSize: 15, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchTextCtrl,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.mutedForeground),
                      onPressed: _clearText,
                    );
                  },
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            )
          : const Text('LevelUp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
        actions: [
          const LocaleToggleButton(),
          const SizedBox(width: 8),
          _buildProfileButton(l10n),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                _buildSidebar(context, l10n, currentIndex),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: IndexedStack(
                        index: currentIndex,
                        children: _screens,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (i) {
                  _closeSearch();
                  context.go('/student?tab=$i');
                },
                backgroundColor: AppColors.white,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.mutedForeground,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: [
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.home, active: false), activeIcon: const GoldenNavIcon(icon: Icons.home), label: AppLocalizations.of(context)!.navHome),
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.check_circle, active: false), activeIcon: const GoldenNavIcon(icon: Icons.check_circle), label: AppLocalizations.of(context)!.navTasks),
                  BottomNavigationBarItem(
                    icon: ListenableBuilder(
                      listenable: getIt<StudentNotificationController>(),
                      builder: (context, _) {
                        final count = getIt<StudentNotificationController>().unreadCount;
                        return Badge(
                          label: count > 0 ? Text('$count') : null,
                          isLabelVisible: count > 0,
                          child: const GoldenNavIcon(icon: Icons.notifications, active: false),
                        );
                      },
                    ),
                    activeIcon: ListenableBuilder(
                      listenable: getIt<StudentNotificationController>(),
                      builder: (context, _) {
                        final count = getIt<StudentNotificationController>().unreadCount;
                        return Badge(
                          label: count > 0 ? Text('$count') : null,
                          isLabelVisible: count > 0,
                          child: const GoldenNavIcon(icon: Icons.notifications),
                        );
                      },
                    ),
                    label: AppLocalizations.of(context)!.navAlerts,
                  ),
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.person, active: false), activeIcon: const GoldenNavIcon(icon: Icons.person), label: AppLocalizations.of(context)!.navProfile),
                ],
              ),
            ),
    );
  }
}
