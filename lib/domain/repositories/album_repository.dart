import 'dart:async';

import 'package:pigallery2_android/domain/models/item.dart';

abstract interface class AlbumRepository {
  Future<Directory> getAlbums();
  Future<Directory?> getAlbumContent(Album album);
}
