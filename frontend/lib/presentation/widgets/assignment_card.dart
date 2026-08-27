// ignore_for_file: experimental_member_use
import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'badge.dart';

class AssignmentCard extends StatelessWidget {
  final String title;
  final String type; // 'central' or 'custom'
  final bool isActive;
  final String deadlineText;
  final bool isOverdue;
  final DateTime? deadline;
  final int pendingCount;
  final int gradedCount;
  final VoidCallback? onPress;
  final bool showGroup;
  final String? groupName;
  final VoidCallback? onDelete;
  final Widget? trailing;
  final bool isVisible;
  final bool showToggle;
  final VoidCallback? onToggle;
  final bool isAdminView;

  const AssignmentCard({
    super.key,
    required this.title,
    required this.type,
    required this.isActive,
    required this.deadlineText,
    required this.isOverdue,
    this.deadline,
    this.pendingCount = 0,
    this.gradedCount = 0,
    this.onPress,
    this.showGroup = false,
    this.groupName,
    this.onDelete,
    this.trailing,
    this.isVisible = true,
    this.showToggle = false,
    this.onToggle,
    this.isAdminView = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // 1. LEADING: active indicator bar
            if (isActive)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: Container(color: AppColors.primary),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 2. MAIN CONTENT
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isAdminView) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    BadgeWidget(
                                      label: type == 'central'
                                          ? AppLocalizations.of(context)!.centralBadgeLabel
                                          : AppLocalizations.of(context)!.customBadgeLabel,
                                      variant: type == 'central'
                                          ? BadgeVariant.info
                                          : BadgeVariant.defaultVariant,
                                    ),
                                    if (!isActive)
                                      BadgeWidget(
                                        label: AppLocalizations.of(context)!.closedBadgeLabel,
                                        variant: BadgeVariant.muted,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: () {
                                  BadgeVariant variant = BadgeVariant.info;
                                  if (isOverdue) {
                                    variant = BadgeVariant.error;
                                  } else if (deadline != null) {
                                    final diff = deadline!.difference(DateTime.now());
                                    if (diff.inHours < 24) {
                                      variant = BadgeVariant.error;
                                    } else if (diff.inDays < 3) {
                                      variant = BadgeVariant.warning;
                                    }
                                  }
                                  return BadgeWidget(
                                    label: deadlineText,
                                    variant: variant,
                                  );
                                }(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                                height: 1.42,
                              ),
                        ),
                        if (showGroup && groupName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            groupName!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                        if (isAdminView && !(showGroup && groupName != null)) ...[
                          const SizedBox(height: 3),
                          Text(
                            ' ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: Colors.transparent,
                                ),
                          ),
                        ],
                        if (!isAdminView && type != 'central' && (pendingCount > 0 || gradedCount > 0)) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!.pendingCountLabel(pendingCount.toString()),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          color: AppColors.mutedForeground,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!.gradedCountLabel(gradedCount.toString()),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          color: AppColors.mutedForeground,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 3. TRAILING ICONS
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showToggle) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onToggle,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: isVisible ? AppColors.primary : AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              isVisible ? Icons.visibility : Icons.visibility_off,
                              size: 16,
                              color: isVisible ? Colors.white : AppColors.primary.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ],
                      if (onDelete != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.delete, size: 16, color: Colors.red),
                          ),
                        ),
                      ],
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
