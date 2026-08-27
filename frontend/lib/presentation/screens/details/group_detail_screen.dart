/// Presentation Tier — Screen
/// Path: lib/presentation/screens/details/group_detail_screen.dart
///
/// ✅ Zero mock data — uses GroupDetailController
/// ✅ Uses ListenableBuilder for reactivity
/// ✅ Students displayed hierarchically by academic level
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../../data/models/curriculum_model.dart';
import '../../../data/repositories/curriculum_repository.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/instructor_material_model.dart';
import '../../../data/repositories/instructor_material_repository.dart';
import '../../../logic/controllers/group_detail_controller.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../../widgets/location_picker.dart';
import '../../../utils/jerusalem_locations.dart';
import 'lesson_detail_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String id;
  const GroupDetailScreen({super.key, required this.id});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late final GroupDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<GroupDetailController>(param1: widget.id);
  }

  String _formatDate(DateTime dt, String locale) {
    return DateFormat('d MMM y', locale).format(dt);
  }

  String _localizedLastActive(DateTime? lastActive, AppLocalizations l10n) {
    if (lastActive == null) return l10n.timeNever;
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 5) return l10n.timeOnline;
    if (diff.inMinutes < 60) return l10n.timeAgoMinutes(diff.inMinutes.toString());
    if (diff.inHours < 24) return l10n.timeAgoHours(diff.inHours.toString());
    return l10n.timeAgoDays(diff.inDays.toString());
  }

  String _localizedLevelName(String levelId, AppLocalizations l10n) {
    return _controller.levels
        .firstWhere((l) => l.id == levelId, orElse: () => LevelModel(id: levelId, name: levelId))
        .name;
  }

  // ── Dialogs ──────────────────────────────

  void _showRenameGroupDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('Rename Group', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Group Name',
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
              final name = controller.text.trim();
              if (name.isNotEmpty && name != currentName) {
                Navigator.pop(ctx);
                try {
                  await _controller.renameGroup(name);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Group renamed to "$name"')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showAddLevelDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<LevelModel>>(
          future: getIt<CurriculumRepository>().getLevels(),
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const AlertDialog(
                backgroundColor: AppColors.background,
                content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              );
            }
            final availableLevels = (snap.data ?? [])
                .where((l) => !_controller.group.levelIds.contains(l.id))
                .toList();

            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Level to Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SizedBox(
                  width: double.maxFinite,
                  child: availableLevels.isEmpty
                      ? const Text('All available levels are already added to this group.', style: TextStyle(color: AppColors.mutedForeground))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableLevels.length,
                          itemBuilder: (context, index) {
                          final lvl = availableLevels[index];
                          return ListTile(
                            title: Text(lvl.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(ctx);
                                try {
                                  await _controller.addLevelToGroup(lvl.id);
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Level "${lvl.name}" added to group.')),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                                  );
                                }
                              },
                              child: const Text('Add'),
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
            );
          },
        );
      },
    );
  }

  void _showTransferStudentDialog(UserModel student) {
    final studentLevelId = student.levelId;
    if (studentLevelId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Transfer ${student.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: FutureBuilder<List<GroupModel>>(
            future: _controller.getTransferTargetGroups(studentLevelId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final groups = snapshot.data ?? [];
              if (groups.isEmpty) {
                return const Center(
                  child: Text('No other active groups found with this level.', style: TextStyle(color: AppColors.mutedForeground)),
                );
              }
              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final grp = groups[index];
                  return ListTile(
                    title: Text(grp.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        try {
                          await _controller.transferStudent(student.id, grp.id);
                          messenger.showSnackBar(
                            SnackBar(content: Text('${student.name} transferred to ${grp.name}')),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Transfer failed: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      },
                      child: const Text('Transfer'),
                    ),
                  );
                },
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

  void _showAddInstructorDialog() {
    _controller.setAvailableInstructorsSearch('');
    showDialog(
      context: context,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final available = _controller.availableInstructors;
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(AppLocalizations.of(context)!.addInstructor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                  children: [
                    _buildDialogSearchBar(
                      onChanged: _controller.setAvailableInstructorsSearch,
                      searchValue: _controller.availableInstructorsSearch,
                      onClear: () => _controller.setAvailableInstructorsSearch(''),
                    ),
                    Expanded(
                      child: available.isEmpty
                          ? Center(child: Text(AppLocalizations.of(context)!.noInstructorsFound, style: TextStyle(color: AppColors.mutedForeground)))
                          : ListView.builder(
                              itemCount: available.length,
                              itemBuilder: (context, index) {
                                final inst = available[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(inst.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(inst.email ?? '', style: const TextStyle(fontSize: 12)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      minimumSize: const Size(60, 30),
                                    ),
                                    onPressed: () => _controller.addInstructor(inst.id),
                                    child: Text(AppLocalizations.of(context)!.addButton),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.closeButton, style: TextStyle(color: AppColors.mutedForeground)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddStudentDialog() {
    _controller.setAvailableStudentsSearch('');
    _controller.clearBulkSelection();
    String globalLevel = _controller.levels.isNotEmpty ? _controller.levels.first.id : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final available = _controller.availableStudents
                .where((s) => s.levelId == globalLevel)
                .toList();
            final selCount = _controller.bulkSelectionCount;
            final l10n = AppLocalizations.of(context)!;
            final levelName = _controller.levels
                .firstWhere((l) => l.id == globalLevel, orElse: () => LevelModel(id: globalLevel, name: globalLevel))
                .name;

            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(l10n.addStudent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 460,
                  child: Column(
                  children: [
                    // Create New Student card
                    GestureDetector(
                      onTap: () { Navigator.pop(ctx); _showCreateStudentDialog(); },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          Icon(Icons.person_add, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l10n.createNewStudent, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            Text(l10n.generateCredentialsAuto, style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                          ])),
                          Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                        ]),
                      ),
                    ),
                    // Global level dropdown
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(l10n.assignSelectedToLevel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground)),
                          const Spacer(),
                          DropdownButton<String>(
                            value: globalLevel,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(12),
                            icon: const Icon(Icons.expand_more, size: 16, color: AppColors.mutedForeground),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                            items: _controller.levels.map((l) =>
                              DropdownMenuItem(
                                value: l.id,
                                child: Text(l.name),
                              ),
                            ).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                _controller.clearBulkSelection();
                                setDialogState(() => globalLevel = v);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildDialogSearchBar(
                      onChanged: _controller.setAvailableStudentsSearch,
                      searchValue: _controller.availableStudentsSearch,
                      onClear: () => _controller.setAvailableStudentsSearch(''),
                    ),
                    if (selCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l10n.nSelected(selCount.toString()),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: available.isEmpty
                          ? Center(child: Text(l10n.noStudentsFound, style: TextStyle(color: AppColors.mutedForeground)))
                          : ListView.builder(
                              itemCount: available.length,
                              itemBuilder: (context, index) {
                                final student = available[index];
                                final isSelected = _controller.bulkSelectedStudentIds.contains(student.id);
                                final currentGroupName = student.groupId != null ? _controller.getGroupName(student.groupId) : null;
                                return _BulkSelectStudentTile(
                                  student: student,
                                  isSelected: isSelected,
                                  onToggle: () => _controller.toggleBulkStudent(student.id),
                                  currentGroupName: currentGroupName,
                                );
                              },
                            ),
                    ),
                  ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.closeButton, style: const TextStyle(color: AppColors.mutedForeground)),
                ),
                if (selCount > 0)
                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final preAssignedStudents = _controller.availableStudents
                          .where((s) => _controller.bulkSelectedStudentIds.contains(s.id) && s.groupId != null)
                          .toList();

                      if (preAssignedStudents.isNotEmpty) {
                        final proceed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Confirm Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500),
                                child: Text(
                                  'The following student(s) are already in other groups:\n'
                                  '${preAssignedStudents.map((s) => '• ${s.name} (in ${_controller.getGroupName(s.groupId) ?? "Unknown"})').join('\n')}\n\n'
                                  'Adding them to this group will automatically transfer them. Proceed?'
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
                                child: const Text('Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (proceed != true) return;
                      }

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      try {
                        await _controller.bulkAddStudents(globalLevel);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Students added successfully')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(l10n.addNStudentsToLevel(selCount.toString(), levelName), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        ),
      ),
    ).whenComplete(() => _controller.clearBulkSelection());
  }

  void _showCreateStudentDialog() {
    final rows = [_CreateStudentRow()];
    final batchUsernames = <String>{};
    String selectedLevel = _controller.levels.isNotEmpty ? _controller.levels.first.id : '';
    bool isCreating = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final l10n = AppLocalizations.of(context)!;

          bool validate() {
            bool valid = true;
            for (final row in rows) {
              row.nameError = null;
              row.usernameError = null;

              if (row.nameCtrl.text.trim().isEmpty) {
                row.nameError = l10n.requiredFieldError;
                valid = false;
              }

              final u = row.usernameCtrl.text.trim();
              if (u.isEmpty) {
                row.usernameError = l10n.requiredFieldError;
                valid = false;
              } else if (u.contains(' ') || u != u.toLowerCase()) {
                row.usernameError = l10n.usernameFormatError;
                valid = false;
              }
            }
            return valid;
          }

          return AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            title: Row(children: [
              Icon(Icons.group_add, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(l10n.bulkCreateTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    l10n.assignToLevel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _controller.levels.map((l) {
                      final sel = selectedLevel == l.id;
                      return GestureDetector(
                        onTap: isCreating ? null : () => setDialogState(() => selectedLevel = l.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(
                            l.name,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.mutedForeground),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: rows.asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      return _buildStudentFormRow(
                        row: row,
                        canRemove: rows.length > 1,
                        enabled: !isCreating,
                        batchUsernames: batchUsernames,
                        onRemove: () => setDialogState(() {
                          batchUsernames.remove(row.usernameCtrl.text);
                          row.dispose();
                          rows.removeAt(i);
                        }),
                        onChange: () => setDialogState(() {}),
                      );
                    }).toList(),
                  ),
                  if (!isCreating)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: TextButton.icon(
                        onPressed: () => setDialogState(() => rows.add(_CreateStudentRow())),
                        icon: const Icon(Icons.add, size: 15),
                        label: Text(l10n.addAnotherStudentLabel, style: const TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancelButton, style: TextStyle(color: AppColors.mutedForeground)),
            ),
              ElevatedButton(
                onPressed: isCreating ? null : () async {
                  if (!validate()) {
                    setDialogState(() {});
                    return;
                  }
                  // Duplicate username check
                  bool hasDupe = false;
                  for (final row in rows) {
                    final exists = await _controller.usernameExists(row.usernameCtrl.text.trim());
                    if (exists) {
                      row.usernameError = l10n.usernameAlreadyTaken;
                      hasDupe = true;
                    }
                  }
                  if (hasDupe) {
                    setDialogState(() {});
                    return;
                  }
                  setDialogState(() => isCreating = true);
                  try {
                    final createdUsers = <UserModel>[];
                    for (final row in rows) {
                      final user = await _controller.createStudent(
                        row.nameCtrl.text.trim(),
                        selectedLevel,
                        username: row.usernameCtrl.text.trim(),
                        pinCode: row.pin,
                        gender: row.gender,
                        dateOfBirth: row.dateOfBirth,
                        location: row.location?.en,
                      );
                      createdUsers.add(user);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted && createdUsers.isNotEmpty) {
                      _showCredentialsDialog(createdUsers);
                    }
                  } catch (e) {
                    setDialogState(() => isCreating = false);
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                        content: Text(l10n.failedToCreateStudent(e.toString())),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 6),
                      ));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isCreating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        rows.length <= 1 ? l10n.createButton : l10n.createNStudents(rows.length.toString()),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        for (final row in rows) {
          row.dispose();
        }
      });
      batchUsernames.clear();
    });
  }

  Widget _buildStudentFormRow({
    required _CreateStudentRow row,
    required bool canRemove,
    required bool enabled,
    required Set<String> batchUsernames,
    required VoidCallback onRemove,
    required VoidCallback onChange,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + remove button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.nameCtrl,
                  enabled: enabled,
                  onChanged: (val) async {
                    onChange();
                    final parts = val.trim().toLowerCase().split(' ');
                    final first = parts.first.replaceAll(RegExp(r'[^a-z]'), '');
                    if (first.isEmpty) return;
                    batchUsernames.remove(row.usernameCtrl.text);
                    final resolved = await _resolveUniqueUsername(val, batchUsernames);
                    batchUsernames.add(resolved);
                    row.usernameCtrl.text = resolved;
                    onChange();
                  },
                  decoration: InputDecoration(
                    labelText: l10n.fullNameLabel,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: row.nameError != null ? AppColors.error : AppColors.input),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorText: row.nameError,
                    errorStyle: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              if (canRemove) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: enabled ? onRemove : null,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Gender Selector
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _buildGenderSelector(
            selectedGender: row.gender,
            onChanged: (val) {
              row.gender = val;
              onChange();
            },
          ),
          const SizedBox(height: 8),
          // Date of Birth Field
          _buildDateOfBirthField(
            selectedDob: row.dateOfBirth,
            onTap: () async {
              final picked = await showDialog<DateTime>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Select Year of Birth'),
                    content: SizedBox(
                      width: 300,
                      height: 300,
                      child: YearPicker(
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                        selectedDate: row.dateOfBirth ?? DateTime(2000),
                        onChanged: (DateTime dateTime) {
                          Navigator.pop(context, dateTime);
                        },
                      ),
                    ),
                  );
                },
              );
              if (picked != null) {
                row.dateOfBirth = DateTime(picked.year, 1, 1);
                onChange();
              }
            },
          ),
          const SizedBox(height: 8),
          // Location Field
          _buildLocationField(
            selectedLocation: row.location,
            onTap: () async {
              final loc = await showLocationPicker(context);
              if (loc != null) {
                row.location = loc;
                onChange();
              }
            },
          ),
          const SizedBox(height: 8),
          // Username
          TextField(
            controller: row.usernameCtrl,
            enabled: enabled,
            onChanged: (_) => onChange(),
            decoration: InputDecoration(
              labelText: l10n.usernameHint,
              hintText: 'ali.hassan',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: row.usernameError != null ? AppColors.error : AppColors.input),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorText: row.usernameError,
              errorStyle: const TextStyle(fontSize: 10),
            ),
          ),
          const SizedBox(height: 8),
          // Read-only PIN bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 14, color: AppColors.mutedForeground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.pinLabel}: ${row.pin}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                if (enabled)
                  Tooltip(
                    message: 'Regenerate PIN',
                    child: GestureDetector(
                      onTap: () {
                        row.regeneratePin();
                        onChange();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.refresh, size: 14, color: AppColors.mutedForeground),
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

  void _showCredentialsDialog(List<UserModel> users) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  users.length == 1 ? l10n.studentAdded : l10n.studentsCreatedBulk(users.length.toString()),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Important: Save the PIN below. For security reasons, it will not be shown again.',
                  style: TextStyle(fontSize: 13, color: AppColors.mutedForeground, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (_, index) => const Divider(height: 20),
                    itemBuilder: (context, idx) {
                      final u = users[idx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.loginUsernameLabel}: ${u.username}',
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${l10n.pinLabel}: ${u.pinCode}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 2,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: u.pinCode ?? ''));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.pinCopiedToClipboard),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                )
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ],
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.iHaveSavedPin, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResetPinDialog(UserModel student) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.resetPinConfirm, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(l10n.resetPinConfirmDesc(student.name)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelButton, style: const TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.resetPin, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final newPin = await _controller.resetStudentPin(student.id);
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(28),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_reset, size: 28, color: AppColors.accentDark),
                ),
                const SizedBox(height: 14),
                Text(AppLocalizations.of(context)!.pinResetTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(AppLocalizations.of(context)!.newPinForStudent(student.name), style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        newPin,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined, color: AppColors.primary),
                        tooltip: 'Copy PIN',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: newPin));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PIN copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(AppLocalizations.of(context)!.doneButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
              ]),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToResetPin(e.toString())),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String> _resolveUniqueUsername(String fullName, Set<String> batchUsernames) async {
    final cleanName = fullName.trim().toLowerCase();
    if (cleanName.isEmpty) return '';

    final parts = cleanName.split(RegExp(r'\s+'));
    final first = parts.first.replaceAll(RegExp(r'[^a-z]'), '');
    final last = parts.length > 1
        ? parts.last.replaceAll(RegExp(r'[^a-z]'), '')
        : '';
    if (first.isEmpty) return '';

    if (last.isEmpty) {
      if (!batchUsernames.contains(first) && !(await _controller.usernameExists(first))) return first;
      int n = 1;
      while (batchUsernames.contains('$first$n') || await _controller.usernameExists('$first$n')) { n++; }
      return '$first$n';
    }

    for (int i = 1; i <= last.length; i++) {
      final candidate = '$first.${last.substring(0, i)}';
      if (!batchUsernames.contains(candidate) && !(await _controller.usernameExists(candidate))) return candidate;
    }

    final base = '$first.$last';
    int n = 1;
    while (batchUsernames.contains('$base$n') || await _controller.usernameExists('$base$n')) { n++; }
    return '$base$n';
  }

  Widget _buildLocationField({
    required JerusalemLocation? selectedLocation,
    required VoidCallback onTap,
    String? hint,
  }) {
    final langCode = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedLocation != null
                    ? selectedLocation.name(langCode)
                    : hint ?? 'Location (optional)',
                style: TextStyle(
                  fontSize: 14,
                  color: selectedLocation != null ? AppColors.text : AppColors.mutedForeground,
                ),
              ),
            ),
            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField({
    required DateTime? selectedDob,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedDob != null
                    ? selectedDob.year.toString()
                    : 'Year of Birth (optional)',
                style: TextStyle(
                  fontSize: 14,
                  color: selectedDob != null ? AppColors.text : AppColors.mutedForeground,
                ),
              ),
            ),
            const Icon(Icons.calendar_today, size: 16, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector({
    required String? selectedGender,
    required void Function(String) onChanged,
  }) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'male', label: Text('Male'), icon: Icon(Icons.male)),
        ButtonSegment(value: 'female', label: Text('Female'), icon: Icon(Icons.female)),
      ],
      selected: {selectedGender ?? 'male'},
      onSelectionChanged: (val) => onChanged(val.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.12),
        selectedForegroundColor: AppColors.primary,
      ),
    );
  }

  /// Shared search bar widget used inside both Add dialogs.
  Widget _buildDialogSearchBar({
    required ValueChanged<String> onChanged,
    required String searchValue,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFc4b8da), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 15, color: AppColors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(hintText: AppLocalizations.of(context)!.searchByNameUsername,
                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontSize: 14, color: AppColors.text),
            ),
          ),
          if (searchValue.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 15, color: AppColors.mutedForeground),
            ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final l10n = AppLocalizations.of(context)!;
        final locale = l10n.localeName;
        final group = _controller.group;
        final instructors = _controller.groupInstructors;
        final studentsByLevel = _controller.studentsByLevel;
        final totalStudents = _controller.allGroupStudents.length;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.text),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(AppLocalizations.of(context)!.groupDetails, style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              if (_controller.currentUserRole == UserRole.admin)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text(AppLocalizations.of(context)!.deleteGroup, style: const TextStyle(fontWeight: FontWeight.bold)),
                          content: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Text(AppLocalizations.of(context)!.deleteGroupConfirm(group.name)),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancelButton, style: const TextStyle(color: AppColors.mutedForeground))),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _controller.deleteGroup();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.groupDeleted(group.name)), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
                                }
                              },
                              child: Text(AppLocalizations.of(context)!.deleteButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                    label: Text(AppLocalizations.of(context)!.deleteGroup, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // ── Hero Card ──
                  Container(
                    margin: const EdgeInsets.all(16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 5, color: AppColors.primary),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                      ),
                                      child: const Icon(Icons.groups, color: AppColors.primary, size: 30),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(child: Text(group.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text))),
                                              if (_controller.currentUserRole == UserRole.admin) ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                                  onPressed: () => _showRenameGroupDialog(group.name),
                                                  constraints: const BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // Level badges
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: group.levelIds.map((levelId) {
                                              final label = _localizedLevelName(levelId, l10n);
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.people, size: 12, color: AppColors.primary),
                                              const SizedBox(width: 4),
                                              Text('$totalStudents', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(l10n.totalMembersLabel, style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: AppColors.mutedForeground),
                                    const SizedBox(width: 6),
                                    Text(l10n.createdOnLabel(_formatDate(group.createdAt, locale)), style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                                  ],
                                ),
                                const Divider(height: 24, color: AppColors.border),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.push('/group-report/${group.id}'),
                                    icon: const Icon(Icons.assessment_outlined, size: 18),
                                    label: const Text('View Group Report Card', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
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

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final isAdmin = _controller.currentUserRole == UserRole.admin;

                      // ── Levels Card ──
                      final levelsCard = _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Levels', onAdd: isAdmin ? _showAddLevelDialog : null),
                            const SizedBox(height: 12),
                            if (group.levelIds.isEmpty)
                              const Text('No levels assigned to this group.', style: TextStyle(color: AppColors.mutedForeground))
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: group.levelIds.map((levelId) {
                                  final label = _localizedLevelName(levelId, l10n);
                                  return InputChip(
                                    label: Text(label),
                                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                                    deleteIconColor: AppColors.error,
                                    onDeleted: isAdmin
                                        ? () async {
                                            try {
                                              await _controller.removeLevelFromGroup(levelId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Level "$label" removed.')),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                showDialog(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    backgroundColor: AppColors.background,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    title: const Text('Cannot Remove Level', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                                                    content: SingleChildScrollView(
                                                      child: ConstrainedBox(
                                                        constraints: const BoxConstraints(maxWidth: 500),
                                                        child: Text(e.toString().replaceAll('Exception: ', '')),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(c),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        : null,
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );

                      // ── Instructors Card (admin only) ──
                      final instructorsCard = isAdmin
                          ? _buildSectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(l10n.instructorsSectionTitle, onAdd: _showAddInstructorDialog),
                                  const SizedBox(height: 12),
                                  if (instructors.isEmpty)
                                    Text(AppLocalizations.of(context)!.noInstructorsAssigned, style: const TextStyle(color: AppColors.mutedForeground))
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: instructors.length,
                                      itemBuilder: (context, index) {
                                        final inst = instructors[index];
                                        return _buildUserCard(
                                          user: inst,
                                          avatarColor: AppColors.accent.withValues(alpha: 0.2),
                                          avatarTextColor: AppColors.accentDark,
                                          onRemove: () => _controller.removeInstructor(inst.id),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            )
                          : null;

                      // ── Students Card ──
                      final studentsCard = _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(l10n.studentsSectionTitle, onAdd: _showAddStudentDialog),
                            const SizedBox(height: 12),

                            // Search Bar + Level Filter
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFc4b8da), width: 1.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.search, size: 15, color: AppColors.mutedForeground),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            onChanged: (val) => _controller.setSearch(val),
                                            decoration: InputDecoration(
                                              hintText: AppLocalizations.of(context)!.searchByNameUsername,
                                              border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false,
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        if (_controller.search.isNotEmpty)
                                          GestureDetector(
                                            onTap: () => _controller.setSearch(''),
                                            child: const Icon(Icons.close, size: 15, color: AppColors.mutedForeground),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (group.levelIds.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFc4b8da), width: 1.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: DropdownButton<String?>(
                                      value: _controller.selectedLevelFilter,
                                      underline: const SizedBox.shrink(),
                                      isDense: true,
                                      icon: const Icon(Icons.expand_more, size: 16, color: AppColors.mutedForeground),
                                      style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w600),
                                      items: [
                                        DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text(l10n.allLevels),
                                        ),
                                        ...group.levelIds.map((levelId) => DropdownMenuItem<String?>(
                                          value: levelId,
                                          child: Text(_localizedLevelName(levelId, l10n)),
                                        )),
                                      ],
                                      onChanged: (val) => _controller.setLevelFilter(val),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Students grouped by Level
                            if (studentsByLevel.isEmpty)
                              EmptyState(icon: Icons.search_off, title: AppLocalizations.of(context)!.noStudentsInGroup, subtitle: AppLocalizations.of(context)!.addStudentsOrSearch)
                            else
                              ...studentsByLevel.entries.map((entry) {
                                final levelId = entry.key;
                                final students = entry.value;
                                final levelLabel = _localizedLevelName(levelId, l10n);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Level sub-header
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              levelLabel,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.3),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(l10n.studentsCount(students.length.toString()), style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                                        ],
                                      ),
                                    ),

                                    // Student cards for this level
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: students.length,
                                      itemBuilder: (context, index) {
                                        final student = students[index];
                                        return _buildUserCard(
                                          user: student,
                                          avatarColor: AppColors.primary.withValues(alpha: 0.1),
                                          avatarTextColor: AppColors.primary,
                                          onRemove: () => _controller.removeStudent(student.id),
                                          isStudent: true,
                                        );
                                      },
                                    ),
                                  ],
                                );
                              }),
                          ],
                        ),
                      );

                      // ── Materials Card ──
                      final materialsCard = _buildSectionCard(child: _buildGroupMaterialsSection(group.id));

                      if (isWide) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    levelsCard,
                                    const SizedBox(height: 16),
                                    studentsCard,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (instructorsCard != null) ...[
                                      instructorsCard,
                                      const SizedBox(height: 16),
                                    ],
                                    materialsCard,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            levelsCard,
                            const SizedBox(height: 16),
                            if (instructorsCard != null) ...[
                              instructorsCard,
                              const SizedBox(height: 16),
                            ],
                            studentsCard,
                            const SizedBox(height: 16),
                            materialsCard,
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Reusable Widgets ──────────────────────────────

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Row(
      children: [
        Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 0.6))),
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 14),
            label: Text(AppLocalizations.of(context)!.addButton, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }

  Widget _buildUserCard({
    required dynamic user,
    required Color avatarColor,
    required Color avatarTextColor,
    required VoidCallback onRemove,
    bool isStudent = false,
  }) {
    final name = user.name as String;
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (parts.isNotEmpty && parts[0].length >= 2 ? parts[0].substring(0, 2).toUpperCase() : '??');

    final UserModel? studentUser = isStudent ? (user as UserModel) : null;
    final bool online = studentUser?.isOnline ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: avatarColor,
                foregroundColor: avatarTextColor,
                radius: 20,
                child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              if (isStudent)
                PositionedDirectional(end: 0, bottom: 0, child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: online ? AppColors.success : AppColors.mutedForeground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                )),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text), overflow: TextOverflow.ellipsis)),
                  if (studentUser?.studentNumber != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(studentUser!.studentNumber!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  if (studentUser?.username != null)
                    Text('@${studentUser!.username}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  if (isStudent) ...[
                    const Text('  ·  ', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                    Icon(Icons.circle, size: 6, color: online ? AppColors.success : AppColors.mutedForeground),
                    const SizedBox(width: 3),
                    Text(_localizedLastActive(studentUser?.lastActive, AppLocalizations.of(context)!), style: TextStyle(fontSize: 11, color: online ? AppColors.success : AppColors.mutedForeground, fontWeight: online ? FontWeight.w600 : FontWeight.normal)),
                  ],
                  if (!isStudent)
                    Text(user.email as String, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                ]),
              ],
            ),
          ),
          if (isStudent)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.mutedForeground),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'reset') _showResetPinDialog(studentUser!);
                if (val == 'transfer') _showTransferStudentDialog(studentUser!);
                if (val == 'remove') onRemove();
                if (val == 'delete') _showDeleteStudentConfirmation(studentUser!);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'reset', child: Row(children: [const Icon(Icons.lock_reset, size: 16, color: AppColors.primary), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.resetPin)])),
                if (_controller.currentUserRole == UserRole.admin)
                  const PopupMenuItem(value: 'transfer', child: Row(children: [Icon(Icons.swap_horiz, size: 16, color: AppColors.primary), SizedBox(width: 8), Text('Transfer Student')])),
                PopupMenuItem(value: 'remove', child: Row(children: [const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.warning), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.removeFromGroup)])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 16, color: AppColors.error), const SizedBox(width: 8), Text(AppLocalizations.of(context)!.deletePermanently, style: const TextStyle(color: AppColors.error))])),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.error),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  // ── Group Materials (instructor_materials) ─────────────────────────────────

  Widget _buildGroupMaterialsSection(String groupId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Materials'),
        const SizedBox(height: 12),
        FutureBuilder<List<InstructorMaterialModel>>(
          future: InstructorMaterialRepository().getGroupAllMaterials(groupId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            final materials = snap.data ?? [];
            if (materials.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 15, color: AppColors.mutedForeground),
                    SizedBox(width: 8),
                    Text(
                      'No materials created for this group yet.',
                      style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              );
            }

            // Group materials by levelId
            final byLevel = <String, List<InstructorMaterialModel>>{};
            for (final m in materials) {
              byLevel.putIfAbsent(m.levelId, () => []).add(m);
            }
            final l10n = AppLocalizations.of(context)!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: byLevel.entries.map((entry) {
                final levelId = entry.key;
                final levelName = _localizedLevelName(levelId, l10n);
                final levelMaterials = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          levelName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: levelMaterials.length,
                      itemBuilder: (context, index) =>
                          _buildGroupMaterialCard(levelMaterials[index], groupId),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGroupMaterialCard(InstructorMaterialModel m, String groupId) {
    final isAdmin = _controller.currentUserRole == UserRole.admin;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(instructorMaterial: m),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: m.isVisible ? AppColors.primary : AppColors.mutedForeground,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_stories, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.isVisible ? 'Visible to students' : 'Hidden from students',
                      style: TextStyle(
                        fontSize: 11,
                        color: m.isVisible ? AppColors.primary : AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        m.isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.mutedForeground,
                      ),
                      tooltip: m.isVisible ? 'Hide from students' : 'Show to students',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        try {
                          await InstructorMaterialRepository().toggleVisibility(m.id, m.isVisible);
                          if (mounted) setState(() {});
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => _confirmDeleteGroupMaterial(m),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteGroupMaterial(InstructorMaterialModel m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Material', style: TextStyle(fontWeight: FontWeight.bold)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text('Are you sure you want to delete "${m.title}"?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await InstructorMaterialRepository().deleteMaterial(m.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material deleted'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showDeleteStudentConfirmation(UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.deleteStudent, style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(AppLocalizations.of(context)!.deleteStudentConfirm(student.name)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final l10n = AppLocalizations.of(context)!;
              try {
                await _controller.deleteStudent(student.id);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.studentDeleted(student.name)), behavior: SnackBarBehavior.floating),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.failedToDeleteStudent(student.name, e.toString())),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.deleteButton, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Private data class: Holds form state for one student row in the create dialog ──
class _CreateStudentRow {
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  String pin = _generatePin();
  String? nameError;
  String? usernameError;
  String gender = 'male';
  DateTime? dateOfBirth;
  JerusalemLocation? location;

  static String _generatePin() =>
      (100000 + Random().nextInt(900000)).toString();

  void regeneratePin() => pin = _generatePin();

  void dispose() {
    nameCtrl.dispose();
    usernameCtrl.dispose();
  }
}

// ── Private Widget: Bulk-select student tile (checkbox + name only) ──

class _BulkSelectStudentTile extends StatelessWidget {
  final UserModel student;
  final bool isSelected;
  final VoidCallback onToggle;
  final String? currentGroupName;

  const _BulkSelectStudentTile({
    required this.student,
    required this.isSelected,
    required this.onToggle,
    this.currentGroupName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('@${student.username ?? student.studentNumber}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                  if (currentGroupName != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text('In group: $currentGroupName', style: const TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
