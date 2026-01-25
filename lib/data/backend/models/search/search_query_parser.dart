import 'package:pigallery2_android/data/backend/models/search/search.dart';

class QueryKeywords {
  final String daysAgo;
  final String yearsAgo;
  final String monthsAgo;
  final String weeksAgo;
  final String everyYear;
  final String everyMonth;
  final String everyWeek;
  final String lastNDays;
  final String sameDay;
  final String portrait;
  final String landscape;
  final String orientation;
  final String kmFrom;
  final String resolution;
  final String rating;
  final String personCount;
  final String nSomeOf;
  final String someOf;
  final String or;
  final String and;
  final String date;
  final String anyText;
  final String caption;
  final String directory;
  final String fileName;
  final String keyword;
  final String person;
  final String position;

  QueryKeywords({
    required this.daysAgo,
    required this.yearsAgo,
    required this.monthsAgo,
    required this.weeksAgo,
    required this.everyYear,
    required this.everyMonth,
    required this.everyWeek,
    required this.lastNDays,
    required this.sameDay,
    required this.portrait,
    required this.landscape,
    required this.orientation,
    required this.kmFrom,
    required this.resolution,
    required this.rating,
    required this.personCount,
    required this.nSomeOf,
    required this.someOf,
    required this.or,
    required this.and,
    required this.date,
    required this.anyText,
    required this.caption,
    required this.directory,
    required this.fileName,
    required this.keyword,
    required this.person,
    required this.position,
  });

  factory QueryKeywords.defaults() {
    return QueryKeywords(
      nSomeOf: 'of',
      and: 'and',
      or: 'or',
      date: 'date',
      rating: 'rating',
      personCount: 'person-count',
      resolution: 'resolution',
      kmFrom: 'km-from',
      orientation: 'orientation',
      landscape: 'landscape',
      portrait: 'portrait',
      yearsAgo: '%d-years-ago',
      monthsAgo: '%d-months-ago',
      weeksAgo: '%d-weeks-ago',
      daysAgo: '%d-days-ago',
      everyYear: 'every-year',
      everyMonth: 'every-month',
      everyWeek: 'every-week',
      lastNDays: 'last-%d-days',
      sameDay: 'same-day',
      anyText: 'any-text',
      keyword: 'keyword',
      caption: 'caption',
      directory: 'directory',
      fileName: 'file-name',
      person: 'person',
      position: 'position',
      someOf: 'some-of',
    );
  }
}

class SearchQueryParser {
  final QueryKeywords keywords;

  SearchQueryParser({QueryKeywords? keywords}) : keywords = keywords ?? QueryKeywords.defaults();

  static String stringifyText(
    String text, [
    TextSearchQueryMatchTypes matchType = TextSearchQueryMatchTypes.like,
  ]) {
    if (matchType == TextSearchQueryMatchTypes.exactMatch) {
      return '"$text"';
    }
    if (text.contains(' ')) {
      return '($text)';
    }
    return text;
  }

  static String? stringifyDate(int? timestamp) {
    if (timestamp == null || timestamp == 0) {
      return null;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);

    // simplify date with year only if it's first of jan
    if (date.month == 1 && date.day == 1) {
      return date.year.toString();
    }
    return stringifyText(date.toIso8601String().substring(0, 10));
  }

  static int parseDate(String text) {
    String cleanText = text;

    if (cleanText.isNotEmpty && (cleanText[0] == '"' || cleanText[0] == '(')) {
      cleanText = cleanText.substring(1);
    }
    if (cleanText.isNotEmpty && (cleanText[cleanText.length - 1] == '"' || cleanText[cleanText.length - 1] == ')')) {
      cleanText = cleanText.substring(0, cleanText.length - 1);
    }

    // it is the year only
    if (cleanText.length == 4) {
      try {
        final year = int.parse(cleanText);
        return DateTime.utc(year, 1, 1).millisecondsSinceEpoch;
      } catch (e) {
        // ignore
      }
    }

    int? timestamp;

    // Parsing ISO string
    try {
      final parts = cleanText.split('-').map((t) => int.parse(t)).toList();
      if (parts.length == 2) {
        timestamp = DateTime.utc(parts[0], parts[1], 1).millisecondsSinceEpoch;
      } else if (parts.length == 3) {
        timestamp = DateTime.utc(parts[0], parts[1], parts[2]).millisecondsSinceEpoch;
      }
    } catch (e) {
      // ignoring errors
    }

    // If it could not parse as ISO string, try parsing as DateTime
    if (timestamp == null) {
      try {
        final parsed = DateTime.parse(cleanText);
        timestamp = parsed.millisecondsSinceEpoch;
      } catch (e) {
        // ignore
      }
    }

    if (timestamp == null) {
      throw Exception('Cannot parse date: $text');
    }

    return timestamp;
  }

  static String humanToRegexpStr(String str) {
    return str.replaceAll('%d', '\\d*');
  }

  SearchQueryDTO parse(String str, {bool implicitAND = true}) {
    String text = str
        .replaceAll(RegExp(r'\s\s+'), ' ') // remove double spaces
        .replaceAll(RegExp(r':\s+'), ':')
        .trim();

    int intFromRegexp(String str) {
      final numMatch = RegExp(r'\d+').firstMatch(str);
      if (numMatch == null) {
        return 0;
      }
      return int.parse(numMatch.group(0)!);
    }

    if (text.isNotEmpty && text[0] == '(' && text[text.length - 1] == ')') {
      text = text.substring(1, text.length - 1);
    }

    int firstSpace({int start = 0}) {
      final bracketIn = <int>[];
      bool quotationMark = false;

      for (int i = start; i < text.length; ++i) {
        if (text[i] == '"') {
          quotationMark = !quotationMark;
          continue;
        }
        if (text[i] == '(') {
          bracketIn.add(i);
          continue;
        }
        if (text[i] == ')') {
          bracketIn.removeLast();
          continue;
        }

        if (!quotationMark && bracketIn.isEmpty && text[i] == ' ') {
          return i;
        }
      }
      return text.length - 1;
    }

    // tokenize
    final tokenEnd = firstSpace();

    if (tokenEnd != text.length - 1) {
      if (text.startsWith(' ${keywords.and} ', tokenEnd)) {
        final rest = parse(
          text.substring(tokenEnd + (' ${keywords.and} ').length),
          implicitAND: implicitAND,
        );
        return ANDSearchQuery([
          parse(text.substring(0, tokenEnd), implicitAND: implicitAND),
          ...(rest is SearchListQuery ? rest.list : [rest]),
        ]);
      } else if (text.startsWith(' ${keywords.or} ', tokenEnd)) {
        final rest = parse(
          text.substring(tokenEnd + (' ${keywords.or} ').length),
          implicitAND: implicitAND,
        );
        return ORSearchQuery([
          parse(text.substring(0, tokenEnd), implicitAND: implicitAND),
          ...(rest is SearchListQuery ? rest.list : [rest]),
        ]);
      } else {
        // Relation cannot be detected
        final t = implicitAND ? SearchQueryTypes.and : SearchQueryTypes.unknownRelation;
        final rest = parse(text.substring(tokenEnd), implicitAND: implicitAND);
        final list = [
          parse(text.substring(0, tokenEnd), implicitAND: implicitAND),
          ...(rest is SearchListQuery && rest.type == t ? rest.list : [rest]),
        ];

        if (t == SearchQueryTypes.and) {
          return ANDSearchQuery(list);
        } else {
          return ANDSearchQuery(list);
        }
      }
    }

    if (text.startsWith('${keywords.someOf}:') || RegExp('^\\d*-${RegExp.escape(keywords.nSomeOf)}:').hasMatch(text)) {
      final prefix = text.startsWith('${keywords.someOf}:')
          ? '${keywords.someOf}:'
          : RegExp('^\\d*-${RegExp.escape(keywords.nSomeOf)}:').stringMatch(text)!;

      SearchQueryDTO tmpList = parse(
        text.substring(prefix.length + 1, text.length - 1),
        implicitAND: false,
      );

      List<SearchQueryDTO> unfoldList(SearchQueryDTO q) {
        if (q is SearchListQuery && q.list.isNotEmpty) {
          if (q.type == SearchQueryTypes.unknownRelation) {
            return q.list.expand((e) => unfoldList(e)).toList();
          } else {
            for (var e in q.list) {
              unfoldList(e);
            }
          }
        }
        return [q];
      }

      final unfolded = unfoldList(tmpList);
      int? minValue;
      if (RegExp('^\\d*-${RegExp.escape(keywords.nSomeOf)}:').hasMatch(text)) {
        final minMatch = RegExp(r'^\d*').stringMatch(text);
        if (minMatch != null && minMatch.isNotEmpty) {
          minValue = int.parse(minMatch);
        }
      }
      final ret = SomeOfSearchQuery(
        unfolded.cast<NegatableSearchQuery>(),
        min: minValue,
      );
      return ret;
    }

    // Parse range queries (date, rating, resolution, person_count)
    RangeSearch? range = _parseRangeQuery(text);
    if (range != null) {
      return range;
    }

    if (RegExp('^\\d*-${RegExp.escape(keywords.kmFrom)}!?:').hasMatch(text)) {
      var from = text.substring(
        RegExp('^\\d*-${RegExp.escape(keywords.kmFrom)}!?:').stringMatch(text)!.length,
      );

      if ((from.startsWith('(') && from.endsWith(')')) || (from.startsWith('"') && from.endsWith('"'))) {
        from = from.substring(1, from.length - 1);
      }

      // Check if the from part matches coordinate pattern (number, number)
      final coordMatch = RegExp(r'^\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*$').firstMatch(from);
      if (coordMatch != null) {
        // It's a coordinate pair
        final latitude = double.parse(coordMatch.group(1)!);
        final longitude = double.parse(coordMatch.group(2)!);
        return DistanceSearch(
          {
            'GPSData': {
              'latitude': latitude,
              'longitude': longitude,
            },
          },
          intFromRegexp(text).toDouble(),
          negate: RegExp('^\\d*-${RegExp.escape(keywords.kmFrom)}!:').hasMatch(text),
        );
      }

      // If not coordinates, treat as location text
      return DistanceSearch(
        {'value': from},
        intFromRegexp(text).toDouble(),
        negate: RegExp('^\\d*-${RegExp.escape(keywords.kmFrom)}!:').hasMatch(text),
      );
    }

    if (text.startsWith('${keywords.orientation}:')) {
      return OrientationSearch(
        text.substring('${keywords.orientation}:'.length) == keywords.landscape,
      );
    }

    if (_matchesKeyword(text, keywords.sameDay) ||
        RegExp('^${humanToRegexpStr(keywords.lastNDays)}!?:').hasMatch(text)) {
      final freqStr = !text.contains('!:')
          ? text.substring(text.indexOf(':') + 1)
          : text.substring(text.indexOf('!:') + 2);

      DatePatternFrequency? freq;
      int? ago;

      if (freqStr == keywords.everyWeek) {
        freq = DatePatternFrequency.everyWeek;
      } else if (freqStr == keywords.everyMonth) {
        freq = DatePatternFrequency.everyMonth;
      } else if (freqStr == keywords.everyYear) {
        freq = DatePatternFrequency.everyYear;
      } else if (RegExp('^${humanToRegexpStr(keywords.daysAgo)}\$').hasMatch(freqStr)) {
        freq = DatePatternFrequency.daysAgo;
        ago = intFromRegexp(freqStr);
      } else if (RegExp('^${humanToRegexpStr(keywords.weeksAgo)}\$').hasMatch(freqStr)) {
        freq = DatePatternFrequency.weeksAgo;
        ago = intFromRegexp(freqStr);
      } else if (RegExp('^${humanToRegexpStr(keywords.monthsAgo)}\$').hasMatch(freqStr)) {
        freq = DatePatternFrequency.monthsAgo;
        ago = intFromRegexp(freqStr);
      } else if (RegExp('^${humanToRegexpStr(keywords.yearsAgo)}\$').hasMatch(freqStr)) {
        freq = DatePatternFrequency.yearsAgo;
        ago = intFromRegexp(freqStr);
      }

      if (freq != null) {
        final daysLength = _matchesKeyword(text, keywords.sameDay) ? 0 : intFromRegexp(text);
        return DatePatternSearch(
          daysLength,
          freq,
          agoNumber: ago,
          negate:
              (RegExp('^${humanToRegexpStr(keywords.lastNDays)}!:').hasMatch(text) ||
              text.startsWith('${keywords.sameDay}!:')),
        );
      }
    }

    // parse text search
    final textSearchTypes = TextSearchQueryTypes.map((type) {
      final keywordName = _getKeywordForType(type);
      if (keywordName == null) return null;
      return (
        key: '$keywordName:',
        type: type,
        negate: false,
      );
    }).whereType<({String key, SearchQueryTypes type, bool negate})>().toList();

    final negatedTextSearchTypes = TextSearchQueryTypes.map((type) {
      final keywordName = _getKeywordForType(type);
      if (keywordName == null) return null;
      return (
        key: '$keywordName!:',
        type: type,
        negate: true,
      );
    }).whereType<({String key, SearchQueryTypes type, bool negate})>().toList();

    final allTextSearchTypes = [...textSearchTypes, ...negatedTextSearchTypes];

    for (final typeTmp in allTextSearchTypes) {
      if (text.startsWith(typeTmp.key)) {
        final afterKey = text.substring(typeTmp.key.length);

        // exact match
        if (afterKey.isNotEmpty && afterKey[0] == '"' && text[text.length - 1] == '"') {
          final textContent = afterKey.substring(1, afterKey.length - 1);
          return TextSearch(
            typeTmp.type,
            textContent,
            matchType: TextSearchQueryMatchTypes.exactMatch,
            negate: typeTmp.negate,
          );
          // like match
        } else if (afterKey.isNotEmpty && afterKey[0] == '(' && text[text.length - 1] == ')') {
          final textContent = afterKey.substring(1, afterKey.length - 1);
          return TextSearch(
            typeTmp.type,
            textContent,
            negate: typeTmp.negate,
          );
        } else {
          return TextSearch(
            typeTmp.type,
            afterKey,
            negate: typeTmp.negate,
          );
        }
      }
    }

    return TextSearch(SearchQueryTypes.anyText, text);
  }

  RangeSearch? _parseRangeQuery(String str) {
    // Regex pattern for parsing range queries
    // Examples: rating:4..6, rating:4, rating=4, rating!>3, rating>3, rating!>=3, rating>=3, etc.

    for (final keyword in [keywords.date, keywords.rating, keywords.resolution, keywords.personCount]) {
      final isDateType = keyword == keywords.date;
      final value = isDateType ? '(\\d{4}(?:-\\d{1,2})?(?:-\\d{1,2})?)' : '(\\d+)';

      final regex = RegExp('^${RegExp.escape(keyword)}(!?[:=]|!?[<>]=?)$value(?:\\.\\.$value)?\$');

      final m = regex.firstMatch(str);
      if (m == null) continue;

      String relation = m.group(1)!;
      final rawA = m.group(2)!;
      final rawB = m.group(3);

      final toValue = isDateType ? (String v) => parseDate(v) : (String v) => int.parse(v);

      final addValue = isDateType ? (int v, int a) => v + (a * 24 * 60 * 60 * 1000) : (int v, int a) => v + a;

      final a = toValue(rawA);
      final b = rawB != null ? toValue(rawB) : null;

      bool negate = false;
      if (relation.startsWith('!')) {
        negate = true;
        relation = relation.substring(1);
      }

      late RangeSearch result;

      if (relation == '=' || relation == ':') {
        if (b == null) {
          result = _createRangeSearch(keyword, min: a, max: a, negate: negate);
        } else {
          result = _createRangeSearch(keyword, min: a, max: b, negate: negate);
        }
      } else if (relation == '>=') {
        result = _createRangeSearch(keyword, min: a, negate: negate);
      } else if (relation == '>') {
        result = _createRangeSearch(keyword, min: addValue(a, 1), negate: negate);
      } else if (relation == '<=') {
        result = _createRangeSearch(keyword, max: a, negate: negate);
      } else if (relation == '<') {
        result = _createRangeSearch(keyword, max: addValue(a, -1), negate: negate);
      } else {
        continue;
      }

      return result;
    }

    return null;
  }

  RangeSearch _createRangeSearch(String keyword, {int? min, int? max, bool negate = false}) {
    if (keyword == keywords.date) {
      return DateSearch(min: min, max: max, negate: negate);
    } else if (keyword == keywords.rating) {
      return RatingSearch(min: min, max: max, negate: negate);
    } else if (keyword == keywords.resolution) {
      return ResolutionSearch(min: min, max: max, negate: negate);
    } else if (keyword == keywords.personCount) {
      return PersonCountSearch(min: min, max: max, negate: negate);
    }
    throw Exception('Unknown range search keyword: $keyword');
  }

  bool _matchesKeyword(String str, String keyword) {
    return str.startsWith('$keyword:') || str.startsWith('$keyword!:');
  }

  String? _getKeywordForType(SearchQueryTypes type) {
    switch (type) {
      case SearchQueryTypes.anyText:
        return keywords.anyText;
      case SearchQueryTypes.caption:
        return keywords.caption;
      case SearchQueryTypes.directory:
        return keywords.directory;
      case SearchQueryTypes.fileName:
        return keywords.fileName;
      case SearchQueryTypes.keyword:
        return keywords.keyword;
      case SearchQueryTypes.person:
        return keywords.person;
      case SearchQueryTypes.position:
        return keywords.position;
      default:
        return null;
    }
  }

  String stringify(SearchQueryDTO query) {
    final ret = _stringifyOnEntry(query);
    if (ret.isNotEmpty && ret[0] == '(' && ret[ret.length - 1] == ')') {
      return ret.substring(1, ret.length - 1);
    }
    return ret;
  }

  String _stringifyOnEntry(SearchQueryDTO query) {
    if (query.type == SearchQueryTypes.unknownRelation) {
      return '';
    }

    final negateSign = (query is NegatableSearchQuery && query.negate == true) ? '!' : '';
    final colon = '$negateSign:';

    switch (query.type) {
      case SearchQueryTypes.and:
        return '(${(query as SearchListQuery).list.map((q) => _stringifyOnEntry(q)).join(' ${keywords.and} ')})';

      case SearchQueryTypes.or:
        return '(${(query as SearchListQuery).list.map((q) => _stringifyOnEntry(q)).join(' ${keywords.or} ')})';

      case SearchQueryTypes.someOf:
        final someOfQuery = query as SomeOfSearchQuery;
        if (someOfQuery.min != null && someOfQuery.min != 0) {
          return '${someOfQuery.min}-${keywords.nSomeOf}:(${someOfQuery.list.map((q) => _stringifyOnEntry(q)).join(' ')})';
        }
        return '${keywords.someOf}:(${someOfQuery.list.map((q) => _stringifyOnEntry(q)).join(' ')})';

      case SearchQueryTypes.date:
        final dateQuery = query as DateSearch;
        return _stringifyRangeQuery(keywords.date, dateQuery, colon);

      case SearchQueryTypes.rating:
        final ratingQuery = query as RatingSearch;
        return _stringifyRangeQuery(keywords.rating, ratingQuery, colon);

      case SearchQueryTypes.resolution:
        final resQuery = query as ResolutionSearch;
        return _stringifyRangeQuery(keywords.resolution, resQuery, colon);

      case SearchQueryTypes.personCount:
        final personQuery = query as PersonCountSearch;
        return _stringifyRangeQuery(keywords.personCount, personQuery, colon);

      case SearchQueryTypes.distance:
        final distanceQuery = query as DistanceSearch;
        final from = distanceQuery.from;
        String? text = from['value'] as String?;
        final gpsData = from['GPSData'] as Map<String, dynamic>?;

        String locationStr = '';
        if (text != null) {
          locationStr = text;
        } else if (gpsData != null) {
          final lat = gpsData['latitude'];
          final lng = gpsData['longitude'];
          if (lat != null && lng != null) {
            locationStr = '${(lat as num).toStringAsFixed(6)}, ${(lng as num).toStringAsFixed(6)}';
          }
        }

        // Add brackets if the location string contains spaces
        if (locationStr.contains(' ')) {
          locationStr = '($locationStr)';
        }

        return '${distanceQuery.distance.toInt()}-${keywords.kmFrom}$colon$locationStr';

      case SearchQueryTypes.orientation:
        final orientationQuery = query as OrientationSearch;
        return '${keywords.orientation}:${orientationQuery.landscape ? keywords.landscape : keywords.portrait}';

      case SearchQueryTypes.datePattern:
        final datePatternQuery = query as DatePatternSearch;
        final daysLength = datePatternQuery.daysLength;
        String strBuilder = '';

        if (daysLength <= 0) {
          strBuilder += keywords.sameDay;
        } else {
          strBuilder += keywords.lastNDays.replaceAll('%d', daysLength.toString());
        }

        if (datePatternQuery.negate == true) {
          strBuilder += '!';
        }
        strBuilder += ':';

        switch (datePatternQuery.frequency) {
          case DatePatternFrequency.everyWeek:
            strBuilder += keywords.everyWeek;
            break;
          case DatePatternFrequency.everyMonth:
            strBuilder += keywords.everyMonth;
            break;
          case DatePatternFrequency.everyYear:
            strBuilder += keywords.everyYear;
            break;
          case DatePatternFrequency.daysAgo:
            strBuilder += keywords.daysAgo.replaceAll('%d', (datePatternQuery.agoNumber ?? 0).toString());
            break;
          case DatePatternFrequency.weeksAgo:
            strBuilder += keywords.weeksAgo.replaceAll('%d', (datePatternQuery.agoNumber ?? 0).toString());
            break;
          case DatePatternFrequency.monthsAgo:
            strBuilder += keywords.monthsAgo.replaceAll('%d', (datePatternQuery.agoNumber ?? 0).toString());
            break;
          case DatePatternFrequency.yearsAgo:
            strBuilder += keywords.yearsAgo.replaceAll('%d', (datePatternQuery.agoNumber ?? 0).toString());
            break;
        }

        return strBuilder;

      case SearchQueryTypes.anyText:
        final textQuery = query as TextSearch;
        if (textQuery.negate != true) {
          return stringifyText(textQuery.value, textQuery.matchType ?? TextSearchQueryMatchTypes.like);
        } else {
          return '${keywords.anyText}$colon${stringifyText(textQuery.value, textQuery.matchType ?? TextSearchQueryMatchTypes.like)}';
        }

      case SearchQueryTypes.person:
      case SearchQueryTypes.position:
      case SearchQueryTypes.keyword:
      case SearchQueryTypes.caption:
      case SearchQueryTypes.fileName:
      case SearchQueryTypes.directory:
        final textQuery = query as TextSearch;
        if (textQuery.value.isEmpty) {
          return '';
        }
        final keyword = _getKeywordForType(textQuery.type);
        if (keyword == null) {
          return '';
        }
        return '$keyword$colon${stringifyText(textQuery.value, textQuery.matchType ?? TextSearchQueryMatchTypes.like)}';

      default:
        throw Exception('Unknown type: ${query.type}');
    }
  }

  String _stringifyRangeQuery(String keyword, RangeSearch query, String colon) {
    final min = query.min;
    final max = query.max;

    if (min == null && max == null) {
      return '';
    }

    if (keyword == keywords.date) {
      if (min != null && max != null && min == max) {
        final dateStr = stringifyDate(min as int?);
        return dateStr != null ? '$keyword$colon$dateStr' : '';
      } else if (min != null && max != null) {
        final minStr = stringifyDate(min as int?);
        final maxStr = stringifyDate(max as int?);
        return '$keyword$colon$minStr..$maxStr';
      } else if (min != null) {
        final dateStr = stringifyDate(min as int?);
        return dateStr != null ? '$keyword$colon$dateStr' : '';
      } else if (max != null) {
        final dateStr = stringifyDate(max as int?);
        return dateStr != null ? '$keyword$colon$dateStr' : '';
      }
    } else {
      if (min != null && max != null && min == max) {
        return '$keyword$colon$min';
      } else if (min != null && max != null) {
        return '$keyword$colon$min..$max';
      } else if (min != null) {
        return '$keyword$colon$min';
      } else if (max != null) {
        return '$keyword$colon$max';
      }
    }

    return '';
  }
}
