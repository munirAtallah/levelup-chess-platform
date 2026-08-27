/// Presentation — Widget
/// Path: lib/presentation/widgets/statistics_filter_sheet.dart
library;

import 'package:flutter/material.dart';
import '../../di/service_locator.dart';
import '../../logic/controllers/admin_statistics_controller.dart';
import '../../theme/app_theme.dart';

/// Opens the statistics filter dialog, centered on screen.
/// Call via [showStatisticsFilterDialog].
void showStatisticsFilterDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 660),
        child: const _StatisticsFilterDialog(),
      ),
    ),
  );
}

class _StatisticsFilterDialog extends StatefulWidget {
  const _StatisticsFilterDialog();

  @override
  State<_StatisticsFilterDialog> createState() => _StatisticsFilterDialogState();
}

class _StatisticsFilterDialogState extends State<_StatisticsFilterDialog> {
  late StatisticsFilter _filter;
  late final AdminStatisticsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = getIt<AdminStatisticsController>();
    _filter = _ctrl.activeFilter;
  }

  void _update(StatisticsFilter next) {
    setState(() => _filter = next);
    _ctrl.setFilter(next);
  }

  void _clearAll() {
    _ctrl.clearFilters();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final locations = _ctrl.allLocations.toList();
    final levelEntries = _ctrl.levelNames.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final hasLevelData =
        levelEntries.isNotEmpty || _ctrl.studentsByLevel.containsKey('Unassigned');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Dialog header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              children: [
                const Text(
                  'Filter Statistics',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                if (_filter.isActive)
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.mutedForeground,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // ── Scrollable filter sections ─────────────────────────────────────
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              shrinkWrap: true,
              children: [
                // TIME PERIOD
                _sectionTitle('Time Period'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _timePeriodChip('all', 'All Time'),
                    _timePeriodChip('last7days', 'Last 7 Days'),
                    _timePeriodChip('thisMonth', 'This Month'),
                    _timePeriodChip('thisYear', 'This Year'),
                  ],
                ),
                const SizedBox(height: 24),

                // LOCATION
                if (locations.isNotEmpty) ...[
                  _sectionTitle('Location'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: locations.map((loc) {
                      final selected = _filter.locations.contains(loc);
                      return _chip(
                        label: loc,
                        selected: selected,
                        onTap: () {
                          final next = Set<String>.from(_filter.locations);
                          selected ? next.remove(loc) : next.add(loc);
                          _update(_filter.copyWith(locations: Set.unmodifiable(next)));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // LEVEL (students only)
                if (hasLevelData) ...[
                  _sectionTitle('Level  ·  Students only'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...levelEntries.map((e) {
                        final selected = _filter.levelIds.contains(e.key);
                        return _chip(
                          label: e.value,
                          selected: selected,
                          onTap: () {
                            final next = Set<String>.from(_filter.levelIds);
                            selected ? next.remove(e.key) : next.add(e.key);
                            _update(_filter.copyWith(levelIds: Set.unmodifiable(next)));
                          },
                        );
                      }),
                      if (levelEntries.isNotEmpty)
                        Builder(builder: (_) {
                          const key = 'Unassigned';
                          final selected = _filter.levelIds.contains(key);
                          return _chip(
                            label: 'Unassigned',
                            selected: selected,
                            muted: true,
                            onTap: () {
                              final next = Set<String>.from(_filter.levelIds);
                              selected ? next.remove(key) : next.add(key);
                              _update(_filter.copyWith(levelIds: Set.unmodifiable(next)));
                            },
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // GROUP STATUS (students only)
                _sectionTitle('Group Status  ·  Students only'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _radioChip(label: 'All', value: 'all'),
                    _radioChip(label: 'Assigned', value: 'assigned'),
                    _radioChip(label: 'Unassigned', value: 'unassigned'),
                  ],
                ),
                const SizedBox(height: 24),

                // GENDER
                _sectionTitle('Gender'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _genderChip('male', 'Male'),
                    _genderChip('female', 'Female'),
                    _genderChip('Not set', 'Not set', muted: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.mutedForeground,
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected
              ? AppColors.primary
              : (muted ? AppColors.mutedForeground : AppColors.text),
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
        width: selected ? 1.5 : 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: true,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _timePeriodChip(String value, String label) {
    final selected = _filter.timePeriod == value;
    return _chip(
      label: label,
      selected: selected,
      onTap: () => _update(_filter.copyWith(timePeriod: value)),
    );
  }

  Widget _radioChip({required String label, required String value}) {
    final selected = _filter.groupStatus == value;
    return _chip(
      label: label,
      selected: selected,
      onTap: () => _update(_filter.copyWith(groupStatus: value)),
    );
  }

  Widget _genderChip(String key, String label, {bool muted = false}) {
    final selected = _filter.genders.contains(key);
    return _chip(
      label: label,
      selected: selected,
      muted: muted,
      onTap: () {
        final next = Set<String>.from(_filter.genders);
        selected ? next.remove(key) : next.add(key);
        _update(_filter.copyWith(genders: Set.unmodifiable(next)));
      },
    );
  }
}
