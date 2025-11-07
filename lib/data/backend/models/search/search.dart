enum SearchQueryTypes {
  and(1),
  or(2),
  someOf(3),
  unknownRelation(99999),

  // non-text metadata
  // |- range types
  fromDate(10),
  toDate(11),
  minRating(12),
  maxRating(13),
  minResolution(14),
  maxResolution(15),
  minPersonCount(16),
  maxPersonCount(17),

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
      case SearchQueryTypes.fromDate:
        return FromDateSearch.fromJson(json);
      case SearchQueryTypes.toDate:
        return ToDateSearch.fromJson(json);
      case SearchQueryTypes.minRating:
        return MinRatingSearch.fromJson(json);
      case SearchQueryTypes.maxRating:
        return MaxRatingSearch.fromJson(json);
      case SearchQueryTypes.minResolution:
        return MinResolutionSearch.fromJson(json);
      case SearchQueryTypes.maxResolution:
        return MaxResolutionSearch.fromJson(json);
      case SearchQueryTypes.minPersonCount:
        return MinPersonCountSearch.fromJson(json);
      case SearchQueryTypes.maxPersonCount:
        return MaxPersonCountSearch.fromJson(json);
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
    final list = (json['list'] as List)
        .map((item) => SearchQueryDTO.fromJson(item))
        .toList();
    return ANDSearchQuery(list);
  }
}

class ORSearchQuery extends SearchListQuery {
  ORSearchQuery(List<SearchQueryDTO> list) : super(SearchQueryTypes.or, list);

  factory ORSearchQuery.fromJson(Map<String, dynamic> json) {
    final list = (json['list'] as List)
        .map((item) => SearchQueryDTO.fromJson(item))
        .toList();
    return ORSearchQuery(list);
  }
}

class SomeOfSearchQuery extends SearchListQuery {
  final int? min;

  SomeOfSearchQuery(List<NegatableSearchQuery> list, {this.min})
      : super(SearchQueryTypes.someOf, list);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (min != null) json['min'] = min;
    return json;
  }

  factory SomeOfSearchQuery.fromJson(Map<String, dynamic> json) {
    final list = (json['list'] as List)
        .map((item) => SearchQueryDTO.fromJson(item) as NegatableSearchQuery)
        .toList();
    return SomeOfSearchQuery(list, min: json['min']);
  }
}

class TextSearch extends NegatableSearchQuery {
  final String text;
  final TextSearchQueryMatchTypes? matchType;

  TextSearch(SearchQueryTypes type, this.text, {this.matchType, super.negate})
      : assert(TextSearchQueryTypes.contains(type)),
        super(type);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['text'] = text;
    if (matchType != null) json['matchType'] = matchType!.value;
    return json;
  }

  factory TextSearch.fromJson(Map<String, dynamic> json) {
    return TextSearch(
      SearchQueryTypes.fromValue(json['type']),
      json['text'],
      matchType: json['matchType'] != null
          ? TextSearchQueryMatchTypes.fromValue(json['matchType'])
          : null,
      negate: json['negate'],
    );
  }
}

class DistanceSearch extends NegatableSearchQuery {
  final Map<String, dynamic> from;
  final double distance;

  DistanceSearch(this.from, this.distance, {super.negate})
      : super(SearchQueryTypes.distance);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['from'] = from;
    json['distance'] = distance;
    return json;
  }

  factory DistanceSearch.fromJson(Map<String, dynamic> json) {
    return DistanceSearch(
      json['from'],
      json['distance'].toDouble(),
      negate: json['negate'],
    );
  }
}

abstract class RangeSearch extends NegatableSearchQuery {
  final num value;

  RangeSearch(super.type, this.value, {super.negate});

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['value'] = value;
    return json;
  }
}

class FromDateSearch extends RangeSearch {
  FromDateSearch(num value, {bool? negate})
      : super(SearchQueryTypes.fromDate, value, negate: negate);

  factory FromDateSearch.fromJson(Map<String, dynamic> json) {
    return FromDateSearch(json['value'], negate: json['negate']);
  }
}

class ToDateSearch extends RangeSearch {
  ToDateSearch(num value, {bool? negate})
      : super(SearchQueryTypes.toDate, value, negate: negate);

  factory ToDateSearch.fromJson(Map<String, dynamic> json) {
    return ToDateSearch(json['value'], negate: json['negate']);
  }
}

class MinRatingSearch extends RangeSearch {
  MinRatingSearch(num value, {bool? negate})
      : super(SearchQueryTypes.minRating, value, negate: negate);

  factory MinRatingSearch.fromJson(Map<String, dynamic> json) {
    return MinRatingSearch(json['value'], negate: json['negate']);
  }
}

class MaxRatingSearch extends RangeSearch {
  MaxRatingSearch(num value, {bool? negate})
      : super(SearchQueryTypes.maxRating, value, negate: negate);

  factory MaxRatingSearch.fromJson(Map<String, dynamic> json) {
    return MaxRatingSearch(json['value'], negate: json['negate']);
  }
}

class MinPersonCountSearch extends RangeSearch {
  MinPersonCountSearch(num value, {bool? negate})
      : super(SearchQueryTypes.minPersonCount, value, negate: negate);

  factory MinPersonCountSearch.fromJson(Map<String, dynamic> json) {
    return MinPersonCountSearch(json['value'], negate: json['negate']);
  }
}

class MaxPersonCountSearch extends RangeSearch {
  MaxPersonCountSearch(num value, {bool? negate})
      : super(SearchQueryTypes.maxPersonCount, value, negate: negate);

  factory MaxPersonCountSearch.fromJson(Map<String, dynamic> json) {
    return MaxPersonCountSearch(json['value'], negate: json['negate']);
  }
}

class MinResolutionSearch extends RangeSearch {
  MinResolutionSearch(num value, {bool? negate})
      : super(SearchQueryTypes.minResolution, value, negate: negate);

  factory MinResolutionSearch.fromJson(Map<String, dynamic> json) {
    return MinResolutionSearch(json['value'], negate: json['negate']);
  }
}

class MaxResolutionSearch extends RangeSearch {
  MaxResolutionSearch(num value, {bool? negate})
      : super(SearchQueryTypes.maxResolution, value, negate: negate);

  factory MaxResolutionSearch.fromJson(Map<String, dynamic> json) {
    return MaxResolutionSearch(json['value'], negate: json['negate']);
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
    super.negate,
  }) : super(SearchQueryTypes.datePattern);

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

const List<SearchQueryTypes> MinRangeSearchQueryTypes = [
  SearchQueryTypes.fromDate,
  SearchQueryTypes.minRating,
  SearchQueryTypes.minResolution,
];

const List<SearchQueryTypes> MaxRangeSearchQueryTypes = [
  SearchQueryTypes.toDate,
  SearchQueryTypes.maxRating,
  SearchQueryTypes.maxResolution,
];

const List<SearchQueryTypes> RangeSearchQueryTypes = [
  ...MinRangeSearchQueryTypes,
  ...MaxRangeSearchQueryTypes,
];

const List<SearchQueryTypes> MetadataSearchQueryTypes = [
  SearchQueryTypes.distance,
  SearchQueryTypes.orientation,
  ...RangeSearchQueryTypes,
  ...TextSearchQueryTypes,
];