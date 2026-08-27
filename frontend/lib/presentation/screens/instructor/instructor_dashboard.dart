
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../../logic/controllers/instructor_dashboard_controller.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';

class InstructorDashboard extends StatelessWidget {
  final VoidCallback onNavigateToAssignments;
  final VoidCallback onNavigateToGroups;

  const InstructorDashboard({
    super.key,
    required this.onNavigateToAssignments,
    required this.onNavigateToGroups,
  });

  @override
  Widget build(BuildContext context) {
    final controller = getIt<InstructorDashboardController>();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final stats = controller.stats;
        final pending = int.tryParse(stats['pendingReview'] ?? '0') ?? 0;
        final activeAssignments = controller.activeAssignments;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Current Week — Visually Striking Section ──
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primaryDark,
                          AppColors.primaryDeep,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        PositionedDirectional(
                          end: -20,
                          top: -20,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: 30,
                          bottom: -15,
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.welcomeBack,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      controller.instructorName.isNotEmpty
                                          ? controller.instructorName
                                          : AppLocalizations.of(context)!.roleInstructorLabel,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pending Alert
                  if (pending > 0)
                    GestureDetector(
                      onTap: onNavigateToAssignments,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(AppLocalizations.of(context)!.submissionsWaitingReview(pending.toString()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text))),
                            const Icon(Icons.arrow_forward, size: 14, color: AppColors.text),
                          ],
                        ),
                      ),
                    ),


                  // Stats — Clickable
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.myOverview, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 0.6)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DashboardStatGrid(
                      perRow: 2,
                      cards: [
                        DashboardStatCard(
                          icon: Icons.groups,
                          value: stats['myGroups']!,
                          label: AppLocalizations.of(context)!.statMyGroups,
                          onTap: onNavigateToGroups,
                        ),
                        DashboardStatCard(
                          icon: Icons.people,
                          value: stats['students']!,
                          label: AppLocalizations.of(context)!.statStudents,
                          gold: true,
                          onTap: onNavigateToGroups,
                        ),
                        DashboardStatCard(
                          icon: Icons.assignment,
                          value: stats['assignments']!,
                          label: AppLocalizations.of(context)!.dashboardAssignments,
                          onTap: onNavigateToAssignments,
                        ),
                        DashboardStatCard(
                          icon: Icons.pending_actions,
                          value: stats['pendingReview']!,
                          label: AppLocalizations.of(context)!.statPendingReview,
                          gold: true,
                          onTap: onNavigateToAssignments,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Active Assignments
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(AppLocalizations.of(context)!.activeAssignmentsHeader, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 0.6))),
                      GestureDetector(
                        onTap: onNavigateToAssignments,
                        child: Row(children: [
                          Text(AppLocalizations.of(context)!.seeAll, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 100),
                    child: Column(
                      children: activeAssignments.map((a) => AssignmentCard(
                        title: a.title,
                        type: a.type,
                        isActive: a.isActive,
                        deadlineText: a.deadlineText,
                        isOverdue: a.isOverdue,
                        pendingCount: a.pendingCount,
                        gradedCount: a.gradedCount,
                        groupName: a.groupName,
                        onPress: () => context.push('/assignment/${a.id}'),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
