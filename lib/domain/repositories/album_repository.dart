import 'dart:async';

import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/domain/models/item.dart';

abstract interface class AlbumRepository {
  Future<Directory> getAlbums();
  Future<Directory?> getAlbumContent(Album album);
  Future<void> createAlbum(String name, SearchQueryDTO query);
  Future<void> deleteAlbum(int id);
}
