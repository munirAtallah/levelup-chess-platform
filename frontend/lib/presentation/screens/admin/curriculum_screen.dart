/// Presentation Tier — Screen
/// Path: lib/presentation/screens/admin/curriculum_screen.dart
///
/// Proof-of-concept for the 3-Tier Architecture:
///   - No business logic here — every mutation (add level, add week, toggle
///     visibility, delete item) is delegated to [CurriculumController].
///   - No data declarations — the full curriculum tree comes from the
///     controller which sourced it from [CurriculumRepository].
///   - [ListenableBuilder] wraps the body so any controller.notifyListeners()
///     call triggers a reactive rebuild without setState.
///
///Dialog helpers (_showAddLevelDialog, _showAddWeekDialog, etc.) are pure UI:
/// they collect user input from AlertDialogs and hand the result to the
/// controller. They do not mutate any state themselves.
// ignore_for_file: experimental_member_use
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/curriculum_model.dart';
import '../../../logic/controllers/curriculum_controller.dart';
import '../../../di/service_locator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/assignment_card.dart';
import 'material_editor_screen.dart';
import 'assignment_editor_screen.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  // -- Injected Controller (from Logic Tier) ----------
  final CurriculumController _controller = getIt<CurriculumController>();

  // -- Dialog Helpers (pure UI — no state mutation) ---
  void _showAddWeekDialog(String levelId) {
    String name = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(AppLocalizations.of(context)!.addWeekTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.weekNameLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onChanged: (val) => name = val,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: AppColors.mutedForeground))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              _controller.addWeek(levelId, name);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.add, style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showAddMaterialDialog(String levelId, String weekId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MaterialEditorScreen(
          levelId: levelId,
          weekId: weekId,
        ),
      ),
    );
  }

  void _showAddAssignmentDialog(String levelId, String weekId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AssignmentEditorScreen(
          levelId: levelId,
          weekId: weekId,
        ),
      ),
    );
  }

  void _showEditMaterialSheet(String levelId, String weekId, String itemId, CurriculumItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MaterialEditorScreen(
          levelId: levelId,
          weekId: weekId,
          itemId: itemId,
          item: item,
        ),
      ),
    );
  }

  void _showEditAssignmentSheet(String levelId, String weekId, String itemId, CurriculumItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AssignmentEditorScreen(
          levelId: levelId,
          weekId: weekId,
          itemId: itemId,
          item: item,
        ),
      ),
    );
  }

  void _showEditLevelDialog(LevelModel level) {
    final nameCtrl = TextEditingController(text: level.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('Edit Level', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.levelNameLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              try {
                await _controller.editLevel(level.id, nameCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditWeekDialog(String levelId, WeekModel week) {
    final nameCtrl = TextEditingController(text: week.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('Edit Week', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Week name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await _controller.editWeek(levelId, week.id, nameCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteWeekDialog(String levelId, WeekModel week) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Week', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete "${week.name}"?', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                const Text('All materials and assignments inside this week will be permanently deleted. This action cannot be undone.', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              _controller.deleteWeek(levelId, week.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddLevelDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(
          AppLocalizations.of(ctx)!.addLevelTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx)!.levelNameLabel,
                hintText: 'e.g. Level 4',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel,
                style: const TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await _controller.addLevel(name);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(ctx)!.add,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteLevelDialog(LevelModel level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FutureBuilder<List<int>>(
        future: Future.wait([
          _controller.getStudentCountForLevel(level.id),
          _controller.getActiveGroupsCountForLevel(level.id),
        ]),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final studentCount = data != null ? data[0] : 0;
          final groupCount = data != null ? data[1] : 0;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          return AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Delete Level',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            content: isLoading
                ? const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        'Are you sure you want to delete "${level.name}"?',
                        style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      if (studentCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Warning: $studentCount student(s) are assigned to this level. Deleting it may cause inconsistencies.',
                                  style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (groupCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Warning: $groupCount active group(s) are using this level. Deleting it may affect level access.',
                                  style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Text(
                        'All weeks and items inside this level will be permanently deleted. This action cannot be undone.',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
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
              if (!isLoading)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _controller.deleteLevel(level.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          );
        },
      ),
    );
  }

  // -- Build ------------------------------------------
  @override
  Widget build(BuildContext context) {
    // ListenableBuilder reacts to notifyListeners() from the controller
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final levels = _controller.levels;

        return Scaffold(
          backgroundColor: Colors.transparent,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.curriculumTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(AppLocalizations.of(context)!.levelsCount((levels.length).toString()), style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                          ],
                        ),
                      ),
                      // + Add Level button
                      ElevatedButton.icon(
                        onPressed: _showAddLevelDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppLocalizations.of(context)!.addLevelTitle,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: levels.isEmpty
                      ? EmptyState(
                          icon: Icons.menu_book,
                          title: AppLocalizations.of(context)!.noLevelsYet,
                          subtitle: AppLocalizations.of(context)!.addFirstLevel,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: levels.length,
                          itemBuilder: (context, index) {
                            return _buildLevelBlock(levels[index]);
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

  Widget _buildLevelBlock(LevelModel level) {
    final isExpanded = _controller.isLevelExpanded(level.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _controller.toggleLevel(level.id),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(level.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text))),
                  Text(AppLocalizations.of(context)!.weeksCount((level.weeks.length).toString()), style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.mutedForeground),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showEditLevelDialog(level),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showDeleteLevelDialog(level),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.mutedForeground),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              margin: const EdgeInsetsDirectional.only(top: 4, start: 12),
              padding: const EdgeInsetsDirectional.only(start: 12),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.border, width: 2)),
              ),
              child: Column(
                children: [
                  ...level.weeks.map((week) => _buildWeekBlock(level.id, week)),
                  GestureDetector(
                    onTap: () => _showAddWeekDialog(level.id),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 4, bottom: 8, start: 8, end: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(AppLocalizations.of(context)!.addWeekTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekBlock(String levelId, WeekModel week) {
    final isExpanded = _controller.isWeekExpanded(week.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _controller.toggleWeek(week.id),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Icon(isExpanded ? Icons.expand_more : Icons.chevron_right, size: 15, color: AppColors.mutedForeground),
                  const SizedBox(width: 8),
                  Expanded(child: Text(week.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text))),
                  Text(AppLocalizations.of(context)!.itemsCount((week.items.length).toString()), style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.mutedForeground),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => _showEditWeekDialog(levelId, week),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => _showDeleteWeekDialog(levelId, week),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  ...week.items.map((item) {
                    if (item.type == CurriculumItemType.material) {
                      return LessonCard(
                        title: item.title,
                        searchTags: item.searchTags,
                        isVisible: item.visible,
                        showToggle: true,
                        onToggle: () => _controller.toggleVisibility(levelId, week.id, item.id),
                        onPress: () => context.push('/lesson/${item.id}'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.mutedForeground),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                          ],
                          onSelected: (val) {
                            if (val == 'edit') _showEditMaterialSheet(levelId, week.id, item.id, item);
                            if (val == 'delete') _controller.deleteItem(levelId, week.id, item.id);
                          },
                        ),
                      );
                    } else if (item.type == CurriculumItemType.assignment) {
                      return AssignmentCard(
                        title: item.title,
                        type: 'central',
                        isAdminView: true,
                        isActive: item.isActive,
                        isVisible: item.visible,
                        showToggle: true,
                        onToggle: () => _controller.toggleVisibility(levelId, week.id, item.id),
                        deadlineText: item.deadlineText,
                        isOverdue: false,
                        pendingCount: 0,
                        gradedCount: 0,
                        onPress: () => context.push('/assignment/${item.id}', extra: 'admin'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.mutedForeground),
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                          ],
                          onSelected: (val) {
                            if (val == 'edit') _showEditAssignmentSheet(levelId, week.id, item.id, item);
                            if (val == 'delete') _controller.deleteItem(levelId, week.id, item.id);
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  if (week.items.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(AppLocalizations.of(context)!.noItemsYet, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.mutedForeground)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddMaterialDialog(levelId, week.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(AppLocalizations.of(context)!.addMaterial, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddAssignmentDialog(levelId, week.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.text,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(AppLocalizations.of(context)!.addAssignment, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
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
}
