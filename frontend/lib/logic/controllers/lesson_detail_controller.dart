/// Logic Tier — Controller
/// Path: lib/logic/controllers/lesson_detail_controller.dart
library;

import 'package:flutter/foundation.dart';
import '../../data/models/curriculum_model.dart';
import '../../data/repositories/curriculum_repository.dart';

class LessonDetailController extends ChangeNotifier {
  final String lessonId;
  final CurriculumRepository _repository;
  
  late CurriculumItem lesson;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  LessonDetailController(this.lessonId, this._repository) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    lesson = await _repository.getLessonById(lessonId) ?? 
      CurriculumItem(type: CurriculumItemType.material, title: 'Unknown Lesson');
    _isLoading = false;
    notifyListeners();
  }

  // Add any lesson specific state/actions here
}
