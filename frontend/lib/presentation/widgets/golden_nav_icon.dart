import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GoldenNavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const GoldenNavIcon({super.key, required this.icon, this.active = true});

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Container(
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      );
    } else {
      return Container(
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.40),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: AppColors.accent.withValues(alpha: 0.55),
        ),
      );
    }
  }
}
