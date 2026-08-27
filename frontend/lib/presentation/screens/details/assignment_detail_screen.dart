// ignore_for_file: experimental_member_use
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/pdf_export_service.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/badge.dart';
import '../../widgets/vibe_premium_renderer.dart';
import '../../../data/models/submission_model.dart';
import '../../../data/models/assignment_model.dart';
import '../../../logic/controllers/assignment_detail_controller.dart';
import '../../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String id;
  final bool isAdminView;
  const AssignmentDetailScreen({super.key, required this.id, this.isAdminView = false});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late final AssignmentDetailController _controller;
  String _currentTab = 'pending'; // 'pending', 'graded', 'not_submitted'

  @override
  void initState() {
    super.initState();
    _controller = getIt<AssignmentDetailController>(param1: widget.id);
  }

  // ── Grading Bottom Sheet ───────────────────────
  void _showGradeSheet(SubmissionModel submission) {
    final feedbackCtrl = TextEditingController(text: submission.feedback ?? '');
    GradeStatus selectedStatus = submission.status == GradeStatus.pending
        ? GradeStatus.correct
        : submission.status;

    // Resolve next pending submission in list for auto-advance
    final pendingList = _controller.submissions.where((s) => s.status == GradeStatus.pending).toList();
    final currentIndex = pendingList.indexWhere((s) => s.id == submission.id);
    SubmissionModel? nextPending;
    if (currentIndex != -1 && currentIndex + 1 < pendingList.length) {
      nextPending = pendingList[currentIndex + 1];
    } else if (pendingList.isNotEmpty && pendingList.first.id != submission.id) {
      nextPending = pendingList.first;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final l10n = AppLocalizations.of(context)!;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  // Title
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.grading, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(submission.status == GradeStatus.pending ? l10n.gradeSubmission : l10n.reviseGrade, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                            Text(_controller.studentName(submission.studentId), style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status selector
                  Align(alignment: AlignmentDirectional.centerStart, child: Text(l10n.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 1))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildStatusOption(l10n.statusCorrect, GradeStatus.correct, selectedStatus, AppColors.success, setSheetState, (v) => selectedStatus = v)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatusOption(l10n.statusIncorrect, GradeStatus.incorrect, selectedStatus, AppColors.error, setSheetState, (v) => selectedStatus = v)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Feedback
                  Align(alignment: AlignmentDirectional.centerStart, child: Text(AppLocalizations.of(context)!.feedbackLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 1))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.input, width: 1.5)),
                    child: TextField(
                      controller: feedbackCtrl,
                      maxLines: 4,
                      minLines: 3,
                      decoration: InputDecoration(hintText: AppLocalizations.of(context)!.writeFeedbackHint, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, contentPadding: const EdgeInsets.all(14)),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _controller.gradeSubmission(submission.id, selectedStatus, feedbackCtrl.text.trim().isEmpty ? null : feedbackCtrl.text.trim());
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.gradeSaved), behavior: SnackBarBehavior.floating));
                        }

                        // Auto advance to next pending submission in Pending tab
                        if (_currentTab == 'pending' && nextPending != null) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              _showGradeSheet(nextPending!);
                            }
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      child: Text(AppLocalizations.of(context)!.saveGrade, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusOption(String label, GradeStatus status, GradeStatus current, Color color, void Function(void Function()) setSheetState, void Function(GradeStatus) onChanged) {
    final selected = current == status;
    return GestureDetector(
      onTap: () => setSheetState(() => onChanged(status)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 16, color: selected ? color : AppColors.mutedForeground),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? color : AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }

  // ── Shared card chrome ──────────────────────────
  Widget _card({required Widget child}) {
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

  Widget _cardHeader(String label) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark, letterSpacing: 0.6)),
      ],
    );
  }

  // ── Header block ─────────────────────────────────
  Widget _buildHeaderBlock(AssignmentModel assignment, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BadgeWidget(
          label: assignment.isActive ? l10n.statusActive : l10n.statusInactive,
          variant: assignment.isActive ? BadgeVariant.success : BadgeVariant.muted,
        ),
        const SizedBox(height: 10),
        Text(assignment.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text, height: 1.3)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            BadgeWidget(label: assignment.deadlineText, variant: assignment.isOverdue ? BadgeVariant.error : BadgeVariant.warning),
            BadgeWidget(label: assignment.groupName ?? l10n.noGroupAssigned, variant: BadgeVariant.defaultVariant),
            if (_controller.levelName.isNotEmpty) BadgeWidget(label: _controller.levelName, variant: BadgeVariant.info),
          ],
        ),
      ],
    );
  }

  // ── Position card content ────────────────────────

  /// Parses [textContent] as Quill Delta JSON and returns its ops list, or
  /// null if it isn't valid Quill JSON (e.g. plain text or empty).
  List<dynamic>? _parseQuillOps(String? textContent) {
    if (textContent == null || textContent.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(textContent);
      if (decoded is Map && decoded['ops'] is List) return decoded['ops'] as List;
      if (decoded is List) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isImageOp(dynamic op) {
    if (op is Map) {
      final insert = op['insert'];
      if (insert is Map && insert.containsKey('image')) return true;
    }
    return false;
  }

  /// Some editors store the image embed's data as a JSON-encoded string
  /// (e.g. `{"s": url, "w": 75, "a": "center"}`) instead of a plain URL.
  /// Resolves either shape down to the actual URL/data-URI source.
  String? _resolveImageSrc(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    final trimmed = raw.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded['s'] is String && (decoded['s'] as String).isNotEmpty) {
          return decoded['s'] as String;
        }
      } catch (_) {
        // fall through and try the raw string as-is
      }
    }
    return raw;
  }

  /// Returns the source (URL or data URI) of the first embedded image op in
  /// [textContent], or null if there isn't one.
  String? _firstEmbeddedImageSrc(String? textContent) {
    final ops = _parseQuillOps(textContent);
    if (ops == null) return null;
    for (final op in ops) {
      if (_isImageOp(op)) {
        final resolved = _resolveImageSrc((op['insert'] as Map)['image']);
        if (resolved != null) return resolved;
      }
    }
    return null;
  }

  /// Builds the content to feed the Instructions renderer: text ops first,
  /// then any remaining image ops. When [removeFirstImage] is true, the
  /// first embedded image op (already shown in the Position card) is
  /// dropped entirely to avoid duplication.
  String _buildInstructionsContent(String? textContent, {bool removeFirstImage = false}) {
    final fallback = textContent ?? 'No instructions provided.';
    final ops = _parseQuillOps(textContent);
    if (ops == null) return fallback;
    try {
      final textOps = <dynamic>[];
      final imageOps = <dynamic>[];
      var droppedFirstImage = false;
      for (final op in ops) {
        if (_isImageOp(op)) {
          if (removeFirstImage && !droppedFirstImage) {
            droppedFirstImage = true;
            continue;
          }
          imageOps.add(op);
        } else {
          textOps.add(op);
        }
      }
      final reordered = [...textOps, ...imageOps];
      final decoded = jsonDecode(textContent!);
      if (decoded is Map && decoded.containsKey('ops')) {
        return jsonEncode({...decoded, 'ops': reordered});
      }
      return jsonEncode(reordered);
    } catch (_) {
      return fallback;
    }
  }

  Widget _buildPositionBox(String? source) {
    if (source == null || source.isEmpty) return _buildNoImagePlaceholder();

    Widget image;
    if (source.startsWith('data:')) {
      try {
        final bytes = base64Decode(source.substring(source.indexOf(',') + 1));
        image = Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (_, _, _) => _buildNoImagePlaceholder(),
        );
      } catch (_) {
        image = _buildNoImagePlaceholder();
      }
    } else {
      image = Image.network(
        source,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          );
        },
        errorBuilder: (_, _, _) => _buildNoImagePlaceholder(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: image,
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 36, color: AppColors.mutedForeground),
          const SizedBox(height: 8),
          const Text('No image', style: TextStyle(fontSize: 13, color: AppColors.mutedForeground, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLeftCard(AssignmentModel assignment, AppLocalizations l10n) {
    final hasImageUrl = assignment.imageUrl != null && assignment.imageUrl!.isNotEmpty;
    final embeddedImageSrc = _firstEmbeddedImageSrc(assignment.textContent);
    final positionImage = hasImageUrl ? assignment.imageUrl : embeddedImageSrc;
    final instructionsContent = _buildInstructionsContent(
      assignment.textContent,
      removeFirstImage: !hasImageUrl && embeddedImageSrc != null,
    );

    final instructorName = _controller.instructorName;
    final hasInstructorName = instructorName != null && instructorName.isNotEmpty;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(assignment.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 12),
          _buildPositionBox(positionImage),
          const SizedBox(height: 24),
          _cardHeader(l10n.instructionsLabel),
          const SizedBox(height: 12),
          VibePremiumRenderer(
            content: instructionsContent,
          ),
          if (hasInstructorName) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.mutedForeground),
                const SizedBox(width: 6),
                Text('${l10n.createdByLabel} $instructorName', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
              ],
            ),
          ],
          if (assignment.assignmentType == AssignmentType.multipleChoice && assignment.choices != null) ...[
            const SizedBox(height: 24),
            _cardHeader(l10n.optionsLabel),
            const SizedBox(height: 12),
            ...assignment.choices!.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(String.fromCharCode(65 + e.key), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14, color: AppColors.text))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  // ── Overview stats card ───────────────────────────
  Widget _buildStatTile({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Overview'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatTile(icon: Icons.people_outline, value: '${_controller.totalStudentsCount}', label: 'Total Students', color: AppColors.info)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatTile(icon: Icons.check_circle_outline, value: '${_controller.submittedCount}', label: 'Submitted', color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatTile(icon: Icons.hourglass_empty, value: '${_controller.notSubmittedCount}', label: 'Not Submitted', color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatTile(icon: Icons.check_circle, value: '${_controller.correctCount}', label: 'Correct', color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatTile(icon: Icons.cancel, value: '${_controller.incorrectCount}', label: 'Incorrect', color: AppColors.error)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatTile(icon: Icons.schedule, value: '${_controller.pendingCount}', label: 'Pending', color: AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Two-column responsive section ─────────────────
  Widget _buildTwoColumnSection(AssignmentModel assignment, AppLocalizations l10n) {
    final left = _buildLeftCard(assignment, l10n);
    final right = _buildOverviewCard();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 20),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: 20),
            right,
          ],
        );
      },
    );
  }

  // ── Submissions tabs toggle (kept) ────────────────
  Widget _buildTabsToggle() {
    final pendingCount = _controller.pendingCount;
    final gradedCount = _controller.correctCount + _controller.incorrectCount;
    final notSubmittedCount = _controller.notSubmittedCount;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabSegment('Pending ($pendingCount)', 'pending')),
          Expanded(child: _buildTabSegment('Graded ($gradedCount)', 'graded')),
          Expanded(child: _buildTabSegment('Unsubmitted ($notSubmittedCount)', 'not_submitted')),
        ],
      ),
    );
  }

  Widget _buildTabSegment(String label, String tabKey) {
    final selected = _currentTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? AppColors.white : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────
  Widget _buildEmptyState(IconData icon, Color iconColor, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 36, color: iconColor),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Student resolution helpers ─────────────────────
  String? _studentEmail(String studentId) {
    final matches = _controller.groupLevelStudents.where((s) => s.id == studentId).toList();
    if (matches.isEmpty) return null;
    return matches.first.email;
  }

  Widget _avatar(String name, {double size = 32}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.accent.withValues(alpha: 0.15)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  ({Color color, String label, IconData icon}) _resultMeta(GradeStatus status, AppLocalizations l10n) {
    switch (status) {
      case GradeStatus.correct:
        return (color: AppColors.success, label: l10n.statusCorrect, icon: Icons.check_circle);
      case GradeStatus.incorrect:
        return (color: AppColors.error, label: l10n.statusIncorrect, icon: Icons.cancel);
      case GradeStatus.pending:
        return (color: AppColors.warning, label: l10n.statusPending, icon: Icons.schedule);
    }
  }

  String _formatSubmittedAt(DateTime dt, String locale) {
    return DateFormat('d MMM, HH:mm', locale).format(dt);
  }

  // ── Submissions table rows ─────────────────────────
  Widget _tableHeaderRow() {
    const headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedForeground, letterSpacing: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Student', style: headerStyle)),
          Expanded(flex: 2, child: Text('Status', style: headerStyle)),
          Expanded(flex: 2, child: Text('Result', style: headerStyle)),
          Expanded(flex: 2, child: Text('Submitted At', style: headerStyle)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _tableRow(SubmissionModel sub, AppLocalizations l10n) {
    final name = _controller.studentName(sub.studentId);
    final email = _studentEmail(sub.studentId);
    final result = _resultMeta(sub.status, l10n);
    final locale = l10n.localeName;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _avatar(name),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text), overflow: TextOverflow.ellipsis),
                      if (email != null && email.isNotEmpty)
                        Text(email, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: BadgeWidget(label: l10n.submittedLabel, variant: BadgeVariant.success)),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(result.icon, size: 14, color: result.color),
                const SizedBox(width: 4),
                Flexible(child: Text(result.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: result.color), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(_formatSubmittedAt(sub.submittedAt, locale), style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground))),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(_controller.canGrade ? Icons.edit : Icons.visibility, size: 18, color: AppColors.primary),
              tooltip: _controller.canGrade ? l10n.gradeButton : null,
              onPressed: () => _showGradeSheet(sub),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactRow(SubmissionModel sub, AppLocalizations l10n) {
    final name = _controller.studentName(sub.studentId);
    final email = _studentEmail(sub.studentId);
    final result = _resultMeta(sub.status, l10n);
    final locale = l10n.localeName;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text), overflow: TextOverflow.ellipsis),
                    if (email != null && email.isNotEmpty)
                      Text(email, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_controller.canGrade ? Icons.edit : Icons.visibility, size: 18, color: AppColors.primary),
                onPressed: () => _showGradeSheet(sub),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              BadgeWidget(label: l10n.submittedLabel, variant: BadgeVariant.success),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(result.icon, size: 13, color: result.color),
                  const SizedBox(width: 4),
                  Text(result.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: result.color)),
                ],
              ),
              Text(_formatSubmittedAt(sub.submittedAt, locale), style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notSubmittedTableRow(String name, String username, {required bool wide}) {
    final content = Row(
      children: [
        _avatar(name),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text), overflow: TextOverflow.ellipsis),
              Text('@$username', style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const BadgeWidget(label: 'Not Submitted', variant: BadgeVariant.muted),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: wide ? null : const EdgeInsets.only(bottom: 8),
      decoration: wide
          ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border)))
          : BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: wide ? content : Padding(padding: const EdgeInsets.all(2), child: content),
    );
  }

  Widget _buildSubmissionsTabBody(AppLocalizations l10n) {
    if (_currentTab == 'not_submitted') {
      final students = _controller.notSubmittedStudents;
      if (students.isEmpty) {
        return _buildEmptyState(Icons.check_circle_outline, AppColors.success, 'All submissions completed!', 'No student is missing this assignment.');
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 560;
          return Column(
            children: students.map((s) => _notSubmittedTableRow(s.name, s.username ?? '', wide: wide)).toList(),
          );
        },
      );
    }

    final list = _currentTab == 'pending'
        ? _controller.submissions.where((s) => s.status == GradeStatus.pending).toList()
        : _controller.submissions.where((s) => s.status != GradeStatus.pending).toList();

    if (list.isEmpty) {
      if (_currentTab == 'pending') {
        return _buildEmptyState(Icons.check_circle_outline, AppColors.success, AppLocalizations.of(context)!.allCaughtUp, 'All submissions have been graded.');
      }
      return _buildEmptyState(Icons.hourglass_empty, AppColors.mutedForeground, 'No graded submissions yet.', 'Submissions will appear here after they are graded.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        return Column(
          children: [
            if (wide) _tableHeaderRow(),
            ...list.map((sub) => wide ? _tableRow(sub, l10n) : _compactRow(sub, l10n)),
          ],
        );
      },
    );
  }

  Widget _buildSubmissionsCard(AppLocalizations l10n) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Student Submissions'),
          const SizedBox(height: 16),
          _buildTabsToggle(),
          const SizedBox(height: 16),
          _buildSubmissionsTabBody(l10n),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final assignment = _controller.assignment;
        final l10n = AppLocalizations.of(context)!;

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
            title: Text(l10n.assignmentDetails, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              if (!widget.isAdminView && assignment.textContent != null && assignment.textContent!.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                  tooltip: l10n.viewAsPdfTooltip,
                  onPressed: () => PdfExportService.exportAndShowPdf(
                    context,
                    assignment.title,
                    assignment.textContent!,
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderBlock(assignment, l10n),
                        const SizedBox(height: 24),
                        _buildTwoColumnSection(assignment, l10n),
                        if (!widget.isAdminView) ...[
                          const SizedBox(height: 24),
                          _buildSubmissionsCard(l10n),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
