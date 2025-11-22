import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/web_view_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

class AppBarModel extends SafeChangeNotifier {
  String _title = "";
  bool _canGoBack = false;
  bool _areDirectoriesDisplayed = false;

  final GalleryModelProvider _galleryModelSelector;
  final WebViewModel _webviewModel;
  final TabStateModel _tabStateModel;

  TabEntry _currentTab = TabEntry.home;

  AppBarModel(this._galleryModelSelector, this._webviewModel, this._tabStateModel) {
    _galleryModelSelector.addListener(_notify);
    _webviewModel.addListener(_webviewNotify);
    _tabStateModel.addListener(_tabStateNotify);
  }

  @override
  void dispose() {
    _galleryModelSelector.removeListener(_notify);
    _webviewModel.removeListener(_webviewNotify);
    super.dispose();
  }

  /// Update when current tab changes
  void _tabStateNotify() {
    if (_currentTab == TabEntry.website && _tabStateModel.currentTab != TabEntry.website) {
      _currentTab = _tabStateModel.currentTab;
      _notify();
      return;
    }
    if (_currentTab != TabEntry.website && _tabStateModel.currentTab == TabEntry.website) {
      _currentTab = _tabStateModel.currentTab;
      _webviewNotify();
      return;
    }
    _currentTab = _tabStateModel.currentTab;
  }

  void _webviewNotify() {
    if (_currentTab != TabEntry.website) return;
    _update(
      canGoBack: _webviewModel.canGoBack,
      title: _webviewModel.title,
      areDirectoriesDisplayed: false,
    );
  }

  void _notify() {
    GalleryModel? model = _galleryModelSelector.model;
    if (_currentTab == TabEntry.website || model == null) return;
    _update(
      canGoBack: model.stackPosition > 0,
      title: model.currentState.title,
      areDirectoriesDisplayed: model.currentState.directories.isNotEmpty,
    );
  }

  /// update appbar before removing stack
  void handleBack() {
    GalleryModel? model = _galleryModelSelector.model;
    if (_currentTab == TabEntry.website || model == null) return;
    _update(
      canGoBack: model.stackPosition > 1,
      title: model.stateOf(model.stackPosition - 1).title,
      areDirectoriesDisplayed: model.stateOf(model.stackPosition - 1).directories.isNotEmpty,
    );
  }

  void _update({bool? canGoBack, String? title, bool? areDirectoriesDisplayed}) {
    bool changed = false;
    if (canGoBack != null && canGoBack != _canGoBack) {
      changed = true;
      _canGoBack = canGoBack;
    }
    if (title != null && title != _title) {
      changed = true;
      _title = title;
    }
    if (areDirectoriesDisplayed != null && areDirectoriesDisplayed != _areDirectoriesDisplayed) {
      changed = true;
      _areDirectoriesDisplayed = areDirectoriesDisplayed;
    }
    if (changed) {
      notifyListeners();
    }
  }

  bool get canGoBack => _canGoBack;

  String get title => _title;

  bool get areDirectoriesDisplayed => _areDirectoriesDisplayed;
}
