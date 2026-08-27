import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Flexible golden-negative-space icon for use in cards, list tiles, and section headers.
/// For nav bar pills use [GoldenNavIcon] instead.
class GoldenIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;

  const GoldenIcon({
    super.key,
    required this.icon,
    this.size = 32,
    this.iconSize = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}
