import 'dart:convert';

import 'package:pigallery2_android/data/storage/models/sort_option.dart';

class ServerSettings {
  final List<Server> servers;
  final ApiSettings defaultApiSettings;
  final String selectedServer;

  const ServerSettings({
    required this.servers,
    required this.defaultApiSettings,
    required this.selectedServer,
  });

  ServerSettings copyWith({
    List<Server>? servers,
    String? selectedServer,
    ApiSettings? defaultApiSettings,
  }) => ServerSettings(
    servers: servers ?? this.servers,
    defaultApiSettings: defaultApiSettings ?? this.defaultApiSettings,
    selectedServer: selectedServer ?? this.selectedServer,
  );

  factory ServerSettings.fromRawJson(String str) => ServerSettings.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ServerSettings.fromJson(Map<String, dynamic> json) => ServerSettings(
    servers: List<Server>.from(json["servers"].map((x) => Server.fromJson(x))),
    defaultApiSettings: ApiSettings.fromJson(json["defaultApiSettings"]),
    selectedServer: json["selectedServer"],
  );

  Map<String, dynamic> toJson() => {
    "servers": List<dynamic>.from(servers.map((x) => x.toJson())),
    "defaultApiSettings": defaultApiSettings.toJson(),
    "selectedServer": selectedServer,
  };
}

class Server {
  final String url;
  final ApiSettings apiSettings;
  final StoredSortOptions sortOptions;

  Server({
    required this.url,
    required this.apiSettings,
    StoredSortOptions? sortOptions,
  }) : sortOptions = sortOptions ?? StoredSortOptions(options: {});

  Server copyWith({
    String? url,
    ApiSettings? apiSettings,
    StoredSortOptions? sortOptions,
  }) => Server(
    url: url ?? this.url,
    apiSettings: apiSettings ?? this.apiSettings,
    sortOptions: sortOptions ?? this.sortOptions,
  );

  factory Server.fromRawJson(String str) => Server.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Server.fromJson(Map<String, dynamic> json) => Server(
    url: json["url"],
    apiSettings: ApiSettings.fromJson(json["apiSettings"]),
    sortOptions: StoredSortOptions.fromJson(json["sortOptions"]),
  );

  Map<String, dynamic> toJson() => {
    "url": url,
    "apiSettings": apiSettings.toJson(),
    "sortOptions": sortOptions.toJson(),
  };
}

class ApiSettings {
  final String thumbnailPath;
  final String videoPath;

  const ApiSettings({
    required this.thumbnailPath,
    required this.videoPath,
  });

  ApiSettings copyWith({
    String? thumbnailPath,
    String? videoPath,
  }) => ApiSettings(
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    videoPath: videoPath ?? this.videoPath,
  );

  factory ApiSettings.fromRawJson(String str) => ApiSettings.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiSettings.fromJson(Map<String, dynamic> json) => ApiSettings(
    thumbnailPath: json["thumbnailPath"],
    videoPath: json["videoPath"],
  );

  Map<String, dynamic> toJson() => {
    "thumbnailPath": thumbnailPath,
    "videoPath": videoPath,
  };
}
