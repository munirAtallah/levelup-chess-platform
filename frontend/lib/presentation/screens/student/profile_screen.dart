/// Presentation Tier — Screen
/// Path: lib/presentation/screens/student/profile_screen.dart
///
///  Zero mock data — profile from StudentProfileController
///  Uses ListenableBuilder for reactivity
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../logic/controllers/student_profile_controller.dart';
import '../../../di/service_locator.dart';
import '../../widgets/golden_icon.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../../../logic/helpers/logout_helper.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
        ]),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
      child: Row(children: [
        GoldenIcon(icon: icon, size: 32, iconSize: 14, radius: 8),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
        ])),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = getIt<StudentProfileController>();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (controller.error != null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load profile details.',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final profile = controller.profile;
        final raw = profile.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
        final initials = raw.length >= 2 ? raw.substring(0, 2) : raw;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: Row(children: [
                      Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.myProfile, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                    ]),
                  ),

                  // Avatar Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Row(children: [
                      Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), alignment: Alignment.center, child: Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white))),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(profile.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text)),
                        const SizedBox(height: 2),
                        Text('${profile.studentId} · ${AppLocalizations.of(context)!.studentRoleLabel}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(20)),
                        child: Text(AppLocalizations.of(context)!.studentRoleLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.white)),
                      ),
                    ]),
                  ),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15).copyWith(bottom: 24),
                    child: Row(children: [
                      _buildStatBox(AppLocalizations.of(context)!.statSubmissionsLabel, profile.submissions.toString()),
                      _buildStatBox(AppLocalizations.of(context)!.statGradedLabel, profile.graded.toString()),
                      _buildStatBox(AppLocalizations.of(context)!.statCorrectLabel, profile.correct.toString()),
                    ]),
                  ),

                  // Account Info Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
                    child: Row(children: [
                      Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.accountInfo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 0.6)),
                    ]),
                  ),

                  // Account Info Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Column(children: [
                      _buildInfoRow(Icons.person, AppLocalizations.of(context)!.fullNameLabel, profile.name),
                      _buildInfoRow(Icons.tag, AppLocalizations.of(context)!.credUsername, profile.username),
                      _buildInfoRow(Icons.credit_card, AppLocalizations.of(context)!.studentIdLabel, profile.studentId),
                      _buildInfoRow(Icons.layers, AppLocalizations.of(context)!.profileLevelLabel, profile.level),
                      _buildInfoRow(Icons.people, AppLocalizations.of(context)!.profileGroupLabel, profile.group),
                      _buildInfoRow(Icons.school, AppLocalizations.of(context)!.roleInstructor, profile.instructorName),
                    ]),
                  ),

                  // Sign Out
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                          await performLogout();
                          if (context.mounted) context.go('/login');
                        },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.1), foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppColors.error.withValues(alpha: 0.2), width: 1.5)), elevation: 0),
                      icon: const Icon(Icons.logout, size: 16),
                      label: Text(AppLocalizations.of(context)!.signOut, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
