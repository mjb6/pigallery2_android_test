import 'package:mime/mime.dart';
import 'package:pigallery2_android/data/backend/models/album.dart';
import 'package:pigallery2_android/data/backend/models/models.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';

import 'media_dimension.dart';
import 'metadata.dart';
import 'package:path/path.dart' as p;

sealed class Item {
  final String name;
  final int id;
  final String relativeApiPath;
  final String? relativeThumbnailPath;
  final Metadata metadata;

  Item({required this.name, required this.id, required this.relativeApiPath, required this.relativeThumbnailPath, required this.metadata});
}

class Media extends Item {
  final MediaDimension dimension;

  Media({required super.name, required super.id, required super.relativeApiPath, required super.relativeThumbnailPath, required this.dimension, required MediaMetadata super.metadata});

  Media.fromBackend(BackendMedia backendMedia)
      : dimension = MediaDimension.fromBackend(backendMedia.metadata.size),
        super(
          name: backendMedia.name,
          id: backendMedia.id,
          relativeApiPath: backendMedia.apiPath,
          relativeThumbnailPath: backendMedia.apiPath,
          metadata: MediaMetadata.fromBackend(backendMedia.metadata),
        );

  bool get isVideo => lookupMimeType(name)?.contains("video") == true;

  bool get isImage => !isVideo;

  double get aspectRatio => dimension.width / dimension.height;
}

class Directory extends Item {
  final List<Directory> directories;
  final List<Media> media;

  Directory({required super.name, required super.id, required super.relativeApiPath, required super.relativeThumbnailPath, required this.directories, required this.media, required DirectoryMetadata super.metadata});

  Directory.fromBackend(BackendDirectory backendDirectory)
      : directories = backendDirectory.directories.map((it) => Directory.fromBackend(it)).toList(),
        media = backendDirectory.media.map((it) => Media.fromBackend(it)).toList(),
        super(
          name: backendDirectory.name,
          id: backendDirectory.id,
          relativeApiPath: backendDirectory.apiPath,
          relativeThumbnailPath: backendDirectory.cover?.apiPath,
          metadata: DirectoryMetadata.fromBackend(backendDirectory),
        );
}

const a = DirectoryMetadata(mediaCount: 0, lastModified: 0);

class Album extends Directory {
  final SearchQueryDTO searchQuery;

  Album({required super.id, required super.name, required this.searchQuery, super.metadata = a, super.relativeApiPath = "", required super.relativeThumbnailPath, required super.directories, required super.media});

  Album.fromBackend(AlbumBaseDto dto) : searchQuery=dto.searchQuery,super(
    id: dto.id,
    name: dto.name,
    relativeApiPath: "",
    relativeThumbnailPath: p.join(dto.cache.cover.directory.path, dto.cache.cover.directory.name, dto.cache.cover.name).replaceAll("./", ""),
    metadata: DirectoryMetadata(mediaCount: dto.cache.itemCount, lastModified: dto.cache.youngestMedia.toDouble()),
    directories: [],
    media: []
  );
}
