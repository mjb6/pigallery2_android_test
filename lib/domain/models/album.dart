import 'package:pigallery2_android/data/backend/models/album.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';

class Album {
  final int id;
  final String name;
  final SearchQueryDTO searchQuery;

  Album({required this.id, required this.name, required this.searchQuery});

  Album.fromBackend(AlbumBaseDto dto) : id = dto.id, name = dto.name, searchQuery = dto.searchQuery;
}
