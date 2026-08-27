import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/models/audit_log_model.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'audit_log_style.dart';
import 'golden_icon.dart';

class AuditLogItem extends StatelessWidget {
  final AuditLog log;

  const AuditLogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final style = AuditLogStyle.actionStyle(log);
    final hasTarget = log.targetPersonName != null && log.targetPersonName!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Golden Icon Avatar ──
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: GoldenIcon(icon: style.icon, size: 40, iconSize: 18, radius: 12),
          ),
          const SizedBox(width: 14),

          // ── Content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action title
                Text(
                  AuditLogStyle.localizeAction(log, l10n),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.3,
                  ),
                ),

                // Details (the rich description)
                if (log.details != null && log.details!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    log.details!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                      height: 1.35,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Target person row (if applicable)
                if (hasTarget) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.person, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          log.targetPersonName!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (log.targetStudentNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.targetStudentNumber!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 6),
                ],

                // Performer + Exact Date/Time — split into two rows to prevent truncation
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.performerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 10, color: AppColors.mutedForeground),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            AuditLogStyle.formatExactTime(log.preciseTimestamp, localeCode),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Relative time badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              AuditLogStyle.formatRelativeTime(log.preciseTimestamp, l10n),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
