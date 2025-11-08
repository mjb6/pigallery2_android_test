import 'package:flutter/cupertino.dart';
import 'package:pigallery2_android/ui/home/viewmodels/home_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:provider/provider.dart';

enum TabEntry {
  home(0),
  albums(1);

  final int pos;

  const TabEntry(this.pos);

  factory TabEntry.fromPosition(int pos) {
    return TabEntry.values.firstWhere((type) => type.index == pos);
  }
}

class HomeModelSelector extends SafeChangeNotifier {
  final Map<TabEntry, HomeModel> _models;
  TabEntry _currentTab = TabEntry.home;
  List<VoidCallback> popRouteCallbacks;

  HomeModelSelector(
    HomeModel home,
    HomeModel albums,
  ) : popRouteCallbacks = List<VoidCallback>.filled(TabEntry.values.length, () {}),
      _models = {TabEntry.home: home, TabEntry.albums: albums} {
    model.addListener(notifyListeners);
  }

  HomeModel get model => _models[_currentTab]!;
  TabEntry get tab => _currentTab; // todo unused

  @override
  void dispose() {
    model.removeListener(notifyListeners);
    super.dispose();
  }

  HomeModel getModelByPage(int page) {
    return _models[TabEntry.fromPosition(page)]!;
  }

  void setPage(int page) {
    if (page != _currentTab.pos) {
      model.removeListener(notifyListeners);
      _currentTab = TabEntry.fromPosition(page);
      model.addListener(notifyListeners);
      notifyListeners();
    }
  }

  void popRoute() {
    popRouteCallbacks[_currentTab.pos].call();
    notifyListeners();
  }

  /// Register navigator pop callback so that we can navigate up from widgets that aren't children of the
  /// tab-specific navigators, e.g. the app bar.
  void registerPopRouteCallback(int index, VoidCallback callback) {
    popRouteCallbacks[index] = callback;
  }

  void refetchItems() {
    for (var model in _models.values) {
      model.fetchItems();
    }
  }
}

extension SelectHomeModel on BuildContext {
  HomeModel selectHomeModel() {
    return select<HomeModelSelector, HomeModel>((it) => it.model);
  }
}
