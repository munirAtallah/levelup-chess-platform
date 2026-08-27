/// Presentation Tier — Screen
/// Path: lib/presentation/screens/student/assignments_screen.dart
///
///  Zero mock data — assignments from StudentAssignmentController
///  Uses ListenableBuilder for reactivity
library;

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/assignment_card.dart';
import '../../../logic/controllers/student_assignment_controller.dart';
import '../../../di/service_locator.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../../widgets/badge.dart';
import '../../../data/models/submission_model.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  final StudentAssignmentController _controller = getIt<StudentAssignmentController>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final tab = _controller.tab;
        final pending = _controller.pendingAssignments;
        final submitted = _controller.submittedAssignments;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.myTasks, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 4),
                    Text('${_controller.pendingCount} pending • ${_controller.submittedCount} submitted', style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                  ]),
                ),

// Tab Toggle
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 14),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _controller.switchTab('pending'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: tab == 'pending' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Active (${_controller.pendingCount})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: tab == 'pending' ? AppColors.white : AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _controller.switchTab('submitted'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: tab == 'submitted' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'History (${_controller.submittedCount})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: tab == 'submitted' ? AppColors.white : AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: tab == 'pending'
                      ? (pending.isEmpty
                          ? EmptyState(
                              icon: Icons.check_circle,
                              title: AppLocalizations.of(context)!.noPendingTasks,
                              subtitle: AppLocalizations.of(context)!.allCaughtUp,
                            )
                          : ListView.builder(
                              padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 100),
                              itemCount: pending.length,
                              itemBuilder: (context, index) {
                                final a = pending[index];
                                final sub = _controller.getSubmissionForAssignment(a.id);
                                
                                Widget statusBadge;
                                if (sub == null) {
                                  statusBadge = const BadgeWidget(
                                    label: 'Not Submitted',
                                    variant: BadgeVariant.muted,
                                  );
                                } else {
                                  statusBadge = const BadgeWidget(
                                    label: 'Pending Review',
                                    variant: BadgeVariant.warning,
                                  );
                                }

                                return AssignmentCard(
                                  title: a.title,
                                  type: a.type,
                                  isActive: a.isActive,
                                  isOverdue: a.isOverdue,
                                  deadlineText: a.deadlineText,
                                  deadline: a.deadline,
                                  groupName: a.groupName,
                                  pendingCount: a.pendingCount,
                                  trailing: statusBadge,
                                  onPress: () {
                                    context.push('/student-assignment/${a.id}', extra: a);
                                  },
                                );
                              },
                            ))
                      : (submitted.isEmpty
                          ? EmptyState(
                              icon: Icons.history,
                              title: AppLocalizations.of(context)!.noSubmittedTasks,
                              subtitle: AppLocalizations.of(context)!.submitFirstAssignment,
                            )
                          : ListView.builder(
                              padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 100),
                              itemCount: submitted.length,
                              itemBuilder: (context, index) {
                                final a = submitted[index];
                                final sub = _controller.getSubmissionForAssignment(a.id);

                                Widget statusBadge;
                                if (sub == null) {
                                  statusBadge = const BadgeWidget(
                                    label: 'Not Submitted',
                                    variant: BadgeVariant.muted,
                                  );
                                } else if (sub.status == GradeStatus.correct) {
                                  statusBadge = const BadgeWidget(
                                    label: 'Correct',
                                    variant: BadgeVariant.success,
                                  );
                                } else {
                                  statusBadge = const BadgeWidget(
                                    label: 'Incorrect',
                                    variant: BadgeVariant.error,
                                  );
                                }

                                return AssignmentCard(
                                  title: a.title,
                                  type: a.type,
                                  isActive: a.isActive,
                                  isOverdue: a.isOverdue,
                                  deadlineText: a.deadlineText,
                                  deadline: a.deadline,
                                  groupName: a.groupName,
                                  pendingCount: a.pendingCount,
                                  trailing: statusBadge,
                                  onPress: () {
                                    context.push('/student-assignment/${a.id}', extra: a);
                                  },
                                );
                              },
                            )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
