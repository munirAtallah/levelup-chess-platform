/// Presentation Tier — Screen
/// Path: lib/presentation/screens/details/student_detail_screen.dart
///
/// Displays a read-only profile for a single student. All data is sourced
/// from [StudentDetailController] which aggregates submissions, grading
/// stats, and group/level info from the repository tier.
///
/// Rendering contract:
///   - ListenableBuilder rebuilds the entire screen whenever the controller
///     emits notifyListeners() (e.g., after async load completes).
///   - While [StudentDetailController.isLoading] is true a centered spinner
///     is shown so the user is not exposed to empty/null state.
///   - Submission stats (submissions / graded / correct) come pre-aggregated
///     from [StudentProfile] — no computation happens in this widget.
library;

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/badge.dart';
import '../../../logic/controllers/student_detail_controller.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';

class StudentDetailScreen extends StatefulWidget {
  final String id;
  const StudentDetailScreen({super.key, required this.id});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late final StudentDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<StudentDetailController>(param1: widget.id);
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? AppColors.text)),
      ],
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
        final profile = _controller.profile;

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
            title: Text(AppLocalizations.of(context)!.studentDetails, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.border, height: 1),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: const Border(
                        top: BorderSide(color: AppColors.primary, width: 3),
                        right: BorderSide(color: AppColors.border),
                        bottom: BorderSide(color: AppColors.border),
                        left: BorderSide(color: AppColors.border),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(profile.initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white)),
                        ),
                        const SizedBox(height: 14),
                        Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
                        const SizedBox(height: 4),
                        Text('@${profile.username} • ${profile.studentId}', style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.layers, size: 11, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(profile.level, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11).copyWith(bottom: 24),
                    child: Row(
                      children: [
                        _buildStatBox(AppLocalizations.of(context)!.statSubmissionsLabel, profile.submissions.toString()),
                        _buildStatBox(AppLocalizations.of(context)!.statGradedLabel, profile.graded.toString()),
                        _buildStatBox(AppLocalizations.of(context)!.statCorrectLabel, profile.correct.toString()),
                      ],
                    ),
                  ),

                  // Assignment Statistics Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
                    child: Row(
                      children: [
                        Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text('Assignment Statistics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 0.6)),
                      ],
                    ),
                  ),

                  // Assignment Stats Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildStatRow('Total Assignments', '${_controller.totalAssignments}'),
                        const Divider(height: 20, color: AppColors.border),
                        _buildStatRow('Correct Submissions', '${_controller.correctCount} (${_controller.correctPercent.toStringAsFixed(1)}%)', color: AppColors.success),
                        const Divider(height: 20, color: AppColors.border),
                        _buildStatRow('Incorrect Submissions', '${_controller.incorrectCount} (${_controller.incorrectPercent.toStringAsFixed(1)}%)', color: AppColors.error),
                        const Divider(height: 20, color: AppColors.border),
                        _buildStatRow('Pending Review', '${_controller.pendingCount}', color: AppColors.warning),
                        const Divider(height: 20, color: AppColors.border),
                        _buildStatRow('Not Submitted', '${_controller.notSubmittedCount}', color: Colors.grey.shade600),
                      ],
                    ),
                  ),

                  // Account Details Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
                    child: Row(
                      children: [
                        Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text(AppLocalizations.of(context)!.accountDetails, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 0.6)),
                      ],
                    ),
                  ),

                  // Account Info Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, AppLocalizations.of(context)!.fullNameLabel, profile.name),
                        _buildInfoRow(Icons.tag, AppLocalizations.of(context)!.credUsername, profile.username),
                        _buildInfoRow(Icons.credit_card, AppLocalizations.of(context)!.studentIdLabel, profile.studentId),
                        _buildInfoRow(Icons.layers, AppLocalizations.of(context)!.profileLevelLabel, profile.level),
                        _buildInfoRow(Icons.people, AppLocalizations.of(context)!.profileGroupLabel, profile.group),
                        _buildInfoRow(Icons.lock, 'PIN', '••••'),
                      ],
                    ),
                  ),

                  // Recent Submissions Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
                    child: Row(
                      children: [
                        Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text(AppLocalizations.of(context)!.recentSubmissions, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 0.6)),
                      ],
                    ),
                  ),

                  // Submissions Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppLocalizations.of(context)!.reactFundamentalsQuiz, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                                    const SizedBox(height: 3),
                                    Text(AppLocalizations.of(context)!.reactLibraryDesc, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              BadgeWidget(label: AppLocalizations.of(context)!.statusCorrect, variant: BadgeVariant.success),
                            ],
                          ),
                        ),
                      ],
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
