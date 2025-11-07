import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/backend/models/album.dart';
import 'package:pigallery2_android/domain/models/album.dart';
import 'package:pigallery2_android/domain/repositories/album_repository.dart';

class AlbumRepositoryImpl implements AlbumRepository {
  final ApiService _api;

  AlbumRepositoryImpl(this._api);
  @override
  Future<List<Album>> getAlbums()async{
    List<AlbumBaseDto> albums = await _api.getAlbums();
    return albums.map((it) => Album.fromBackend(it)).toList();
  }

}