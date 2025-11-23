import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/backend/models/album.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/metadata.dart';
import 'package:pigallery2_android/domain/repositories/album_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';

class AlbumRepositoryImpl implements AlbumRepository {
  final ApiService _api;

  AlbumRepositoryImpl(this._api);
  @override
  Future<Directory> getAlbums() async {
    List<AlbumBaseDto> albums = await _api.getAlbums();
    return Directory(
      id: -1,
      name: "Albums",
      relativeApiPath: "Albums",
      relativeThumbnailPath: null,
      metadata: DirectoryMetadata(mediaCount: 0, lastModified: 0),
      media: [],
      directories: albums.map((it) => Album.fromBackend(it)).toList(),
    );
  }

  @override
  Future<Directory?> getAlbumContent(Album album) async {
    BackendDirectory? result = (await _api.search(album.searchQuery))?.toDirectory(album.name);
    return result?.let((it) => Directory.fromBackend(result));
  }
}
