// ignore_for_file: constant_identifier_names

enum SearchQueryTypes {
  and(1),
  or(2),
  someOf(3),
  unknownRelation(99999),

  // non-text metadata
  // |- range types
  date(10),
  rating(12),
  resolution(14),
  personCount(16),

  distance(50),
  orientation(51),

  datePattern(60),

  // TEXT search types
  anyText(100),
  caption(101),
  directory(102),
  fileName(103),
  keyword(104),
  person(105),
  position(106);

  final int value;
  const SearchQueryTypes(this.value);

  factory SearchQueryTypes.fromValue(int value) {
    return SearchQueryTypes.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SearchQueryTypes.unknownRelation,
    );
  }
}

enum TextSearchQueryMatchTypes {
  exactMatch(1),
  like(2);

  final int value;
  const TextSearchQueryMatchTypes(this.value);

  factory TextSearchQueryMatchTypes.fromValue(int value) {
    return TextSearchQueryMatchTypes.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TextSearchQueryMatchTypes.exactMatch,
    );
  }
}

enum DatePatternFrequency {
  everyWeek(1),
  everyMonth(2),
  everyYear(3),
  daysAgo(10),
  weeksAgo(11),
  monthsAgo(12),
  yearsAgo(13);

  final int value;
  const DatePatternFrequency(this.value);

  factory DatePatternFrequency.fromValue(int value) {
    return DatePatternFrequency.values.firstWhere(
      (freq) => freq.value == value,
      orElse: () => DatePatternFrequency.everyWeek,
    );
  }
}

sealed class SearchQueryDTO {
  final SearchQueryTypes type;

  SearchQueryDTO(this.type);

  Map<String, dynamic> toJson() => {'type': type.value};

  factory SearchQueryDTO.fromJson(Map<String, dynamic> json) {
    final type = SearchQueryTypes.fromValue(json['type']);
    switch (type) {
      case SearchQueryTypes.and:
        return ANDSearchQuery.fromJson(json);
      case SearchQueryTypes.or:
        return ORSearchQuery.fromJson(json);
      case SearchQueryTypes.someOf:
        return SomeOfSearchQuery.fromJson(json);
      case SearchQueryTypes.distance:
        return DistanceSearch.fromJson(json);
      case SearchQueryTypes.date:
        return DateSearch.fromJson(json);
      case SearchQueryTypes.rating:
        return RatingSearch.fromJson(json);
      case SearchQueryTypes.resolution:
        return ResolutionSearch.fromJson(json);
      case SearchQueryTypes.personCount:
        return PersonCountSearch.fromJson(json);
      case SearchQueryTypes.orientation:
        return OrientationSearch.fromJson(json);
      case SearchQueryTypes.datePattern:
        return DatePatternSearch.fromJson(json);
      default:
        if (TextSearchQueryTypes.contains(type)) {
          return TextSearch.fromJson(json);
        }
        throw Exception('Unknown SearchQueryType: ${json['type']}');
    }
  }
}

abstract class NegatableSearchQuery extends SearchQueryDTO {
  final bool? negate;

  NegatableSearchQuery(super.type, {this.negate});

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (negate != null) json['negate'] = negate;
    return json;
  }
}

abstract class SearchListQuery extends SearchQueryDTO {
  final List<SearchQueryDTO> list;

  SearchListQuery(super.type, this.list);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['list'] = list.map((query) => query.toJson()).toList();
    return json;
  }
}

class ANDSearchQuery extends SearchListQuery {
  ANDSearchQuery(List<SearchQueryDTO> list) : super(SearchQueryTypes.and, list);

  factory ANDSearchQuery.fromJson(Map<String, dynamic> json) {
    final list = (json['list'] as List).map((item) => SearchQueryDTO.fromJson(item)).toList();
    return ANDSearchQuery(list);
  }
}

class ORSearchQuery extends SearchListQuery {
  ORSearchQuery(List<SearchQueryDTO> list) : super(SearchQueryTypes.or, list);

  factory ORSearchQuery.fromJson(Map<String, dynamic> json) {
    final list = (json['list'] as List).map((item) => SearchQueryDTO.fromJson(item)).toList();
    return ORSearchQuery(list);
  }
}

class SomeOfSearchQuery extends SearchListQuery {
  final int? min;

  SomeOfSearchQuery(List<NegatableSearchQuery> list, {this.min}) : super(SearchQueryTypes.someOf, list);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (min != null) json['min'] = min;
    return json;
  }

  factory SomeOfSearchQuery.fromJson(Map<String, dynamic> json) {
    final list = (json['list'] as List).map((item) => SearchQueryDTO.fromJson(item) as NegatableSearchQuery).toList();
    return SomeOfSearchQuery(list, min: json['min']);
  }
}

class TextSearch extends NegatableSearchQuery {
  final String value;
  final TextSearchQueryMatchTypes? matchType;

  TextSearch(super.type, this.value,
      {this.matchType, super.negate})
      : assert(TextSearchQueryTypes.contains(type));

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['value'] = value;
    if (matchType != null) json['matchType'] = matchType!.value;
    return json;
  }

  factory TextSearch.fromJson(Map<String, dynamic> json) {
    return TextSearch(
      SearchQueryTypes.fromValue(json['type']),
      json['value'],
      matchType: json['matchType'] != null
          ? TextSearchQueryMatchTypes.fromValue(json['matchType'])
          : null,
      negate: json['negate'],
    );
  }
}

class DistanceSearch extends NegatableSearchQuery {
  final Map<String, dynamic> from;
  final num distance;

  DistanceSearch(this.from, this.distance, {bool? negate})
      : super(SearchQueryTypes.distance, negate: negate);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['from'] = from;
    json['distance'] = distance;
    return json;
  }

  factory DistanceSearch.fromJson(Map<String, dynamic> json) {
    return DistanceSearch(
      json['from'] as Map<String, dynamic>,
      json['distance'] is int ? (json['distance'] as int).toDouble() : json['distance'] as double,
      negate: json['negate'],
    );
  }
}

abstract class RangeSearch extends NegatableSearchQuery {
  final num? min;
  final num? max;

  RangeSearch(super.type, {this.min, this.max, super.negate});

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (min != null) json['min'] = min;
    if (max != null) json['max'] = max;
    return json;
  }
}

class DateSearch extends RangeSearch {
  DateSearch({num? min, num? max, bool? negate})
      : super(SearchQueryTypes.date, min: min, max: max, negate: negate);

  factory DateSearch.fromJson(Map<String, dynamic> json) {
    return DateSearch(
      min: json['min'],
      max: json['max'],
      negate: json['negate'],
    );
  }
}

class RatingSearch extends RangeSearch {
  RatingSearch({num? min, num? max, bool? negate})
      : super(SearchQueryTypes.rating, min: min, max: max, negate: negate);

  factory RatingSearch.fromJson(Map<String, dynamic> json) {
    return RatingSearch(
      min: json['min'],
      max: json['max'],
      negate: json['negate'],
    );
  }
}

class PersonCountSearch extends RangeSearch {
  PersonCountSearch({num? min, num? max, bool? negate})
      : super(SearchQueryTypes.personCount, min: min, max: max, negate: negate);

  factory PersonCountSearch.fromJson(Map<String, dynamic> json) {
    return PersonCountSearch(
      min: json['min'],
      max: json['max'],
      negate: json['negate'],
    );
  }
}

class ResolutionSearch extends RangeSearch {
  ResolutionSearch({num? min, num? max, bool? negate})
      : super(SearchQueryTypes.resolution, min: min, max: max, negate: negate);

  factory ResolutionSearch.fromJson(Map<String, dynamic> json) {
    return ResolutionSearch(
      min: json['min'],
      max: json['max'],
      negate: json['negate'],
    );
  }
}

class OrientationSearch extends SearchQueryDTO {
  final bool landscape;

  OrientationSearch(this.landscape) : super(SearchQueryTypes.orientation);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['landscape'] = landscape;
    return json;
  }

  factory OrientationSearch.fromJson(Map<String, dynamic> json) {
    return OrientationSearch(json['landscape']);
  }
}

class DatePatternSearch extends NegatableSearchQuery {
  final int daysLength;
  final DatePatternFrequency frequency;
  final int? agoNumber;

  DatePatternSearch(
    this.daysLength,
    this.frequency, {
    this.agoNumber,
    bool? negate,
  }) : super(SearchQueryTypes.datePattern, negate: negate);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['daysLength'] = daysLength;
    json['frequency'] = frequency.value;
    if (agoNumber != null) json['agoNumber'] = agoNumber;
    return json;
  }

  factory DatePatternSearch.fromJson(Map<String, dynamic> json) {
    return DatePatternSearch(
      json['daysLength'],
      DatePatternFrequency.fromValue(json['frequency']),
      agoNumber: json['agoNumber'],
      negate: json['negate'],
    );
  }
}

// Helper Lists
const List<SearchQueryTypes> ListSearchQueryTypes = [
  SearchQueryTypes.and,
  SearchQueryTypes.or,
  SearchQueryTypes.someOf,
];

const List<SearchQueryTypes> TextSearchQueryTypes = [
  SearchQueryTypes.anyText,
  SearchQueryTypes.caption,
  SearchQueryTypes.directory,
  SearchQueryTypes.fileName,
  SearchQueryTypes.keyword,
  SearchQueryTypes.person,
  SearchQueryTypes.position,
];

const List<SearchQueryTypes> RangeSearchQueryTypes = [
  SearchQueryTypes.date,
  SearchQueryTypes.rating,
  SearchQueryTypes.resolution,
  SearchQueryTypes.personCount,
];

const List<SearchQueryTypes> MetadataSearchQueryTypes = [
  SearchQueryTypes.distance,
  SearchQueryTypes.orientation,
  ...RangeSearchQueryTypes,
  ...TextSearchQueryTypes,
];
