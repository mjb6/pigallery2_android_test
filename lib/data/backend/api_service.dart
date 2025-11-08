import 'package:pigallery2_android/data/backend/models/album.dart';
import 'package:pigallery2_android/data/backend/models/auth/connection_test_result.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/data/backend/models/search/search_result.dart';
import 'package:pigallery2_android/domain/models/item.dart';

abstract interface class ApiService {
  Future<BackendDirectory?> getDirectories({String? path});

  Future<SearchResult?> search(SearchQueryDTO query);

  Future<List<AlbumBaseDto>> getAlbums();

  Future<void> startIndexingJob();

  Future<ConnectionTestResult> testConnection(String url, String? username, String? password);

  Map<String, String> get headers;

  String getMediaApiPath(Media item);

  String? getThumbnailApiPath(Item item);

  String getSpritesApiPath(Media item);
}
