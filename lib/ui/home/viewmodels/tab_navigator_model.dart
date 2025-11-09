import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pigallery2_android/ui/app_bar/viewmodels/app_bar_model.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

final Map<int, GlobalKey<NavigatorState>> navigatorKeys = {
  for (var it in TabEntry.values) it.pos: GlobalKey<NavigatorState>(),
};

class TabNavigatorModel extends SafeChangeNotifier {
  final TabStateModel _tabStateModel;
  int _currentTab = 0;
  late VoidCallback _webViewBackHandler;
  final AppBarModel _appBarModel;

  TabNavigatorModel(this._tabStateModel, this._appBarModel) {
    _tabStateModel.addListener(_tabChangedListener);
  }

  @override
  void dispose() {
    _tabStateModel.removeListener(_tabChangedListener);
    super.dispose();
  }

  void _tabChangedListener() {
    _currentTab = _tabStateModel.currentTab.pos;
  }

  void registerWebViewBackHandler(VoidCallback handler) {
    _webViewBackHandler = handler;
  }

  /// invoked before removing the stack from [model].
  void goBack() {
    if (_currentTab == TabEntry.website.pos) {
      _webViewBackHandler.call();
    } else {
      if (navigatorKeys[_currentTab]?.currentState?.canPop() != true) {
        SystemNavigator.pop();
      }
      navigatorKeys[_currentTab]?.currentState?.pop();
    }
    _appBarModel.handleBack();
  }
}
