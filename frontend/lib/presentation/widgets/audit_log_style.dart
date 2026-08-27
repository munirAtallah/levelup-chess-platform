import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:frontend/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../data/models/audit_log_model.dart';

/// Shared action -> icon/color/label/type/time logic for audit log entries.
/// Single source of truth for [AuditLogItem] (vertical list).
class AuditLogStyle {
  const AuditLogStyle._();

  /// "12 May 2026, 14:30" (locale-aware month abbreviation).
  static String formatExactTime(DateTime ts, String localeCode) {
    return intl.DateFormat('dd MMM yyyy, HH:mm', localeCode).format(ts);
  }

  /// Relative time label — fully localized.
  static String formatRelativeTime(DateTime ts, AppLocalizations l10n) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeAgoMinutes(diff.inMinutes.toString());
    if (diff.inHours < 24) return l10n.timeAgoHours(diff.inHours.toString());
    if (diff.inDays < 7) return l10n.timeAgoDays(diff.inDays.toString());
    return l10n.timeAgoWeeks((diff.inDays ~/ 7).toString());
  }

  /// Map Firestore action strings to localized display text.
  static String localizeAction(AuditLog log, AppLocalizations l10n) {
    final a = log.action.toLowerCase();
    if (a.contains('created') && a.contains('level')) return l10n.actionCreatedLevel;
    if (a.contains('added') && a.contains('instructor')) return l10n.actionAddedInstructor;
    if (a.contains('created assignment') || a.contains('assigned from')) return l10n.actionCreatedAssignment;
    if (a.contains('revised')) return l10n.actionRevisedGrade;
    if (a.contains('graded') || a.contains('grade')) return l10n.actionGradedSubmission;
    if (a.contains('submitted')) return l10n.actionSubmittedAssignment;
    if (a.contains('added') && a.contains('student')) return l10n.actionAddedStudent;
    if (a.contains('reset') && a.contains('pin')) return l10n.actionResetPin;
    if (a.contains('joined group')) return l10n.actionJoinedGroup;
    return log.action;
  }

  /// Choose icon and color based on action content.
  static ({IconData icon, Color color}) actionStyle(AuditLog log) {
    final a = log.action.toLowerCase();
    if (a.contains('graded') || a.contains('grade')) {
      return (icon: Icons.check_circle_outline, color: const Color(0xFF22C55E));
    }
    if (a.contains('revised') || a.contains('revise')) {
      return (icon: Icons.rate_review_outlined, color: const Color(0xFFF59E0B));
    }
    if (a.contains('created assignment') || a.contains('assigned from')) {
      return (icon: Icons.assignment_outlined, color: const Color(0xFF3B82F6));
    }
    if (a.contains('added new student') || a.contains('added student')) {
      return (icon: Icons.person_add_outlined, color: const Color(0xFF8B5CF6));
    }
    if (a.contains('removed student')) {
      return (icon: Icons.person_remove_outlined, color: const Color(0xFFEF4444));
    }
    if (a.contains('reset') && a.contains('pin')) {
      return (icon: Icons.lock_reset, color: const Color(0xFFEC4899));
    }
    if (a.contains('submitted') || a.contains('submission')) {
      return (icon: Icons.file_upload_outlined, color: const Color(0xFF06B6D4));
    }
    if (a.contains('level') || a.contains('curriculum') || a.contains('content')) {
      return (icon: Icons.menu_book_outlined, color: const Color(0xFF6366F1));
    }
    if (a.contains('schedule') || a.contains('updated group')) {
      return (icon: Icons.calendar_month_outlined, color: const Color(0xFF14B8A6));
    }
    if (a.contains('joined group')) {
      return (icon: Icons.group_add_outlined, color: const Color(0xFF0EA5E9));
    }
    if (a.contains('deleted')) {
      return (icon: Icons.delete_outline, color: const Color(0xFFEF4444));
    }
    // Fallback
    switch (log.performerRole) {
      case 'admin':
        return (icon: Icons.shield, color: const Color(0xFF8B5CF6));
      case 'instructor':
        return (icon: Icons.school, color: const Color(0xFFF59E0B));
      case 'student':
      default:
        return (icon: Icons.person, color: AppColors.primary);
    }
  }

  /// Broad type badge for the horizontal timeline — derived from the
  /// canonical [AuditLog.actionCategory], not re-inferred from text.
  static ({String label, Color color}) typeInfo(AuditLog log, AppLocalizations l10n) {
    switch (log.actionCategory) {
      case 'assignments':
        return (label: l10n.badgeAssignment, color: AppColors.info);
      case 'groups':
        return (label: l10n.badgeGroup, color: AppColors.primary);
      case 'curriculum':
        return (label: l10n.badgeLesson, color: AppColors.accent);
      case 'submissions':
      case 'grading':
        return (label: l10n.badgeSubmission, color: AppColors.success);
      case 'users':
      default:
        return (label: l10n.badgeUser, color: AppColors.warning);
    }
  }
}
