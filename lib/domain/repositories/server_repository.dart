import 'package:pigallery2_android/data/storage/models/server_settings.dart';
import 'package:pigallery2_android/data/storage/models/session_data.dart';

abstract interface class ServerRepository {
  Iterable<String> get serverUrls;

  String? get serverUrl;

  ApiSettings get apiSettings;

  Future<bool> addServer(String url, String? username, String? password, SessionData? sessionData);

  Future<void> deleteServer(String url);

  Future<void> selectServer(String url);

  Future<void> updateApiSettings(ApiSettings apiSettings);
}
