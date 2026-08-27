import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LessonCard extends StatelessWidget {
  final String title;
  final bool isVisible;
  final List<String> searchTags;
  final VoidCallback? onPress;
  final bool showToggle;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final Widget? trailing;
  final bool hideTrailing;

  const LessonCard({
    super.key,
    required this.title,
    this.isVisible = true,
    this.searchTags = const [],
    this.onPress,
    this.showToggle = false,
    this.onToggle,
    this.onDelete,
    this.trailing,
    this.hideTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. LEADING: visibility dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isVisible ? AppColors.primary : AppColors.primary.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // 2. MAIN CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  if (searchTags.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      searchTags.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
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
                ] else if (onDelete == null && !showToggle && !hideTrailing) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.mutedForeground),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
