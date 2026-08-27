import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../di/service_locator.dart';
import '../../../logic/helpers/logout_helper.dart';
import '../../../logic/controllers/admin_statistics_controller.dart';
import '../../../logic/controllers/curriculum_controller.dart';
import '../../../logic/controllers/user_controller.dart';
import '../../../logic/controllers/group_controller.dart';
import '../../../logic/controllers/audit_log_controller.dart';
import '../../../logic/controllers/admin_assignments_controller.dart';
import '../../widgets/locale_toggle_button.dart';
import '../../widgets/sidebar_nav_item.dart';

import '../admin/admin_dashboard.dart';
import '../admin/admin_statistics_screen.dart';
import '../admin/admin_assignments_screen.dart';
import '../admin/curriculum_screen.dart';
import '../admin/groups_screen.dart';
import '../admin/users_screen.dart';
import '../admin/logs_screen.dart';
import '../../widgets/golden_nav_icon.dart';


class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final TextEditingController _searchTextCtrl = TextEditingController();

  late final List<Widget> _screens = [
    AdminDashboard(
      onNavigateToCurriculum: () => context.go('/admin?tab=1'),
      onNavigateToUsers:       () => context.go('/admin?tab=2'),
      onNavigateToGroups:      () => context.go('/admin?tab=3'),
      onNavigateToLogs:        () => context.go('/admin?tab=4'),
    ),
    const CurriculumScreen(),
    const UsersScreen(),
    const GroupsScreen(),
    const LogsScreen(),
    const AdminStatisticsScreen(),
    const AdminAssignmentsScreen(),
  ];

  @override
  void dispose() {
    _searchTextCtrl.dispose();
    super.dispose();
  }

  void _setSearch(String val) {
    final tabParam = GoRouterState.of(context).uri.queryParameters['tab'];
    final currentIndex = (int.tryParse(tabParam ?? '') ?? 0).clamp(0, 6);
    switch (currentIndex) {
      case 1:
        getIt<CurriculumController>().setSearch(val);
      case 2:
        getIt<UserController>().setSearch(val);
      case 3:
        getIt<GroupController>().setSearch(val);
        getIt<GroupController>().setArchiveSearch(val);
      case 4:
        getIt<AuditLogController>().setSearch(val);
      case 6:
        getIt<AdminAssignmentsController>().setSearch(val);
    }
  }

  /// Clears the persistent search field and the per-tab search filter it
  /// drives. Called whenever the user navigates to a different tab.
  void _resetSearch() {
    _searchTextCtrl.clear();
    _setSearch('');
  }

  void _goToTab(int index) {
    _resetSearch();
    if (index == 5) getIt<AdminStatisticsController>().refresh();
    context.go('/admin?tab=$index');
  }

  /// Single-letter avatar fallback, e.g. "Ibrahim" -> "I", or "A" if no name
  /// is resolvable from the current Firebase user.
  String _avatarLetter(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'A';
  }

  Widget _buildSidebar(BuildContext context, AppLocalizations l10n, int currentIndex) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final displayName = firebaseUser?.displayName;
    final photoUrl = firebaseUser?.photoURL;
    final avatarLetter = _avatarLetter(displayName);

    final navItems = <({IconData icon, String label, int tabIndex})>[
      (icon: Icons.dashboard_rounded, label: l10n.navHome, tabIndex: 0),
      (icon: Icons.menu_book, label: l10n.navCurriculum, tabIndex: 1),
      (icon: Icons.people, label: l10n.navUsers, tabIndex: 2),
      (icon: Icons.how_to_reg, label: l10n.navGroups, tabIndex: 3),
      (icon: Icons.assignment_rounded, label: l10n.assignmentsTitle, tabIndex: 6),
      (icon: Icons.list_alt, label: l10n.navLogs, tabIndex: 4),
      (icon: Icons.bar_chart_rounded, label: 'Stats', tabIndex: 5),
    ];

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
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                for (final item in navItems)
                  SidebarNavItem(
                    icon: item.icon,
                    label: item.label,
                    active: item.tabIndex == currentIndex,
                    onTap: () => _goToTab(item.tabIndex),
                  ),
              ],
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
                        l10n.roleAdministrator,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.superAdmin,
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

  Widget _buildSearchField(AppLocalizations l10n) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SizedBox(
        height: 40,
        child: TextField(
          controller: _searchTextCtrl,
          onChanged: _setSearch,
          onSubmitted: _setSearch,
          style: const TextStyle(fontSize: 13, color: AppColors.text),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mutedForeground),
            hintText: l10n.globalSearchHint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
            hintMaxLines: 1,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.roleAdministrator, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text)),
                Text(l10n.superAdmin, style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
              ],
            ),
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
    final currentIndex = (int.tryParse(tabParam ?? '') ?? 0).clamp(0, 6);
    final bool isWide = _enableResponsiveDesktopLayout && MediaQuery.of(context).size.width > 850;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        centerTitle: true,
        title: _buildSearchField(l10n),
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
                onTap: _goToTab,
                backgroundColor: AppColors.white,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.mutedForeground,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: [
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.home, active: false), activeIcon: const GoldenNavIcon(icon: Icons.home), label: AppLocalizations.of(context)!.navHome),
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.menu_book, active: false), activeIcon: const GoldenNavIcon(icon: Icons.menu_book), label: AppLocalizations.of(context)!.navCurriculum),
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.people, active: false), activeIcon: const GoldenNavIcon(icon: Icons.people), label: AppLocalizations.of(context)!.navUsers),
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.how_to_reg, active: false), activeIcon: const GoldenNavIcon(icon: Icons.how_to_reg), label: AppLocalizations.of(context)!.navGroups),
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.list_alt, active: false), activeIcon: const GoldenNavIcon(icon: Icons.list_alt), label: AppLocalizations.of(context)!.navLogs),
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.bar_chart_rounded, active: false), activeIcon: const GoldenNavIcon(icon: Icons.bar_chart_rounded), label: 'Stats'),
                  BottomNavigationBarItem(icon: const GoldenNavIcon(icon: Icons.assignment_rounded, active: false), activeIcon: const GoldenNavIcon(icon: Icons.assignment_rounded), label: AppLocalizations.of(context)!.assignmentsTitle),
                ],
              ),
            ),
    );
  }
}
