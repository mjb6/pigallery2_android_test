import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

class ServerModel extends SafeChangeNotifier {
  final ServerRepository _serverRepository;

  ServerModel(this._serverRepository);

  String? get serverUrl => _serverRepository.serverUrl;

  Iterable<String> get serverUrls => _serverRepository.serverUrls;

  Future<void> addServer(String url, String? username, String? password, SessionData? sessionData) async {
    bool added = await _serverRepository.addServer(url, username, password, sessionData);
    if (added) {
      notifyListeners();
    }
  }

  Future<void> deleteServer(String url) async {
    await _serverRepository.deleteServer(url);
    notifyListeners();
  }

  Future<void> selectServer(String url) async {
    await _serverRepository.selectServer(url);
    notifyListeners();
  }

  String get apiThumbnailPath => _serverRepository.apiSettings.thumbnailPath;

  set apiThumbnailPath(String value) {
    if (value != apiThumbnailPath) {
      _serverRepository.updateApiSettings(
        _serverRepository.apiSettings.copyWith(thumbnailPath: value),
      );
      notifyListeners();
    }
  }

  String get apiVideoPath => _serverRepository.apiSettings.videoPath;

  set apiVideoPath(String value) {
    if (value != apiVideoPath) {
      _serverRepository.updateApiSettings(
        _serverRepository.apiSettings.copyWith(videoPath: value),
      );
      notifyListeners();
    }
  }
}
