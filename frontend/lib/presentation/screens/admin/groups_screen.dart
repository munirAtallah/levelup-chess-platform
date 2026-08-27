/// Presentation Tier — Screen
/// Path: lib/presentation/screens/admin/groups_screen.dart
///
/// ✅ Two tabs: Active Groups | Archived Groups
/// ✅ Archive tab: Restore + Permanently Delete actions
/// ✅ Zero business logic — via GroupController
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/group_model.dart';
import '../../widgets/group_card.dart';
import '../../widgets/empty_state.dart';
import '../../../logic/controllers/group_controller.dart';
import '../../../di/service_locator.dart';
import '../../../data/models/curriculum_model.dart';
import '../../../data/repositories/curriculum_repository.dart';
import '../../../data/models/user_model.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  final GroupController _controller = getIt<GroupController>();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Always refresh on mount — GroupController is a singleton so data may be stale.
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.refresh());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Always reload archive when switching to the Archive tab.
      if (_tabController.index == 1) {
        _controller.loadArchivedGroups();
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ── Dialogs ────────────────────────────────────────────────────────────

  void _showAddGroupDialog() {
    final nameController = TextEditingController();
    final selectedLevelIds = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.group_add, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('New Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => FutureBuilder<List<LevelModel>>(
            future: getIt<CurriculumRepository>().getLevels(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final levels = snapshot.data ?? [];
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create a new group', style: TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Group Name',
                      prefixIcon: const Icon(Icons.label_outline, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.input, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Levels', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: levels.map((lvl) {
                      final isSelected = selectedLevelIds.contains(lvl.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(lvl.name),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedLevelIds.add(lvl.id);
                            } else {
                              selectedLevelIds.remove(lvl.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              if (selectedLevelIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('At least one level must be selected.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await _controller.createGroup(name, selectedLevelIds.toList());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "$name" created'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create group: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmArchiveGroup(GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${group.name}?',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete this group?\nInstructors count: ${group.instructorIds.length}',
                    style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground)),
                const SizedBox(height: 12),
                if (group.students.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: This group has ${group.students.length} student(s). They will be unassigned from this group.',
                            style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'The group will be moved to the Archive tab and can be restored.',
                          style: TextStyle(fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _controller.deleteGroup(group.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${group.name}" moved to archive'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete group: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showArchivedGroupDetails(GroupModel group, int position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
        final archivedDate = group.archivedAt != null
            ? 'Archived on: ${DateFormat('MMM d, y').format(group.archivedAt!)}'
            : 'Archived on: —';
        return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(group.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mutedForeground.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Archived',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedForeground)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.people_outline, 'Students', '${group.students.length}'),
              _detailRow(Icons.person_outline, 'Instructors', '${group.instructorIds.length}'),
              _detailRow(Icons.archive_outlined, 'Status', archivedDate),
              const SizedBox(height: 8),
              // Restore / Close
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text('Close',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: AppColors.mutedForeground)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _controller.restoreGroup(group.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('"${group.name}" restored'),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child:
                          const Text('Restore', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Permanently Delete (danger zone)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, color: AppColors.error, size: 18),
                  label: const Text('Permanently Delete',
                      style: TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _controller.permanentlyDeleteGroup(group.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('"${group.name}" permanently deleted'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                ),
              ),
            ],
          ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final l10n = AppLocalizations.of(context)!;
        final isArchiveTab = _tabController.index == 1;
        final isUnassignedTab = _tabController.index == 2;
        final groups = _controller.groups;
        final archivedGroups = _controller.archivedGroups;
        final unassignedStudents = _controller.unassignedStudents;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: _tabController.index == 0
              ? FloatingActionButton(
                  heroTag: 'fab_admin_groups',
                  onPressed: _showAddGroupDialog,
                  backgroundColor: AppColors.primary,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isArchiveTab
                                      ? 'Archived Groups'
                                      : isUnassignedTab
                                          ? 'Unassigned Students'
                                          : l10n.groupsTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isArchiveTab
                                  ? '${archivedGroups.length} archived groups'
                                  : isUnassignedTab
                                      ? '${unassignedStudents.length} unassigned students'
                                      : l10n.groupsCount(groups.length.toString()),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  color: AppColors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.mutedForeground,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2,
                    labelStyle:
                        const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle:
                        const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: [
                      Tab(text: 'Active (${groups.length})'),
                      Tab(text: 'Archived (${archivedGroups.length})'),
                      Tab(text: 'Unassigned (${unassignedStudents.length})'),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ── Active Groups ──
                      Column(
                        children: [
                          Expanded(
                            child: groups.isEmpty
                                ? EmptyState(
                                    icon: Icons.how_to_reg,
                                    title: l10n.noGroupsFound,
                                    subtitle: l10n.tryDifferentSearch,
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsetsDirectional.only(
                                        start: 20, top: 16, end: 20, bottom: 100),
                                    itemCount: groups.length,
                                    itemBuilder: (context, index) {
                                      final group = groups[index];
                                      final levelLabel = group.levelIds.isEmpty
                                          ? l10n.noLevelsAssigned
                                          : group.levelIds
                                              .map((l) => l10n.levelLabel(
                                                  l.replaceAll('l', '')))
                                              .join(' · ');
                                      return Dismissible(
                                        key: ValueKey(group.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment:
                                              AlignmentDirectional.centerEnd,
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  end: 20),
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: const Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.archive,
                                                  color: AppColors.white),
                                              SizedBox(height: 2),
                                              Text('Archive',
                                                  style: TextStyle(
                                                      color: AppColors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                        confirmDismiss: (_) async {
                                           _confirmArchiveGroup(group);
                                           return false;
                                         },
                                        child: GroupCard(
                                          groupName: group.name,
                                          instructorsCount:
                                              group.instructorIds.length,
                                          levelName: levelLabel,
                                          studentsCount: group.studentIds.length,
                                          onPress: () async {
                                            await context.push('/group/${group.id}');
                                            _controller.refresh();
                                          },
                                          trailing: PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.mutedForeground),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            onSelected: (val) {
                                              if (val == 'rename') _showRenameGroupDialog(group);
                                              if (val == 'archive') _confirmArchiveGroup(group);
                                            },
                                            itemBuilder: (_) => [
                                              const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Rename')])),
                                              const PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive_outlined, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Archive', style: TextStyle(color: AppColors.error))])),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),

                      // ── Archived Groups ──
                      Column(
                        children: [
                          Expanded(
                            child: archivedGroups.isEmpty
                                ? const EmptyState(
                                    icon: Icons.archive_outlined,
                                    title: 'No archived groups',
                                    subtitle: 'Deleted groups will appear here',
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsetsDirectional.only(
                                        start: 20, top: 16, end: 20, bottom: 100),
                                    itemCount: archivedGroups.length,
                                    itemBuilder: (context, index) {
                                      final group = archivedGroups[index];
                                      return _buildArchivedGroupCard(group, index + 1);
                                    },
                                  ),
                          ),
                        ],
                      ),

                      // ── Unassigned Students ──
                      Column(
                        children: [
                          Expanded(
                            child: unassignedStudents.isEmpty
                                ? const EmptyState(
                                    icon: Icons.person_off_outlined,
                                    title: 'No unassigned students',
                                    subtitle: 'All students are in groups',
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsetsDirectional.only(start: 20, top: 16, end: 20, bottom: 100),
                                    itemCount: unassignedStudents.length,
                                    itemBuilder: (context, index) {
                                      final student = unassignedStudents[index];
                                      return _buildUnassignedStudentCard(student);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameGroupDialog(GroupModel group) {
    final nameController = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('Rename Group', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New Group Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              Navigator.pop(ctx);
              if (newName.isNotEmpty && newName != group.name) {
                try {
                  await _controller.updateGroup(group.id, newName);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to rename group: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            child: const Text('Rename', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedStudentCard(UserModel student) {
    final name = student.name;
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (parts.isNotEmpty && parts[0].length >= 2 ? parts[0].substring(0, 2).toUpperCase() : '??');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            foregroundColor: AppColors.primary,
            radius: 22,
            child: Text(initials, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 3),
                Text('@${student.username ?? student.studentNumber}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                const SizedBox(height: 3),
                if (student.levelId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Level: ${student.levelId}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showAssignToGroupDialog(student),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showAssignToGroupDialog(UserModel student) {
    final studentLevelId = student.levelId;
    if (studentLevelId == null || studentLevelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student has no assigned level.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final matchingGroups = _controller.groups
        .where((g) => g.levelIds.contains(studentLevelId))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Assign ${student.name} to Group', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.maxFinite,
            child: matchingGroups.isEmpty
                ? Text('No active groups found for level: $studentLevelId')
                : ListView.builder(
                  shrinkWrap: true,
                  itemCount: matchingGroups.length,
                  itemBuilder: (context, index) {
                    final grp = matchingGroups[index];
                    return ListTile(
                      title: Text(grp.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          try {
                            await _controller.assignStudentToGroup(
                              student.id,
                              grp.id,
                              studentLevelId,
                              student.name,
                            );
                            messenger.showSnackBar(
                              SnackBar(content: Text('${student.name} assigned to ${grp.name}')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        },
                        child: const Text('Assign'),
                      ),
                    );
                  },
                ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedGroupCard(GroupModel group, int position) {
    final archivedDate = group.archivedAt != null
        ? DateFormat('MMM d, y').format(group.archivedAt!)
        : '—';

    return GestureDetector(
      onTap: () => _showArchivedGroupDetails(group, position),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.mutedForeground.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.group_outlined,
                  size: 22, color: AppColors.mutedForeground),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.students.length} students · ${group.instructorIds.length} instructors',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Archived $archivedDate',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            // Badge + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mutedForeground.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#$position',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedForeground),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.mutedForeground),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
