/// Presentation Tier — Screen
/// Path: lib/presentation/screens/instructor/groups_screen.dart
///
/// ✅ Zero mock data — groups from InstructorGroupController
/// ✅ Uses ListenableBuilder for reactivity
/// ✅ Group cards navigate to detail, show globalSequenceId
/// ✅ FloatingActionButton to add groups
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/group_card.dart';
import '../../../logic/controllers/instructor_group_controller.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';

class InstructorGroupsScreen extends StatefulWidget {
  const InstructorGroupsScreen({super.key});

  @override
  State<InstructorGroupsScreen> createState() => _InstructorGroupsScreenState();
}

class _InstructorGroupsScreenState extends State<InstructorGroupsScreen> {
  final InstructorGroupController _controller = getIt<InstructorGroupController>();

  @override
  void initState() {
    super.initState();
    // Refresh on every mount so the list stays current after admin changes or tab switches.
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.refresh());
  }

  void _showAddGroupDialog() {
    final nameController = TextEditingController();
    final selectedLevelIds = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Row(
          children: [
            const Icon(Icons.group_add, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.newGroup, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            final levels = _controller.instructorAssignedLevelIds;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.createNewGroupDesc, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.groupNameHint,
                        prefixIcon: const Icon(Icons.label_outline, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.input, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Levels', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text)),
                    const SizedBox(height: 8),
                    if (levels.isEmpty)
                      const Text('No assigned levels found.', style: TextStyle(fontSize: 12, color: AppColors.error))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: levels.map((lvlId) {
                          final isSelected = selectedLevelIds.contains(lvlId);
                          final levelLabel = AppLocalizations.of(context)!.levelLabel(lvlId.replaceAll('l', ''));
                          return FilterChip(
                            selected: isSelected,
                            label: Text(levelLabel),
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primary,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedLevelIds.add(lvlId);
                                } else {
                                  selectedLevelIds.remove(lvlId);
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancelButton, style: const TextStyle(color: AppColors.mutedForeground)),
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
                await _controller.addGroup(name, selectedLevelIds.toList());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.groupCreated(name)), behavior: SnackBarBehavior.floating),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateGroup(e.toString())), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
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
            child: Text(AppLocalizations.of(context)!.createButton, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
        if (_controller.error != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('Failed to load groups', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_controller.error!, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _controller.refresh(),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final groups = _controller.myGroups;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_instructor_groups',
            onPressed: _showAddGroupDialog,
            backgroundColor: AppColors.primary,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.myGroupsTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 4),
                      Text(AppLocalizations.of(context)!.groupsAssignedCount(groups.length.toString()), style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                    ])),
                  ]),
                ),

                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 100),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final levelLabel = group.levelIds.isEmpty
                          ? AppLocalizations.of(context)!.noLevelsAssigned
                          : group.levelIds.map((l) => AppLocalizations.of(context)!.levelLabel(l.replaceAll('l', ''))).join(' \u00b7 ');
                      return GroupCard(
                        groupName: group.name,
                        instructorsCount: group.instructorIds.length,
                        levelName: levelLabel,
                        studentsCount: group.studentIds.length,
                        onPress: () async {
                          await context.push('/group/${group.id}');
                          _controller.refresh();
                        },
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
}
