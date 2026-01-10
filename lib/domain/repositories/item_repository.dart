import 'package:pigallery2_android/data/backend/models/search/auto_complete.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/domain/models/item.dart';

abstract interface class ItemRepository {
  Future<Directory?> search(SearchQueryDTO query);

  Future<Directory?> getDirectories({String? path});

  Future<Directory?> getTopPicks(int daysLength);

  Future<Directory?> flattenDirectory(Directory? dir);

  Future<List<AutoCompleteItem>> autoComplete(AutoCompleteItem request);
}
