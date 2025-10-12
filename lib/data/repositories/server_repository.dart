import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/storage/credential_storage.dart';
import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';
import 'package:pigallery2_android/data/storage/shared_prefs_storage.dart';
import 'package:pigallery2_android/data/storage/session_storage.dart';
import 'package:pigallery2_android/data/storage/storage_key.dart';
import 'package:pigallery2_android/domain/repositories/server_repository.dart';

class ServerRepositoryImpl implements ServerRepository {
  final CredentialStorage _credentialStorage;
  final SharedPrefsStorage _storage;
  final SessionStorage _sessionStorage;

  ServerRepositoryImpl(this._storage, this._credentialStorage, this._sessionStorage);

  ServerSettings get _serverSettings => _storage.get(StorageKey.serverSettings);

  @override
  Iterable<String> get serverUrls => _serverSettings.servers.map((it) => it.url);

  @override
  String? get serverUrl {
    return _serverSettings.servers.firstWhereOrNull((it) => it.url == _serverSettings.selectedServer)?.url;
  }

  @override
  ApiSettings get apiSettings {
    if (_serverSettings.servers.isEmpty) {
      return _serverSettings.defaultApiSettings;
    }
    return _serverSettings.servers.firstWhere((it) => it.url == _serverSettings.selectedServer).apiSettings;
  }

  @override
  Future<bool> addServer(String url, String? username, String? password, SessionData? sessionData) async {
    List<Server> servers = _serverSettings.servers.toList();
    if (servers.any((it) => it.url == url)) {
      return false; // already exists
    }
    servers.add(Server(url: url, apiSettings: _serverSettings.defaultApiSettings));
    ServerSettings settings = _serverSettings.copyWith(
      servers: servers,
      selectedServer: servers.length == 1 ? url : _serverSettings.selectedServer,
    );
    await _storage.set(StorageKey.serverSettings, settings);

    if (username != null && password != null) {
      await _credentialStorage.storeCredentials(url, username, password);
    }
    if (sessionData != null) {
      await _sessionStorage.storeSessionData(sessionData);
      sessionData = null;
    }
    return true;
  }

  @override
  Future<void> deleteServer(String url) async {
    List<Server> updatedServers = _serverSettings.servers.whereNot((it) => it.url == url).toList();
    String? selectedServer = _serverSettings.selectedServer;
    if (selectedServer == url && updatedServers.isNotEmpty) {
      selectedServer = updatedServers.first.url;
    }
    ServerSettings updatedSettings = _serverSettings.copyWith(
      servers: updatedServers,
      selectedServer: selectedServer,
    );
    await _storage.set(StorageKey.serverSettings, updatedSettings);
    await _credentialStorage.deleteCredentials(url);
    await _sessionStorage.deleteSessionData(url);
  }

  @override
  Future<void> selectServer(String url) async {
    await _storage.set(StorageKey.serverSettings, _serverSettings.copyWith(selectedServer: url));
  }

  @override
  Future<void> updateApiSettings(ApiSettings apiSettings) async {
    ApiSettings? defaultApiSettings;
    if (_serverSettings.servers.length <= 1) {
      defaultApiSettings = apiSettings;
    }
    ServerSettings updatedServerSettings = _serverSettings.copyWith(
      defaultApiSettings: defaultApiSettings,
      servers: _serverSettings.servers.map((it) {
        if (it.url == serverUrl) {
          return it.copyWith(apiSettings: apiSettings);
        }
        return it;
      }).toList(),
    );
    await _storage.set(StorageKey.serverSettings, updatedServerSettings);
  }
}
