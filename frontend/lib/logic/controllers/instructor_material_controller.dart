/// Logic Tier — Controller
/// Path: lib/logic/controllers/instructor_material_controller.dart
library;

import 'package:flutter/foundation.dart';
import '../../data/models/instructor_material_model.dart';
import '../../data/repositories/instructor_material_repository.dart';

class InstructorMaterialController extends ChangeNotifier {
  final InstructorMaterialRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<InstructorMaterialModel> _materials = [];
  List<InstructorMaterialModel> get materials => _materials;

  String? _error;
  String? get error => _error;

  InstructorMaterialController(this._repository);

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<void> loadInstructorMaterials(String instructorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _materials =
          await _repository.getInstructorMaterials(instructorId);
    } catch (e) {
      _error = e.toString();
      debugPrint('InstructorMaterialController.loadInstructorMaterials: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<void> addMaterial({
    required String title,
    required String deltaJson,
    required List<Map<String, String>> attachments,
    required String instructorId,
    required String groupId,
    required String levelId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.addMaterial(
        title: title,
        deltaJson: deltaJson,
        attachments: attachments,
        instructorId: instructorId,
        groupId: groupId,
        levelId: levelId,
      );
      // Reload so the list reflects the new document.
      _materials = await _repository.getInstructorMaterials(instructorId);
    } catch (e) {
      _error = e.toString();
      debugPrint('InstructorMaterialController.addMaterial: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMaterial(
    String id,
    String title,
    String deltaJson,
    List<Map<String, String>> attachments, {
    required String instructorId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.updateMaterial(id, title, deltaJson, attachments);
      _materials = await _repository.getInstructorMaterials(instructorId);
    } catch (e) {
      _error = e.toString();
      debugPrint('InstructorMaterialController.updateMaterial: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMaterial(String id, {required String instructorId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.deleteMaterial(id);
      _materials = await _repository.getInstructorMaterials(instructorId);
    } catch (e) {
      _error = e.toString();
      debugPrint('InstructorMaterialController.deleteMaterial: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleVisibility(
    String id,
    bool current, {
    required String instructorId,
  }) async {
    // Optimistic local update
    _materials = _materials.map((m) {
      if (m.id != id) return m;
      return InstructorMaterialModel(
        id: m.id,
        title: m.title,
        content: m.content,
        deltaJson: m.deltaJson,
        attachments: m.attachments,
        instructorId: m.instructorId,
        groupId: m.groupId,
        levelId: m.levelId,
        createdAt: m.createdAt,
        updatedAt: DateTime.now(),
        isVisible: !current,
        searchKeywords: m.searchKeywords,
      );
    }).toList();
    notifyListeners();
    try {
      await _repository.toggleVisibility(id, current);
    } catch (e) {
      // Roll back on error
      _materials = await _repository.getInstructorMaterials(instructorId);
      _error = e.toString();
      debugPrint('InstructorMaterialController.toggleVisibility: $e');
      notifyListeners();
      rethrow;
    }
  }
}
