library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/curriculum_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/instructor_material_model.dart';
import '../../../logic/controllers/auth_controller.dart';
import '../../../logic/controllers/curriculum_controller.dart';
import '../../../logic/controllers/instructor_assignment_controller.dart';
import '../../../logic/controllers/instructor_group_controller.dart';
import '../../../logic/controllers/instructor_material_controller.dart';
import '../../../data/repositories/instructor_material_repository.dart';
import '../../../di/service_locator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/assignment_card.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../admin/material_editor_screen.dart';
import '../details/lesson_detail_screen.dart';

class InstructorCurriculumScreen extends StatefulWidget {
  const InstructorCurriculumScreen({super.key});

  @override
  State<InstructorCurriculumScreen> createState() =>
      _InstructorCurriculumScreenState();
}

class _InstructorCurriculumScreenState extends State<InstructorCurriculumScreen>
    with SingleTickerProviderStateMixin {
  final CurriculumController _controller = getIt<CurriculumController>();
  final InstructorAssignmentController _assignmentController =
      getIt<InstructorAssignmentController>();
  final InstructorGroupController _groupController =
      getIt<InstructorGroupController>();
  final AuthController _authController = getIt<AuthController>();
  final InstructorMaterialController _materialController =
      getIt<InstructorMaterialController>();

  late final TabController _tabController;

  List<String> _assignedLevelIds = [];
  bool _materialsLoaded = false;

  // Group name cache: groupId → name
  Map<String, String> _groupNames = {};
  // Level name cache: levelId → name
  Map<String, String> _levelNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _authController.getCurrentAssignedLevels().then((ids) {
      if (mounted) setState(() => _assignedLevelIds = ids);
    });
    _buildNameCaches();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_materialsLoaded) {
      _loadMaterials();
    }
  }

  Future<void> _buildNameCaches() async {
    // Group names
    final groups = _groupController.myGroups;
    final gMap = <String, String>{};
    for (final g in groups) {
      gMap[g.id] = g.name;
    }
    // Level names come from curriculum controller once loaded.
    _groupNames = gMap;
    if (mounted) setState(() {});
  }

  void _refreshGroupNames() {
    final groups = _groupController.myGroups;
    final gMap = <String, String>{};
    for (final g in groups) {
      gMap[g.id] = g.name;
    }
    _groupNames = gMap;
    if (mounted) setState(() {});
  }

  String _groupName(String groupId) =>
      _groupNames[groupId] ?? groupId;

  String _levelName(String levelId) {
    // Try curriculum controller levels first.
    try {
      final lvl = _controller.levels.firstWhere((l) => l.id == levelId);
      return lvl.name;
    } catch (_) {}
    return levelId;
  }

  Future<void> _loadMaterials() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _materialController.loadInstructorMaterials(uid);
    _refreshGroupNames();
    if (mounted) setState(() => _materialsLoaded = true);
  }



  int _parseLevelNumber(String id) {
    final clean = id.toLowerCase().replaceAll('l', '').replaceAll('level', '').replaceAll('_', '').trim();
    return int.tryParse(clean) ?? 0;
  }

  int getHighestAssignedLevelNumber() {
    if (_assignedLevelIds.isEmpty) return 0;
    int highest = 0;
    for (final id in _assignedLevelIds) {
      final num = _parseLevelNumber(id);
      if (num > highest) highest = num;
    }
    return highest;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ── My Materials UI ───────────────────────────────────────────────────────

  Widget _buildMyMaterialsTab() {
    return ListenableBuilder(
      listenable: _materialController,
      builder: (context, _) {
        if (_materialController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final materials = _materialController.materials;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            onPressed: _showGroupLevelPicker,
            child: const Icon(Icons.add),
          ),
          body: materials.isEmpty
              ? const EmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: 'No materials yet',
                  subtitle:
                      'Tap + to create your first material for a group.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: materials.length,
                  itemBuilder: (context, i) =>
                      _buildMaterialCard(materials[i]),
                ),
        );
      },
    );
  }

  Widget _buildMaterialCard(InstructorMaterialModel m) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = m.instructorId == uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(instructorMaterial: m),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Visibility indicator dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: m.isVisible
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(_groupName(m.groupId), Icons.group_outlined),
                        _chip(_levelName(m.levelId), Icons.bar_chart),
                        _chip(
                          _formatDate(m.createdAt),
                          Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Visibility toggle button (like admin)
              if (isOwner) ...[
                GestureDetector(
                  onTap: () => _toggleVisibility(m),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: m.isVisible
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      m.isVisible ? Icons.visibility : Icons.visibility_off,
                      size: 16,
                      color: m.isVisible ? Colors.white : AppColors.primary.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: AppColors.mutedForeground),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'edit') _editMaterial(m);
                    if (val == 'delete') _confirmDelete(m);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Edit'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        const Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      DateFormat('d MMM y').format(dt);

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _showGroupLevelPicker() async {
    final groups = _groupController.myGroups;
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No groups assigned to you yet.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    GroupModel? selectedGroup;
    LevelModel? selectedLevel;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Levels available for the selected group AND assigned to instructor.
          final availableLevels = selectedGroup == null
              ? <LevelModel>[]
              : _controller.levels
                  .where((l) =>
                      _assignedLevelIds.contains(l.id) &&
                      selectedGroup!.levelIds.contains(l.id))
                  .toList();

          return AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Select Group & Level',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<GroupModel>(
                    decoration: InputDecoration(
                      labelText: 'Select Group',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: groups
                        .map((g) => DropdownMenuItem(
                            value: g, child: Text(g.name)))
                        .toList(),
                    onChanged: (val) => setDialogState(() {
                      selectedGroup = val;
                      selectedLevel = null;
                    }),
                  ),
                  if (selectedGroup != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<LevelModel>(
                      decoration: InputDecoration(
                        labelText: 'Select Level',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: availableLevels
                          .map((l) => DropdownMenuItem(
                              value: l, child: Text(l.name)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedLevel = val),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.mutedForeground)),
              ),
              ElevatedButton(
                onPressed:
                    (selectedGroup == null || selectedLevel == null)
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _openEditorForNew(
                                selectedGroup!, selectedLevel!);
                          },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Continue',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditorForNew(
      GroupModel group, LevelModel level) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialEditorScreen(
          isInstructorMaterial: true,
          groupId: group.id,
          materialLevelId: level.id,
        ),
      ),
    );
    if (result == true) {
      await _loadMaterials();
    }
  }

  Future<void> _editMaterial(InstructorMaterialModel m) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialEditorScreen(
          isInstructorMaterial: true,
          instructorMaterialId: m.id,
          instructorMaterial: m,
          groupId: m.groupId,
          materialLevelId: m.levelId,
        ),
      ),
    );
    if (result == true) {
      await _loadMaterials();
    }
  }

  Future<void> _confirmDelete(InstructorMaterialModel m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Material',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text('Are you sure you want to delete "${m.title}"?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      await _materialController.deleteMaterial(m.id, instructorId: uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Material deleted'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _toggleVisibility(InstructorMaterialModel m) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      await _materialController.toggleVisibility(
        m.id,
        m.isVisible,
        instructorId: uid,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ── Curriculum Tab (original logic, unchanged) ────────────────────────────

  Widget _buildCurriculumTab() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final maxLevelNum = getHighestAssignedLevelNumber();

        final levels = _controller.levels
            .where((l) {
              final levelNum = _parseLevelNumber(l.id);
              return _assignedLevelIds.contains(l.id) ||
                  (levelNum <= maxLevelNum && levelNum > 0);
            })
            .map((l) => LevelModel(
                  id: l.id,
                  name: l.name,
                  weeks: l.weeks
                      .map((w) => WeekModel(
                            id: w.id,
                            name: w.name,
                            items: w.items
                                .where((i) => i.visible)
                                .toList(),
                          ))
                      .toList(),
                ))
            .toList();

        return _controller.search.isNotEmpty
            ? (() {
                final filteredResults = _controller.searchResults
                    .where((r) {
                      final levelNum = _parseLevelNumber(r.levelId);
                      return _assignedLevelIds.contains(r.levelId) ||
                          (levelNum <= maxLevelNum && levelNum > 0);
                    })
                    .toList();
                if (filteredResults.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title:
                        AppLocalizations.of(context)!.noResults,
                    subtitle: AppLocalizations.of(context)!
                        .tryDifferentKeyword,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsetsDirectional.only(
                      bottom: 100, top: 10, start: 16, end: 16),
                  itemCount: filteredResults.length,
                  itemBuilder: (context, index) {
                    final result = filteredResults[index];
                    final item = result.item;
                    if (item.type == CurriculumItemType.material) {
                      return LessonCard(
                        title: item.title,
                        searchTags: [
                          result.contextLabel,
                          ...item.searchTags
                        ],
                        isVisible: item.visible,
                        showToggle: false,
                        onPress: () =>
                            context.push('/lesson/${item.id}'),
                      );
                    } else if (item.type ==
                        CurriculumItemType.assignment) {
                      return AssignmentCard(
                        title: item.title,
                        type: 'central',
                        isActive: item.isActive,
                        deadlineText: result.contextLabel,
                        isOverdue: false,
                        pendingCount: 0,
                        gradedCount: 0,
                        isAdminView: true,
                        onPress: () =>
                            context.push('/lesson/${item.id}'),
                        trailing: _buildAssignButton(item),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              })()
            : (levels.isEmpty
                ? EmptyState(
                    icon: Icons.menu_book,
                    title: AppLocalizations.of(context)!.noCurriculum,
                    subtitle: AppLocalizations.of(context)!
                        .adminNotAddedCurriculum,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: levels.length,
                    itemBuilder: (context, index) =>
                        _buildLevelBlock(index, levels[index]),
                  ));
      },
    );
  }

  // ── Main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
                              l10n.materialsLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
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
            // Tab bar
            Container(
              color: AppColors.background,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.mutedForeground,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'Curriculum'),
                  Tab(text: 'My Materials'),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Tab body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCurriculumTab(),
                  _buildMyMaterialsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Curriculum helpers (unchanged from original) ─────────────────────────

  Widget _buildLevelBlock(int levelIndex, LevelModel level) {
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      level.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text),
                    ),
                  ),
                  Text('${level.weeks.length}w',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground)),
                  const SizedBox(width: 10),
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              margin: const EdgeInsetsDirectional.only(
                  top: 4, start: 12),
              padding:
                  const EdgeInsetsDirectional.only(start: 12),
              decoration: const BoxDecoration(
                border: Border(
                    left: BorderSide(
                        color: AppColors.border, width: 2)),
              ),
              child: Column(
                children: [
                  ...List.generate(
                    level.weeks.length,
                    (weekIndex) => _buildWeekBlock(
                        levelIndex,
                        weekIndex,
                        level.weeks[weekIndex],
                        level),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekBlock(int levelIndex, int weekIndex,
      WeekModel week, LevelModel level) {
    final isExpanded = _controller.isWeekExpanded(week.id);
    return Column(
      children: [
        GestureDetector(
          onTap: () => _controller.toggleWeek(week.id),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.expand_more
                      : Icons.chevron_right,
                  size: 15,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    week.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!
                      .itemsCount(week.items.length.toString()),
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(children: [
              ...List.generate(week.items.length, (itemIndex) {
                final item = week.items[itemIndex];
                if (item.type == CurriculumItemType.material) {
                  return LessonCard(
                    title: item.title,
                    searchTags: item.searchTags,
                    isVisible: item.visible,
                    showToggle: false,
                    onPress: () => context.push('/lesson/${item.id}'),
                  );
                } else if (item.type == CurriculumItemType.assignment) {
                  return AssignmentCard(
                    title: item.title,
                    type: 'central',
                    isActive: item.isActive,
                    deadlineText: item.deadlineText,
                    isOverdue: false,
                    pendingCount: 0,
                    gradedCount: 0,
                    isAdminView: true,
                    onPress: () => context.push('/lesson/${item.id}'),
                    trailing: _buildAssignButton(item),
                  );
                }
                return const SizedBox.shrink();
              }),
              if (week.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(AppLocalizations.of(context)!.noItemsYet, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.mutedForeground)),
                ),
            ]),
          ),
      ],
    );
  }

  Widget _buildAssignButton(CurriculumItem item) {
    return IconButton(
      onPressed: () => _showAssignAssignmentDialog(item),
      icon: const Icon(Icons.assignment_add,
          size: 20, color: AppColors.primary),
      tooltip:
          AppLocalizations.of(context)!.assignToLevelTooltip,
      padding: EdgeInsets.zero,
      constraints:
          const BoxConstraints(minWidth: 34, minHeight: 34),
      splashRadius: 18,
    );
  }

  void _showAssignAssignmentDialog(CurriculumItem item) {
    GroupModel? selectedGroup;
    LevelModel? selectedLevel;
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final groupLevels = selectedGroup != null
              ? (selectedGroup!.levelIds.isNotEmpty ? selectedGroup!.levelIds : selectedGroup!.activeLevels.toList())
              : <String>[];
          final dialogLevels = _controller.levels
              .where((l) => _assignedLevelIds.contains(l.id) && groupLevels.contains(l.id))
              .toList();

          return AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              AppLocalizations.of(context)!.assignTemplateTitle(item.title),
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
                      onChanged: (val) => setDialogState(() {
                        selectedGroup = val;
                        selectedLevel = null; // reset level when group changes
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<LevelModel>(
                      value: selectedLevel,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.selectLevelHint,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: dialogLevels.map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(l.name),
                      )).toList(),
                      onChanged: selectedGroup == null ? null : (val) => setDialogState(() => selectedLevel = val),
                    ),
                    const SizedBox(height: 16),
                    // Deadline Picker
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 23, minute: 59),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedDeadline = DateTime(
                                date.year, date.month, date.day,
                                time.hour, time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedDeadline != null ? AppColors.primary : AppColors.border, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: selectedDeadline != null ? AppColors.primary : AppColors.mutedForeground),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedDeadline != null
                                    ? 'Deadline: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}  ${selectedDeadline!.hour}:${selectedDeadline!.minute.toString().padLeft(2, '0')}'
                                    : 'Select Deadline',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedDeadline != null ? AppColors.text : AppColors.mutedForeground,
                                  fontWeight: selectedDeadline != null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                onPressed: (selectedGroup == null || selectedLevel == null || selectedDeadline == null) ? null : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final l10n = AppLocalizations.of(context)!;
                  final groupName = selectedGroup!.name;
                  final levelName = selectedLevel!.name;
                  Navigator.pop(ctx);
                  try {
                    await _assignmentController.addAssignment(
                      item.title,
                      type: 'central',
                      groupId: selectedGroup!.id,
                      groupName: groupName,
                      levelId: selectedLevel!.id,
                      textContent: item.content,
                      deadline: selectedDeadline,
                      curriculumItemId: item.id,
                    );
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.assignmentAssignedToGroupLevel(item.title, groupName, levelName)),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
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
                ),
                child: Text(AppLocalizations.of(context)!.assign, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
