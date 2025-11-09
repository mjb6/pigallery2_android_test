import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

enum TabEntry {
  home(0),
  albums(1),
  website(2);

  final int pos;

  const TabEntry(this.pos);

  factory TabEntry.fromPosition(int pos) {
    return TabEntry.values.firstWhere((type) => type.index == pos);
  }
}

class TabStateModel extends SafeChangeNotifier {
  double _scroll = 0;
  TabEntry get currentTab => TabEntry.fromPosition(_scroll.round());
  double get currentScroll => _scroll;

  void setTabScroll(double progress) {
    if (progress != _scroll) {
      _scroll = progress;
      notifyListeners();
    }
  }
}
