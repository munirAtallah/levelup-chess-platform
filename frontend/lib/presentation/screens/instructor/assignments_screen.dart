/// Presentation Tier — Screen
/// Path: lib/presentation/screens/instructor/assignments_screen.dart
///
/// ✅ Filter chips (All, Overdue, Central, Custom) are clickable
/// ✅ Create Assignment FAB with two options: from curriculum pool or new
/// ✅ Cards navigate to AssignmentDetailScreen
library;

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/models/curriculum_model.dart';
import '../../../data/models/group_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/assignment_card.dart';
import '../../../logic/controllers/instructor_assignment_controller.dart';
import '../../../logic/controllers/curriculum_controller.dart';
import '../../../logic/controllers/instructor_group_controller.dart';
import '../../../logic/controllers/auth_controller.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'instructor_assignment_editor_screen.dart';

class InstructorAssignmentsScreen extends StatefulWidget {
  const InstructorAssignmentsScreen({super.key});

  @override
  State<InstructorAssignmentsScreen> createState() => _InstructorAssignmentsScreenState();
}

class _InstructorAssignmentsScreenState extends State<InstructorAssignmentsScreen> {
  final InstructorAssignmentController _controller = getIt<InstructorAssignmentController>();
  final CurriculumController _curriculumController = getIt<CurriculumController>();
  final InstructorGroupController _groupController = getIt<InstructorGroupController>();
  final AuthController _authController = getIt<AuthController>();

  List<String> _assignedLevelIds = [];

  @override
  void initState() {
    super.initState();
    _authController.getCurrentAssignedLevels().then((ids) {
      if (mounted) setState(() => _assignedLevelIds = ids);
    });
  }

  void _showCreateAssignmentFlow() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(l10n.createAssignment, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 6),
          Text(l10n.chooseCreationMethod, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
          const SizedBox(height: 24),
          // Option A: From Admin Template
          _buildOptionCard(
            icon: Icons.library_books,
            iconColor: AppColors.primary,
            title: l10n.fromAdminTemplate,
            subtitle: l10n.fromAdminTemplateDesc,
            onTap: () { Navigator.pop(ctx); _showAdminTemplatePicker(); },
          ),
          const SizedBox(height: 12),
          // Option B: Create New
          _buildOptionCard(
            icon: Icons.edit_note,
            iconColor: AppColors.accent,
            title: l10n.createFromScratch,
            subtitle: l10n.createFromScratchDesc,
            onTap: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const InstructorAssignmentEditorScreen(),
              ));
            },
          ),
          const SizedBox(height: 16),
        ]),
        ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({required IconData icon, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
          ])),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.mutedForeground),
        ]),
      ),
    );
  }

  void _showAdminTemplatePicker() {
    final templateItems = <CurriculumItem>[];
    for (final level in _curriculumController.levels) {
      for (final week in level.weeks) {
        for (final item in week.items) {
          if (item.type == CurriculumItemType.assignment) {
            templateItems.add(item);
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.library_books, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.adminTemplates, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: templateItems.isEmpty
            ? Center(child: Text(AppLocalizations.of(context)!.noTemplatesAvailable, style: const TextStyle(color: AppColors.mutedForeground)))
            : ListView.builder(
                itemCount: templateItems.length,
                itemBuilder: (_, i) {
                  final item = templateItems[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showTemplateAssignDialog(item.title);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(AppLocalizations.of(context)!.centralTemplate, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                        ])),
                        const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                      ]),
                    ),
                  );
                },
              ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancelButton, style: const TextStyle(color: AppColors.mutedForeground)),
          ),
        ],
      ),
    );
  }

  void _showTemplateAssignDialog(String templateTitle) {
    GroupModel? selectedGroup;
    LevelModel? selectedLevel;
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocalizations.of(context)!.assignTemplateTitle(templateTitle),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<GroupModel>(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.selectGroupStep,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _groupController.myGroups.map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(g.name),
                )).toList(),
                onChanged: (val) => setDialogState(() => selectedGroup = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LevelModel>(
                initialValue: selectedLevel,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.selectLevelHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _curriculumController.levels
                    .where((l) => _assignedLevelIds.contains(l.id))
                    .map((l) => DropdownMenuItem(
                  value: l,
                  child: Text(l.name),
                )).toList(),
                onChanged: (val) => setDialogState(() => selectedLevel = val),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null && context.mounted) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 23, minute: 59),
                      initialEntryMode: TimePickerEntryMode.inputOnly,
                    );
                    if (pickedTime != null) {
                      setDialogState(() {
                        selectedDeadline = DateTime(
                          pickedDate.year, pickedDate.month, pickedDate.day,
                          pickedTime.hour, pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.input, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.schedule, size: 16, color: AppColors.mutedForeground),
                    const SizedBox(width: 8),
                    Text(
                      selectedDeadline != null
                        ? '${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}  ${selectedDeadline!.hour}:${selectedDeadline!.minute.toString().padLeft(2, '0')}'
                        : AppLocalizations.of(context)!.selectDeadline,
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDeadline != null ? AppColors.text : AppColors.mutedForeground,
                      ),
                    ),
                  ]),
                ),
              ),
              ],
            ),
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancelButton, style: const TextStyle(color: AppColors.mutedForeground)),
            ),
            ElevatedButton(
              onPressed: selectedGroup == null ? null : () async {
                final group = selectedGroup!;
                final messenger = ScaffoldMessenger.of(context);
                final l10n = AppLocalizations.of(context)!;
                Navigator.pop(ctx);
                await _controller.addAssignment(
                  templateTitle,
                  type: 'central',
                  groupId: group.id,
                  groupName: group.name,
                  deadline: selectedDeadline,
                );
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.assignmentAssignedToGroup(templateTitle, group.name)),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppLocalizations.of(context)!.assign, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final l10n = AppLocalizations.of(context)!;
        final tab = _controller.tab;
        final assignments = _controller.assignments;
        final currentFilter = _controller.filter;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_instructor_assignments',
            onPressed: _showCreateAssignmentFlow,
            backgroundColor: AppColors.accent,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, color: AppColors.text, size: 24),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text(l10n.assignmentsTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                      ]),
                      Text(
                        tab == 'active'
                            ? l10n.activeCount(assignments.length.toString())
                            : l10n.pastCount(assignments.length.toString()),
                        style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
                      ),
                    ])),
                  ]),
                ),

                // Tab Toggle
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () => _controller.switchTab('active'),
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: BoxDecoration(color: tab == 'active' ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(l10n.tabActive, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tab == 'active' ? AppColors.white : AppColors.mutedForeground))),
                    )),
                    Expanded(child: GestureDetector(
                      onTap: () => _controller.switchTab('past'),
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: BoxDecoration(color: tab == 'past' ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(l10n.tabPast, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tab == 'past' ? AppColors.white : AppColors.mutedForeground))),
                    )),
                  ]),
                ),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _buildFilterChip(l10n.filterAll, 'all', currentFilter),
                      _buildFilterChip(l10n.filterCentral, 'central', currentFilter),
                      _buildFilterChip(l10n.filterCustom, 'custom', currentFilter),
                    ]),
                  ),
                ),

                // List
                Expanded(
                  child: assignments.isEmpty
                    ? EmptyState(icon: Icons.assignment_outlined, title: l10n.noAssignments, subtitle: l10n.noAssignmentsSubtitle)
                    : ListView.builder(
                        padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 100),
                        itemCount: assignments.length,
                        itemBuilder: (context, index) {
                          final a = assignments[index];
                          return AssignmentCard(
                            title: a.title, type: a.type, isActive: a.isActive, isOverdue: a.isOverdue,
                            deadlineText: a.deadlineText, deadline: a.deadline, groupName: a.groupName, pendingCount: a.pendingCount, gradedCount: a.gradedCount,
                            onPress: () => context.push('/assignment/${a.id}'),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.mutedForeground),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) {
                                if (val == 'edit_content') {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (_) => InstructorAssignmentEditorScreen(initialAssignment: a),
                                  ));
                                }
                                if (val == 'edit_deadline') _showEditDeadlineDialog(a);
                                if (val == 'delete') _showDeleteAssignmentDialog(a);
                              },
                              itemBuilder: (_) => [
                                if (a.type == 'custom' && !a.isOverdue)
                                  PopupMenuItem(value: 'edit_content', child: Row(children: [const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary), const SizedBox(width: 8), Text(l10n.editContent)])),
                                PopupMenuItem(value: 'edit_deadline', child: Row(children: [const Icon(Icons.schedule, size: 16, color: AppColors.primary), const SizedBox(width: 8), Text(l10n.editDeadlineMenu)])),
                                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 16, color: AppColors.error), const SizedBox(width: 8), Text(l10n.deleteAssignment, style: const TextStyle(color: AppColors.error))])),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, String current) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: () => _controller.setFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.mutedForeground)),
        ),
      ),
    );
  }

  void _showEditDeadlineDialog(AssignmentModel assignment) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: assignment.deadline.isAfter(DateTime.now()) ? assignment.deadline : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: assignment.deadline.hour, minute: assignment.deadline.minute),
        initialEntryMode: TimePickerEntryMode.inputOnly,
      );
      if (pickedTime != null) {
        final newDeadline = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        _controller.updateDeadline(assignment.id, newDeadline);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.deadlineUpdated(assignment.title)), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }


  void _showDeleteAssignmentDialog(AssignmentModel assignment) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteAssignment, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(l10n.deleteAssignmentConfirm),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _controller.deleteAssignment(assignment.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.assignmentDeleted(assignment.title)), behavior: SnackBarBehavior.floating),
              );
            },
            child: Text(l10n.deleteButton, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

}
