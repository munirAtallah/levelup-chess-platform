/// Logic Tier — Controller
/// Path: lib/logic/controllers/admin_statistics_controller.dart
library;

import 'package:flutter/foundation.dart';
import '../../data/models/curriculum_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../models/statistics_filter.dart';

export '../models/statistics_filter.dart';

class AdminStatisticsController extends ChangeNotifier {
  final UserRepository _userRepository;
  final CurriculumRepository _curriculumRepository;

  AdminStatisticsController(this._userRepository, this._curriculumRepository) {
    _load();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Raw data retained for in-memory filtering
  List<UserModel> _rawStudents = [];
  List<UserModel> _rawInstructors = [];

  // Active filter
  StatisticsFilter _activeFilter = StatisticsFilter.empty;
  StatisticsFilter get activeFilter => _activeFilter;

  // All unique locations across both cohorts (for the filter sheet chips)
  Set<String> get allLocations {
    final locs = <String>{};
    for (final u in [..._rawStudents, ..._rawInstructors]) {
      locs.add((u.location == null || u.location!.isEmpty) ? 'Not set' : u.location!);
    }
    final sorted = locs.toList()..sort();
    return Set.unmodifiable(sorted);
  }

  // Level name lookup
  Map<String, String> _levelNames = {};
  Map<String, String> get levelNames => _levelNames;

  // Students
  int _totalStudents = 0;
  int get totalStudents => _totalStudents;

  int _unassignedStudents = 0;
  int get unassignedStudents => _unassignedStudents;

  Map<String, int> _studentsByGender = {};
  Map<String, int> get studentsByGender => _studentsByGender;

  Map<String, int> _studentsByLevel = {};
  Map<String, int> get studentsByLevel => _studentsByLevel;

  Map<String, int> _studentsByAge = {};
  Map<String, int> get studentsByAge => _studentsByAge;

  Map<String, int> _studentsByLocation = {};
  Map<String, int> get studentsByLocation => _studentsByLocation;

  double _studentAverageAge = 0;
  double get studentAverageAge => _studentAverageAge;

  // Instructors
  int _totalInstructors = 0;
  int get totalInstructors => _totalInstructors;

  Map<String, int> _instructorsByGender = {};
  Map<String, int> get instructorsByGender => _instructorsByGender;

  Map<String, int> _instructorsByLocation = {};
  Map<String, int> get instructorsByLocation => _instructorsByLocation;

  Map<String, int> _instructorsByAge = {};
  Map<String, int> get instructorsByAge => _instructorsByAge;

  double _instructorAverageAge = 0;
  double get instructorAverageAge => _instructorAverageAge;

  Future<void> refresh() => _load();

  void setFilter(StatisticsFilter filter) {
    _activeFilter = filter;
    _computeStats(
      _applyFilter(_rawStudents, isStudents: true),
      _applyFilter(_rawInstructors, isStudents: false),
    );
    notifyListeners();
  }

  void clearFilters() => setFilter(StatisticsFilter.empty);

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _userRepository.getStudents(),
        _userRepository.getInstructors(),
        _curriculumRepository.getLevels(),
      ]);
      _rawStudents = results[0] as List<UserModel>;
      _rawInstructors = results[1] as List<UserModel>;
      final levels = results[2] as List<LevelModel>;

      final nameMap = <String, String>{};
      for (final l in levels) {
        nameMap[l.id] = l.name;
      }
      _levelNames = nameMap;

      // Reapply any active filter after refresh
      _computeStats(
        _applyFilter(_rawStudents, isStudents: true),
        _applyFilter(_rawInstructors, isStudents: false),
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('AdminStatisticsController._load error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  List<UserModel> _applyFilter(List<UserModel> users, {required bool isStudents}) {
    var result = users;

    // Time period — applies to both cohorts
    if (_activeFilter.timePeriod != 'all') {
      final now = DateTime.now();
      final DateTime cutoff;
      switch (_activeFilter.timePeriod) {
        case 'last7days':
          cutoff = now.subtract(const Duration(days: 7));
        case 'thisMonth':
          cutoff = DateTime(now.year, now.month, 1);
        case 'thisYear':
          cutoff = DateTime(now.year, 1, 1);
        default:
          cutoff = DateTime.fromMillisecondsSinceEpoch(0);
      }
      result = result.where((u) => u.createdAt != null && u.createdAt!.isAfter(cutoff)).toList();
    }

    if (_activeFilter.locations.isNotEmpty) {
      result = result.where((u) {
        final loc = (u.location == null || u.location!.isEmpty) ? 'Not set' : u.location!;
        return _activeFilter.locations.contains(loc);
      }).toList();
    }

    if (_activeFilter.genders.isNotEmpty) {
      result = result.where((u) {
        final g = (u.gender == null || u.gender!.isEmpty) ? 'Not set' : u.gender!;
        return _activeFilter.genders.contains(g);
      }).toList();
    }

    if (isStudents) {
      if (_activeFilter.levelIds.isNotEmpty) {
        result = result.where((u) {
          final lvl = u.levelId ?? 'Unassigned';
          return _activeFilter.levelIds.contains(lvl);
        }).toList();
      }

      switch (_activeFilter.groupStatus) {
        case 'assigned':
          result = result.where((u) => u.groupId != null && u.groupId!.isNotEmpty).toList();
        case 'unassigned':
          result = result.where((u) => u.groupId == null || u.groupId!.isEmpty).toList();
      }
    }

    return result;
  }

  void _computeStats(List<UserModel> students, List<UserModel> instructors) {
    // --- Students ---
    _totalStudents = students.length;
    _unassignedStudents =
        students.where((s) => s.groupId == null || s.groupId!.isEmpty).length;

    final sGender = <String, int>{};
    for (final s in students) {
      final g = (s.gender == null || s.gender!.isEmpty) ? 'Not set' : s.gender!;
      sGender[g] = (sGender[g] ?? 0) + 1;
    }
    _studentsByGender = sGender;

    final sLevel = <String, int>{};
    for (final s in students) {
      final key = s.levelId ?? 'Unassigned';
      sLevel[key] = (sLevel[key] ?? 0) + 1;
    }
    _studentsByLevel = sLevel;

    _studentsByAge = _byAge(students);
    _studentAverageAge = _avgAge(students);
    _studentsByLocation = _topLocations(students.map((s) => s.location));

    // --- Instructors ---
    _totalInstructors = instructors.length;

    final iGender = <String, int>{};
    for (final i in instructors) {
      final g = (i.gender == null || i.gender!.isEmpty) ? 'Not set' : i.gender!;
      iGender[g] = (iGender[g] ?? 0) + 1;
    }
    _instructorsByGender = iGender;

    _instructorsByLocation = _topLocations(instructors.map((i) => i.location));
    _instructorsByAge = _byAge(instructors);
    _instructorAverageAge = _avgAge(instructors);
  }

  Map<String, int> _byAge(Iterable<UserModel> users) {
    final ageMap = <int, int>{};
    for (final u in users) {
      if (u.dateOfBirth != null) {
        final age = DateTime.now().year - u.dateOfBirth!.year;
        ageMap[age] = (ageMap[age] ?? 0) + 1;
      }
    }
    return {
      for (final e
          in (ageMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
        e.key.toString(): e.value,
    };
  }

  double _avgAge(Iterable<UserModel> users) {
    var sum = 0;
    var count = 0;
    for (final u in users) {
      if (u.dateOfBirth != null) {
        sum += DateTime.now().year - u.dateOfBirth!.year;
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  Map<String, int> _topLocations(Iterable<String?> locations) {
    final counts = <String, int>{};
    for (final loc in locations) {
      final key = (loc == null || loc.isEmpty) ? 'Not set' : loc;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.length <= 5) return Map.fromEntries(sorted);
    final top5 = sorted.take(5);
    final other = sorted.skip(5).fold(0, (sum, e) => sum + e.value);
    return Map.fromEntries([...top5, MapEntry('Other', other)]);
  }
}
