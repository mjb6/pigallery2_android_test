import 'package:collection/collection.dart';
import 'package:pigallery2_android/data/storage/models/sort_option.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/domain/repositories/sort_options_repository.dart';
import 'package:pigallery2_android/util/extensions.dart';

/// Represents the data to be displayed for the current [HomeView].
class GalleryModelState {
  /// [Directory] received from the backend.
  Directory? baseDirectory;

  String? _title;

  String get title => _title ?? baseDirectory?.name ?? "";

  /// Whether this state represents a search result.
  bool isSearching = false;

  /// Whether to show a loading indicator.
  bool isLoading = false;

  /// Error received from the backend.
  String? error;

  late SortOption _sortOption;

  /// Selected [SortOption] to be applied to [items].
  SortOption get sortOption => _sortOption;

  List<Media> _media = List.unmodifiable([]);

  List<Directory> _directories = List.unmodifiable([]);

  /// [Item]s received from the backend.
  List<Item> get items => List<Item>.unmodifiable([..._directories, ..._media]);

  set items(List<Item> val) {
    _media = List.unmodifiable(_sort(val.whereType<Media>().toList()));
    _directories = List.unmodifiable(_sort(val.whereType<Directory>().toList()));
  }

  /// All [items] of type [Media].
  List<Media> get media => _media;

  /// All [items] of type [Directory].
  List<Directory> get directories => _directories;

  /// Key for fetching the sort options stored for this [GalleryModelState].
  /// [Null] if nothing fetched yet or no server configured.
  SortingKey? sortingKey;

  GalleryModelState(this.baseDirectory, SortOptionsRepository repo)
    : sortingKey = baseDirectory?.let((it) => DirectorySortingKey(it.relativeApiPath)) {
    _sortOption = repo.getSortOption(sortingKey);
  }

  GalleryModelState.searching(SortOptionsRepository repo, this.sortingKey, {String? title, this.baseDirectory})
    : _title = title,
      isSearching = true {
    _sortOption = repo.getSortOption(sortingKey);
  }

  //region sorting
  set sortOption(SortOption newSortOption) {
    sortType = newSortOption.type;
    sortOrder = newSortOption.order;
    sortOnlyThisFolder = newSortOption.onlyThisFolder;
  }

  set sortType(SortType type) {
    if (type != sortOption.type || type == SortType.random) {
      _sortOption = sortOption.copyWith(type: type);
      _media = List.unmodifiable(_sort(_media.toList()));
      _directories = List.unmodifiable(_sort(_directories.toList()));
    }
  }

  set sortOnlyThisFolder(bool onlyThisFolder) {
    if (sortOption.onlyThisFolder != onlyThisFolder) {
      _sortOption = _sortOption.copyWith(onlyThisFolder: onlyThisFolder);
    }
  }

  set sortOrder(SortOrder order) {
    if (sortOption.order != order) {
      _sortOption = sortOption.copyWith(order: order);
      _media = List.unmodifiable(_media.reversed);
      _directories = List.unmodifiable(_directories.reversed);
    }
  }

  List<Item> _sort(List<Item> toSort) {
    if (sortOption.type == SortType.random) toSort.shuffle();
    toSort.sort(_compare(sortOption.type));
    return sortOption.order == SortOrder.asc ? toSort : toSort.reversed.toList();
  }

  int _compareItems(Item a, Item b, SortType? sortType) {
    return switch (sortType) {
      SortType.date => a.metadata.date.compareTo(b.metadata.date),
      SortType.name => compareNatural(a.name.toLowerCase(), b.name.toLowerCase()),
      SortType.size => a.metadata.size.compareTo(b.metadata.size),
      SortType.random => 1,
      null => a.id.compareTo(b.id),
    };
  }

  int Function(Item, Item) _compare(SortType? sortType) {
    // Create consistent results by sorting by name or id if items are equal according to the current sort option.
    return (Item a, Item b) {
      int result = _compareItems(a, b, sortType);
      if (result != 0) return result;

      if (sortType != SortType.name) {
        result = _compareItems(a, b, SortType.name);
        if (result != 0) return result;
      }
      return _compareItems(a, b, null);
    };
  }
  //endregion
}
