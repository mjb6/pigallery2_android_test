import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/data/backend/models/auth/connection_test_result.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/settings/viewmodels/server_model.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

class AddServerModel extends SafeChangeNotifier {
  final ServerRepository _serverRepository;
  final ApiService _apiService;
  final ServerModel _serverModel;

  AddServerModel(this._serverRepository, this._apiService, this._serverModel);

  SessionData? _lastSessionData;

  bool testSuccessUrl = false;
  bool testSuccessAuth = false;
  String? testUrlErrorText;
  bool testFailedAuth = false;

  Future<void> addServer(String url, String? username, String? password) async {
    await _serverModel.addServer(url, username, password, _lastSessionData);
  }

  void credentialsChanged() {
    testFailedAuth = false;
    testSuccessAuth = false;
    _lastSessionData = null;
    notifyListeners();
  }

  void urlChanged() {
    testUrlErrorText = null;
    testSuccessUrl = false;
    testSuccessAuth = false;
    testFailedAuth = false;
    _lastSessionData = null;
    notifyListeners();
  }

  Future<void> testConnection(String url, String? username, String? password) async {
    if (_serverRepository.serverUrls.contains(url)) {
      testUrlErrorText = "Server already exists";
      testFailedAuth = false;
      testSuccessAuth = false;
      testSuccessUrl = false;
      _lastSessionData = null;
      notifyListeners();
      return;
    }
    ConnectionTestResult result = await _apiService.testConnection(url, username, password);
    if (result.serverUnreachable) {
      testUrlErrorText = "Can't connect to server";
      testFailedAuth = false;
      testSuccessAuth = false;
      testSuccessUrl = false;
      _lastSessionData = null;
    } else if (result.authFailed) {
      testUrlErrorText = null;
      testFailedAuth = true;
      testSuccessUrl = true;
      testSuccessAuth = false;
      _lastSessionData = null;
    } else {
      testUrlErrorText = null;
      testFailedAuth = false;
      testSuccessAuth = true;
      testSuccessUrl = true;
      _lastSessionData = result.sessionData;
    }
    notifyListeners();
  }

  void reset() {
    testFailedAuth = false;
    testUrlErrorText = null;
    testSuccessAuth = false;
    testSuccessUrl = false;
    _lastSessionData = null;
  }
}
