import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

/// Provides the [GalleryModel] for the current tab to widgets above the tab view.
class GalleryModelProvider extends SafeChangeNotifier {
  final List<GalleryModel> _models;
  final TabStateModel _tabStateModel;
  int _currentTab = 0;

  GalleryModelProvider(
    this._tabStateModel,
    GalleryModel home,
    GalleryModel albums,
  ) : _models = [home, albums] {
    model?.addListener(_galleryModelNotify);
    _tabStateModel.addListener(_tabChangedListener);
  }

  GalleryModel? get model => _models.elementAtOrNull(_currentTab);

  @override
  void dispose() {
    model?.removeListener(_galleryModelNotify);
    _tabStateModel.removeListener(_tabChangedListener);
    super.dispose();
  }

  GalleryModel getModelByTab(int tab) {
    return _models[tab];
  }

  void _tabChangedListener() {
    if (_currentTab != _tabStateModel.currentTab.pos) {
      model?.removeListener(_galleryModelNotify);
      _currentTab = _tabStateModel.currentTab.pos;
      model?.addListener(_galleryModelNotify);
      notifyListeners();
    }
  }

  void _galleryModelNotify() {
    notifyListeners();
  }

  Future<void> reset() async {
    for (var model in _models) {
      while(model.stackPosition > 0) {
        model.popStack();
      }
      await model.fetch();
    }
  }
}
