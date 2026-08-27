/// Logic Tier — View Model
/// Path: lib/logic/models/statistics_filter.dart
library;

class StatisticsFilter {
  final Set<String> locations;
  final Set<String> levelIds;
  final Set<String> genders;

  /// 'all' | 'assigned' | 'unassigned'
  final String groupStatus;

  /// 'all' | 'last7days' | 'thisMonth' | 'thisYear'
  final String timePeriod;

  const StatisticsFilter({
    required this.locations,
    required this.levelIds,
    required this.genders,
    required this.groupStatus,
    required this.timePeriod,
  });

  static const empty = StatisticsFilter(
    locations: {},
    levelIds: {},
    genders: {},
    groupStatus: 'all',
    timePeriod: 'all',
  );

  bool get isActive =>
      locations.isNotEmpty ||
      levelIds.isNotEmpty ||
      genders.isNotEmpty ||
      groupStatus != 'all' ||
      timePeriod != 'all';

  int get activeCount =>
      (locations.isNotEmpty ? 1 : 0) +
      (levelIds.isNotEmpty ? 1 : 0) +
      (genders.isNotEmpty ? 1 : 0) +
      (groupStatus != 'all' ? 1 : 0) +
      (timePeriod != 'all' ? 1 : 0);

  StatisticsFilter copyWith({
    Set<String>? locations,
    Set<String>? levelIds,
    Set<String>? genders,
    String? groupStatus,
    String? timePeriod,
  }) {
    return StatisticsFilter(
      locations: locations ?? Set.unmodifiable(this.locations),
      levelIds: levelIds ?? Set.unmodifiable(this.levelIds),
      genders: genders ?? Set.unmodifiable(this.genders),
      groupStatus: groupStatus ?? this.groupStatus,
      timePeriod: timePeriod ?? this.timePeriod,
    );
  }
}
