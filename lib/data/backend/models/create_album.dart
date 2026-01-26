import 'dart:convert';

import 'package:pigallery2_android/data/backend/models/search/search.dart';

class CreateAlbumDto {
  final String name;
  final SearchQueryDTO searchQuery;

  CreateAlbumDto({required this.name, required this.searchQuery});

  CreateAlbumDto copyWith({
    String? name,
    SearchQueryDTO? searchQuery,
  }) => CreateAlbumDto(
    name: name ?? this.name,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  factory CreateAlbumDto.fromRawJson(String str) => CreateAlbumDto.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CreateAlbumDto.fromJson(Map<String, dynamic> json) => CreateAlbumDto(
    name: json["name"],
    searchQuery: SearchQueryDTO.fromJson(json["searchQuery"]),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "searchQuery": searchQuery.toJson(),
  };
}
