import 'dart:convert';

enum SortType {
  name,
  date,
  size,
  random;

  String toJson() => this.name;

  static SortType fromJson(String value) {
    return SortType.values.firstWhere((e) => e.name == value, orElse: () => SortType.name);
  }
}

enum SortOrder {
  asc,
  desc;

  String toJson() => name;

  static SortOrder fromJson(String value) {
    return SortOrder.values.firstWhere((e) => e.name == value, orElse: () => SortOrder.asc);
  }
}

class StoredSortOption {
  final SortOrder order;
  final SortType type;

  StoredSortOption({
    required this.order,
    required this.type,
  });

  StoredSortOption.initial(): this(order: SortOrder.asc, type: SortType.name);

  StoredSortOption copyWith({
    SortOrder? order,
    SortType? type,
  }) =>
      StoredSortOption(
        order: order ?? this.order,
        type: type ?? this.type,
      );

  factory StoredSortOption.fromRawJson(String str) => StoredSortOption.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory StoredSortOption.fromJson(Map<String, dynamic> json) => StoredSortOption(
    order: SortOrder.fromJson(json["order"]),
    type: SortType.fromJson(json["type"]),
  );

  Map<String, dynamic> toJson() => {
    "order": order.toJson(),
    "type": type.toJson(),
  };
}

class StoredSortOptions {
  final Map<String, StoredSortOption> options;

  StoredSortOptions({required this.options});

  factory StoredSortOptions.fromRawJson(String str) => StoredSortOptions.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory StoredSortOptions.fromJson(Map<String, dynamic> json) {
    final map = <String, StoredSortOption>{};
    json.forEach((key, value) {
      map[key] = StoredSortOption.fromJson(value);
    });
    return StoredSortOptions(options: map);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    options.forEach((key, value) {
      map[key] = value.toJson();
    });
    return map;
  }
}