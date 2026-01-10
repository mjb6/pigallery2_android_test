import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:pigallery2_android/data/backend/models/directory.dart';
import 'package:pigallery2_android/data/backend/models/search/auto_complete.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query_parser.dart';
import 'package:pigallery2_android/data/backend/models/search/search_result.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';

class ItemRepositoryImpl implements ItemRepository {
  final ApiService _api;

  ItemRepositoryImpl(this._api);

  @override
  Future<Directory?> search(SearchQueryDTO query) async {
    // SearchQueryDTO query = TextSearch(SearchQueryTypes.anyText, searchText);
    // if (baseDir != null){
    // query = ANDSearchQuery([
    //   TextSearch(SearchQueryTypes.directory, baseDir.relativeApiPath),
    //   query,
    // ]);
    // }
    BackendDirectory? result = (await _api.search(query))?.toDirectory(SearchQueryParser().stringify(query));
    // remove current directory from response
    // result?.directories.removeWhere((element) => element.apiPath == baseDir?.relativeApiPath);
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<Directory?> getDirectories({String? path}) async {
    BackendDirectory? result = await _api.getDirectories(path: path);
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  /// Combines [TopPicksQuery] with [RecentlyAddedQuery] to also show images from the current year.
  Future<Directory?> getTopPicks(int daysLength) async {
    SearchResult? topPicksResult = await _api.search(DatePatternSearch(daysLength, DatePatternFrequency.everyYear));
    SearchResult? recentlyAddedResult = await _api.search(
      DatePatternSearch(daysLength, DatePatternFrequency.yearsAgo, agoNumber: 0),
    );
    SearchResult? searchResult;
    if (topPicksResult == null && recentlyAddedResult == null) {
      searchResult = null;
    } else {
      final results = [topPicksResult, recentlyAddedResult].whereNot((it) => it == null).cast<SearchResult>();
      searchResult = SearchResult.combine(results);
    }
    BackendDirectory? result = searchResult?.toDirectory("");
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<Directory?> flattenDirectory(Directory? dir) async {
    String path = dir?.relativeApiPath ?? ".";
    TextSearch query;
    if (path.isEmpty || path == ".") {
      query = TextSearch(SearchQueryTypes.anyText, "");
    } else {
      query = TextSearch(SearchQueryTypes.directory, path);
    }
    BackendDirectory? result = (await _api.search(query))?.toDirectory(path);
    result?.directories.clear();
    return result?.let((it) => Directory.fromBackend(result));
  }

  @override
  Future<List<AutoCompleteItem>> autoComplete(AutoCompleteItem request) async {
    return await _api.autoComplete(request);
  }
}
