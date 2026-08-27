library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/instructor_material_model.dart';
import '../../../data/repositories/instructor_material_repository.dart';
import '../../../logic/controllers/student_dashboard_controller.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../details/lesson_detail_screen.dart';

class StudentDashboard extends StatefulWidget {
  final VoidCallback onNavigateToAssignments;
  final VoidCallback onNavigateToNotifications;

  const StudentDashboard({
    super.key,
    required this.onNavigateToAssignments,
    required this.onNavigateToNotifications,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final StudentDashboardController _controller =
      getIt<StudentDashboardController>();
  final InstructorMaterialRepository _materialRepo =
      InstructorMaterialRepository();

  Future<List<InstructorMaterialModel>>? _materialsFuture;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final groupId = data['groupId'] as String?;
    final levelId = data['levelId'] as String?;

    if (groupId == null || groupId.isEmpty) return;
    if (levelId == null || levelId.isEmpty) return;

    if (mounted) {
      setState(() {
        _materialsFuture =
            _materialRepo.getGroupMaterials(groupId, levelId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── GREETING BANNER ──
                  Container(
                    margin:
                        const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        PositionedDirectional(
                          end: -20,
                          top: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: 30,
                          bottom: -15,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.welcomeBack,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _controller.studentName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _bannerChip(
                                      _controller.levelLabel,
                                      Icons.trending_up_rounded),
                                  if (_controller.groupLabel != '—' &&
                                      _controller.groupLabel.isNotEmpty)
                                    _bannerChip(
                                        _controller.groupLabel,
                                        Icons.group_rounded),
                                  if (_controller.instructorName != '—' &&
                                      _controller.instructorName.isNotEmpty)
                                    _bannerChip(
                                        '${AppLocalizations.of(context)!.roleInstructor}: ${_controller.instructorName}',
                                        Icons.person_rounded),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── LATEST NOTIFICATION BAR ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _controller.latestNotification != null
                            ? AppColors.accent.withValues(alpha: 0.08)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _controller.latestNotification != null
                              ? AppColors.accent.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: widget.onNavigateToNotifications,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                _controller.latestNotification != null
                                    ? Icons.campaign_rounded
                                    : Icons.notifications_none_rounded,
                                color: _controller.latestNotification != null
                                    ? AppColors.accentDark
                                    : AppColors.mutedForeground,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _controller.latestNotification != null
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _controller.latestNotification!.title,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.text,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _controller.latestNotification!.body,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.mutedForeground,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      )
                                    : Text(
                                        l10n.noNotifications,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.mutedForeground,
                                        ),
                                      ),
                              ),
                              if (_controller.latestNotification != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _controller.latestNotification!.time,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppColors.mutedForeground,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── MY OVERVIEW ──
                  _sectionHeader(l10n.myOverview),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DashboardStatGrid(
                      perRow: 2,
                      cards: [
                        DashboardStatCard(
                          icon: Icons.assignment,
                          value: '${_controller.tasksDue}',
                          label: l10n.navTasks,
                          onTap: widget.onNavigateToAssignments,
                        ),
                        DashboardStatCard(
                          icon: Icons.pending_actions,
                          value: '${_controller.pendingReviewCount}',
                          label: l10n.statPendingReview,
                          gold: true,
                          onTap: widget.onNavigateToAssignments,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── MY MATERIALS ──
                  _sectionHeader('My Materials'),
                  const SizedBox(height: 12),
                  _buildMaterialsSection(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── My Materials section ──────────────────────────────────────────────────

  Widget _buildMaterialsSection() {
    if (_materialsFuture == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _emptyMaterials(),
      );
    }

    return FutureBuilder<List<InstructorMaterialModel>>(
      future: _materialsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2)),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Could not load materials.',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.mutedForeground),
            ),
          );
        }
        final materials = snap.data ?? [];
        if (materials.isEmpty) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: _emptyMaterials(),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding:
              const EdgeInsets.symmetric(horizontal: 20),
          itemCount: materials.length,
          itemBuilder: (context, i) =>
              _buildMaterialCard(materials[i]),
        );
      },
    );
  }

  Widget _buildMaterialCard(InstructorMaterialModel m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LessonDetailScreen(instructorMaterial: m),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_stories,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(m.createdAt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyMaterials() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: AppColors.mutedForeground),
          SizedBox(width: 8),
          Text(
            'No materials yet',
            style: TextStyle(
                fontSize: 13, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _bannerChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 5),
          Text(
            _capitalize(label),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
