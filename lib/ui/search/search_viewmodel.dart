import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query_parser.dart';
import 'package:pigallery2_android/domain/models/item.dart';

class SearchViewModel extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool _showOverlay = false;

  bool _isSearching = false;

  bool get isSearching => _isSearching;

  String get query => controller.text;

  set query(String v) {
    controller.text = v;
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    notifyListeners();
  }

  bool get showOverlay => _showOverlay;
  set showOverlay(bool v) {
    if (_showOverlay != v) {
      _showOverlay = v;
      notifyListeners();
    }
  }

  void clearInput() {
    _showOverlay = true;
    query = '';
    focusNode.requestFocus();
  }

  void startSearch(Directory? baseDirectory) {
    String? apiPath = baseDirectory?.relativeApiPath;
    if (apiPath != null && apiPath.isNotEmpty && apiPath != ".") {
      query = '${SearchQueryParser().keywords.directory}:$apiPath ';
    } else {
      query = '';
    }
    showOverlay = true;
    _isSearching = true;
    notifyListeners();
  }

  void stopSearch() {
    showOverlay = false;
    _isSearching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
