import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum BadgeVariant {
  defaultVariant,
  success,
  error,
  warning,
  info,
  muted,
  primary,
}

class BadgeWidget extends StatelessWidget {
  final String label;
  final BadgeVariant variant;

  const BadgeWidget({
    super.key,
    required this.label,
    this.variant = BadgeVariant.defaultVariant,
  });

  Color get backgroundColor {
    switch (variant) {
      case BadgeVariant.defaultVariant:
        return AppColors.tint;
      case BadgeVariant.success:
        return AppColors.success;
      case BadgeVariant.error:
        return AppColors.error;
      case BadgeVariant.warning:
        return const Color(0xFFFEF3C7);
      case BadgeVariant.info:
        return AppColors.info;
      case BadgeVariant.muted:
        return const Color(0xFFe5e2ec);
      case BadgeVariant.primary:
        return AppColors.primary;
    }
  }

  Color get foregroundColor {
    switch (variant) {
      case BadgeVariant.warning:
        return const Color(0xFF92400e);
      case BadgeVariant.muted:
        return const Color(0xFF6b7280);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}
