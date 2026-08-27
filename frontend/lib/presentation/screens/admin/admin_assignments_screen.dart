// ignore_for_file: experimental_member_use
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/badge.dart';
import '../../../data/models/assignment_model.dart';
import '../../../utils/level_helpers.dart';
import '../../../logic/controllers/admin_assignments_controller.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';

class AdminAssignmentsScreen extends StatefulWidget {
  const AdminAssignmentsScreen({super.key});

  @override
  State<AdminAssignmentsScreen> createState() => _AdminAssignmentsScreenState();
}

class _AdminAssignmentsScreenState extends State<AdminAssignmentsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<AssignmentModel> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAllAssignments();
    getIt<AdminAssignmentsController>().addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    getIt<AdminAssignmentsController>().removeListener(_onSearchChanged);
    super.dispose();
  }

  Future<void> _loadAllAssignments() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('assignments').get();
      final list = snapshot.docs.map((doc) => AssignmentModel.fromMap(doc.data(), doc.id)).toList();

      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _assignments = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading assignments: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text(_errorMessage, style: const TextStyle(color: AppColors.error))),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final searchQuery = getIt<AdminAssignmentsController>().searchQuery;
    final filtered = searchQuery.isEmpty
        ? _assignments
        : _assignments.where((a) {
            final q = searchQuery;
            return a.title.toLowerCase().contains(q) ||
                (a.groupName?.toLowerCase().contains(q) ?? false) ||
                levelDisplayName(a.levelId).toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
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
                              l10n.assignmentsTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_assignments.length} total assignments',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _assignments.isEmpty
                            ? 'No assignments found.'
                            : 'No results for "$searchQuery".',
                        style: const TextStyle(color: AppColors.mutedForeground),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final a = filtered[index];

                        final int total = a.totalStudents;
                        final int submitted = a.submittedCount;
                        final int correct = a.correctCount;
                        final int incorrect = a.incorrectCount;
                        final int pending = submitted - correct - incorrect;

                        final subRate = total > 0 ? (submitted / total) : 0.0;
                        final correctRate = total > 0 ? (correct / total) : 0.0;

                        return GestureDetector(
                          onTap: () => context.push('/admin/assignment/${a.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    BadgeWidget(
                                      label: a.type == 'central' ? 'CENTRAL' : 'CUSTOM',
                                      variant: a.type == 'central' ? BadgeVariant.primary : BadgeVariant.defaultVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        a.groupName ?? 'No Group',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (a.levelId != null)
                                      BadgeWidget(
                                        label: levelDisplayName(a.levelId),
                                        variant: BadgeVariant.primary,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  a.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),

                                // Submission Rate Progress Bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Submission Rate', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                                    Text('${(subRate * 100).toStringAsFixed(0)}% ($submitted/$total)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: subRate,
                                    backgroundColor: AppColors.border,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Correct Rate Progress Bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Correct Rate', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                                    Text('${(correctRate * 100).toStringAsFixed(0)}% ($correct/$total)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: correctRate,
                                    backgroundColor: AppColors.border,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Bottom details
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.pending_actions, size: 14, color: AppColors.warning),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$pending Pending Review',
                                          style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      a.deadlineText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: a.isOverdue ? AppColors.error : AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
