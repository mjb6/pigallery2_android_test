import 'dart:async';

import 'package:pigallery2_android/domain/models/album.dart';

abstract interface class AlbumRepository {
  Future<List<Album>> getAlbums();
}
