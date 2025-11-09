import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

class WebViewModel extends SafeChangeNotifier {
  final ServerRepository _serverRepository;
  String? _serverUrl;
  bool _canGoBack = false;
  String _title = "";

  WebViewModel(this._serverRepository): _serverUrl = _serverRepository.serverUrl;

  bool get canGoBack => _canGoBack;
  String get title => _title;
  String? get serverUrl => _serverUrl;

  set canGoBack(bool value) {
    if (value != _canGoBack) {
      _canGoBack = value;
      notifyListeners();
    }
  }

  set title(String value) {
    if (value != _title) {
      _title = value;
      notifyListeners();
    }
  }

  void updateUrl() {
    String? newUrl = _serverRepository.serverUrl;
    if (newUrl != _serverUrl) {
      _serverUrl = newUrl;
      notifyListeners();
    }
  }
}