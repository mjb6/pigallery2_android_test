import 'dart:convert';

import 'package:pigallery2_android/data/backend/models/search/search.dart';

/// generated with quicktype for Pigallery2 v3.0.1

class AlbumBaseDto {
  final int id;
  final String name;
  final bool locked;
  final SearchQueryDTO searchQuery;
  final AlbumCacheDTO cache;

  AlbumBaseDto({
    required this.id,
    required this.name,
    required this.locked,
    required this.searchQuery,
    required this.cache,
  });

  AlbumBaseDto copyWith({
    int? id,
    String? name,
    bool? locked,
    SearchQueryDTO? searchQuery,
    AlbumCacheDTO? cache,
  }) => AlbumBaseDto(
    id: id ?? this.id,
    name: name ?? this.name,
    locked: locked ?? this.locked,
    searchQuery: searchQuery ?? this.searchQuery,
    cache: cache ?? this.cache,
  );

  factory AlbumBaseDto.fromRawJson(String str) => AlbumBaseDto.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AlbumBaseDto.fromJson(Map<String, dynamic> json) => AlbumBaseDto(
    id: json["id"],
    name: json["name"],
    locked: json["locked"],
    searchQuery: SearchQueryDTO.fromJson(json["searchQuery"]),
    cache: AlbumCacheDTO.fromJson(json["cache"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "locked": locked,
    "searchQuery": searchQuery.toJson(),
    "cache": cache.toJson(),
  };
}

class AlbumCacheDTO {
  final int id;
  final int itemCount;
  final int oldestMedia;
  final int youngestMedia;
  final bool valid;
  final CoverPhotoDTO cover;

  AlbumCacheDTO({
    required this.id,
    required this.itemCount,
    required this.oldestMedia,
    required this.youngestMedia,
    required this.valid,
    required this.cover,
  });

  AlbumCacheDTO copyWith({
    int? id,
    int? itemCount,
    int? oldestMedia,
    int? youngestMedia,
    bool? valid,
    CoverPhotoDTO? cover,
  }) => AlbumCacheDTO(
    id: id ?? this.id,
    itemCount: itemCount ?? this.itemCount,
    oldestMedia: oldestMedia ?? this.oldestMedia,
    youngestMedia: youngestMedia ?? this.youngestMedia,
    valid: valid ?? this.valid,
    cover: cover ?? this.cover,
  );

  factory AlbumCacheDTO.fromRawJson(String str) => AlbumCacheDTO.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AlbumCacheDTO.fromJson(Map<String, dynamic> json) => AlbumCacheDTO(
    id: json["id"],
    itemCount: json["itemCount"],
    oldestMedia: json["oldestMedia"],
    youngestMedia: json["youngestMedia"],
    valid: json["valid"],
    cover: CoverPhotoDTO.fromJson(json["cover"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "itemCount": itemCount,
    "oldestMedia": oldestMedia,
    "youngestMedia": youngestMedia,
    "valid": valid,
    "cover": cover.toJson(),
  };
}

class CoverPhotoDTO {
  final String name;
  final DirectoryPathDTO directory;

  CoverPhotoDTO({
    required this.name,
    required this.directory,
  });

  CoverPhotoDTO copyWith({
    String? name,
    DirectoryPathDTO? directory,
  }) => CoverPhotoDTO(
    name: name ?? this.name,
    directory: directory ?? this.directory,
  );

  factory CoverPhotoDTO.fromRawJson(String str) => CoverPhotoDTO.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CoverPhotoDTO.fromJson(Map<String, dynamic> json) => CoverPhotoDTO(
    name: json["name"],
    directory: DirectoryPathDTO.fromJson(json["directory"]),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "directory": directory.toJson(),
  };
}

class DirectoryPathDTO {
  final String name;
  final String path;

  DirectoryPathDTO({
    required this.name,
    required this.path,
  });

  DirectoryPathDTO copyWith({
    String? name,
    String? path,
  }) => DirectoryPathDTO(
    name: name ?? this.name,
    path: path ?? this.path,
  );

  factory DirectoryPathDTO.fromRawJson(String str) => DirectoryPathDTO.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DirectoryPathDTO.fromJson(Map<String, dynamic> json) => DirectoryPathDTO(
    name: json["name"],
    path: json["path"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "path": path,
  };
}
