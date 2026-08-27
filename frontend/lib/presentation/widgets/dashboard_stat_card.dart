import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

const _kCardShadow = BoxShadow(
  color: Color(0x0D000000), // ≈ 5 % black — matches the rest of the app
  blurRadius: 8,
  spreadRadius: 0,
  offset: Offset(0, 2),
);

/// Compact icon + value + label stat card shared by the admin, instructor,
/// and student dashboards' "My Overview" sections, so the cards look
/// identical across roles regardless of how many a given role has.
class DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool gold;
  final VoidCallback? onTap;

  /// Optional "+N% from last month" pill, shown only when both are set.
  final int? trendPercent;
  final String? trendCaption;

  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.gold = false,
    this.onTap,
    this.trendPercent,
    this.trendCaption,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = gold ? AppColors.accent : AppColors.primary;
    final iconBg = gold ? AppColors.accent.withValues(alpha: 0.15) : AppColors.secondary;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [_kCardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
                          ),
                          Text(
                            label,
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (trendPercent != null && trendCaption != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_upward, size: 10, color: AppColors.success),
                            const SizedBox(width: 2),
                            Text(
                              '+$trendPercent%',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(trendCaption!, style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays out [cards] as fixed rows of [perRow] (3 by default), so the grid
/// stays the same shape at every width instead of reflowing to 1-per-row
/// on narrow/phone screens.
class DashboardStatGrid extends StatelessWidget {
  final List<DashboardStatCard> cards;
  final int perRow;
  final double gap;

  const DashboardStatGrid({super.key, required this.cards, this.perRow = 3, this.gap = 12});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectivePerRow =
            constraints.maxWidth < 500 ? perRow.clamp(1, 2) : perRow;
        final rows = <Widget>[];
        for (int i = 0; i < cards.length; i += effectivePerRow) {
          final rowCards =
              cards.sublist(i, (i + effectivePerRow).clamp(0, cards.length));
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int j = 0; j < rowCards.length; j++) ...[
                  if (j > 0) SizedBox(width: gap),
                  Expanded(child: rowCards[j]),
                ],
              ],
            ),
          );
          if (i + effectivePerRow < cards.length) rows.add(SizedBox(height: gap));
        }
        return Column(children: rows);
      },
    );
  }
}
