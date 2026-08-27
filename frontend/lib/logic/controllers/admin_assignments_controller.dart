import 'package:flutter/foundation.dart';

class AdminAssignmentsController extends ChangeNotifier {
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  void setSearch(String query) {
    final cleanQuery = query.toLowerCase().trim();
    if (_searchQuery != cleanQuery) {
      _searchQuery = cleanQuery;
      notifyListeners();
    }
  }
}
