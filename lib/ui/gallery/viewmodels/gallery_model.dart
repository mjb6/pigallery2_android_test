import 'package:pigallery2_android/data/storage/models/sort_option.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/data/backend/api_service.dart';
import 'package:async/async.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/domain/repositories/album_repository.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/domain/repositories/sort_options_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';

import 'gallery_model_state.dart';

class GalleryModel extends SafeChangeNotifier {
  final AlbumRepository _albumRepository;
  final ItemRepository _itemRepository;
  final SortOptionsRepository _sortOptionsRepository;
  final List<GalleryModelState> _state;
  final bool isAlbumView;

  GalleryModel(this._albumRepository, this._itemRepository, this._sortOptionsRepository, this.isAlbumView)
    : _state = [GalleryModelState(null, _sortOptionsRepository)] {
    fetchItems();
  }

  /// [GalleryModelState] of the given position in the [Navigator] stack.
  GalleryModelState stateOf(int stackPosition) => _state[stackPosition];

  /// How many pages are on the [Navigator] stack.
  int get stackPosition => _state.length - 1;

  /// [GalleryModelState] of the top-most [HomeView] in the [Navigator] stack.
  GalleryModelState get currentState => _state.last;

  /// Whether a search page is currently shown via showSearch, but no search has been submitted yet.
  bool _isSearchPending = false;

  bool _searchOngoing = false;

  /// Whether a search page is currently shown via showSearch and has not yet been closed.
  bool get searchOngoing => _searchOngoing;

  CancelableOperation<Directory?>? _currentRequest;

  SortOption get sortOption => currentState.sortOption;

  void setSortType(SortType type) {
    if (sortOption.onlyThisFolder) {
      currentState.sortType = type;
    } else {
      for (GalleryModelState state in _state) {
        if (!state.sortOption.onlyThisFolder) {
          state.sortType = type;
        }
      }
    }

    _sortOptionsRepository.storeSortOption(
      sortOption.onlyThisFolder ? currentState.sortingKey : null,
      SortOption(order: currentState.sortOption.order, type: type, onlyThisFolder: sortOption.onlyThisFolder),
    );
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    if (sortOption.onlyThisFolder) {
      currentState.sortOrder = order;
    } else {
      for (GalleryModelState state in _state) {
        if (!state.sortOption.onlyThisFolder) {
          state.sortOrder = order;
        }
      }
    }

    _sortOptionsRepository.storeSortOption(
      sortOption.onlyThisFolder ? currentState.sortingKey : null,
      SortOption(order: order, type: currentState.sortOption.type, onlyThisFolder: sortOption.onlyThisFolder),
    );
    notifyListeners();
  }

  void setSortOnlyThisFolder(bool onlyThisFolder) {
    SortingKey? sortingKey = currentState.sortingKey;
    if (!onlyThisFolder) {
      if (sortingKey != null) {
        _sortOptionsRepository.deleteSortOption(sortingKey);
      }
      SortOption sortOption = _sortOptionsRepository.getSortOption(sortingKey);
      currentState.sortOrder = sortOption.order;
      currentState.sortType = sortOption.type;
    } else {
      _sortOptionsRepository.storeSortOption(sortingKey, currentState.sortOption);
    }
    currentState.sortOnlyThisFolder = onlyThisFolder;
    notifyListeners();
  }

  void _addStack(GalleryModelState state) {
    _isSearchPending = false;
    _state.add(state);
  }

  /// Register a new [HomeView] instance.
  void addStack(Directory baseDirectory) {
    _addStack(GalleryModelState(baseDirectory, _sortOptionsRepository));
    fetchItems();
  }

  /// Unregister a closed [HomeView] instance.
  void popStack() {
    if (_state.length == 1) {
      // never remove last screen; should be unreachable
      return;
    }
    _currentRequest?.cancel();
    _currentRequest = null;
    _state.removeLast();
    _isSearchPending = false;
  }

  void startSearch() {
    _isSearchPending = true;
    _searchOngoing = true;
  }

  void stopSearch() {
    if (!_isSearchPending) {
      popStack();
    }
    _isSearchPending = false;
    _searchOngoing = false;
    notifyListeners();
  }

  void topPicksSearch(Directory directory) {
    _addStack(GalleryModelState.searching(_sortOptionsRepository, TopPicksSortingKey(), baseDirectory: directory));
    currentState.items = directory.media;
    notifyListeners();
  }

  /// Update [currentState] to represent the given [Directory].
  void _updateCurrentState(Directory? result) {
    currentState.isLoading = false;
    if (result != null) {
      currentState.baseDirectory = result;
      currentState.sortingKey ??= DirectorySortingKey(result.relativeApiPath);
      currentState.sortOption = _sortOptionsRepository.getSortOption(currentState.sortingKey);
      currentState.items = [...result.directories, ...result.media];
    } else {
      currentState.items = [];
    }
  }

  /// Set [isLoading] if the request takes more than 200ms.
  /// Leads to a smoother transition if the loading screen would only be shown for a short time.
  void _setIsLoadingDelayed(CancelableOperation? request) {
    Future.delayed(const Duration(milliseconds: 200), () {
      return request == null || request.isCanceled || request.isCompleted;
    }).then((isRequestFinished) {
      if (!isRequestFinished) {
        currentState.isLoading = true;
        notifyListeners();
      }
    });
  }

  /// Perform the given api request & update the state according to the progress/result.
  Future<void> _apiRequest(CancelableOperation<Directory?> request) async {
    currentState.error = null;
    _setIsLoadingDelayed(_currentRequest);

    return request.then((result) {
      _updateCurrentState(result);
      notifyListeners();
    }).value;
  }

  /// Cancels the previous request when invoking the given [request].
  void _cancelableApiRequest(Future<Directory?> Function() request) async {
    _currentRequest?.cancel();
    try {
      CancelableOperation<Directory?> cancelableRequest = CancelableOperation.fromFuture(request());
      _currentRequest = cancelableRequest;
      await _apiRequest(cancelableRequest);
    } on Exception catch (e) {
      _updateCurrentState(null);
      currentState.error = e.toString();
      notifyListeners();
      return Future.value();
    }
  }

  /// Request [Item]s from the [ApiService] for the current [HomeView] screen.
  /// Result will be available via [currentState].
  void fetchItems() {
    _cancelableApiRequest(() {
      if (stackPosition == 0 && isAlbumView) {
        return _albumRepository.getAlbums();
      }
      Directory? baseDirectory = currentState.baseDirectory;
      if (baseDirectory is Album) {
        return _albumRepository.getAlbumContent(baseDirectory);
      }
      return _itemRepository.getDirectories(path: baseDirectory?.relativeApiPath);
    });
  }

  /// Start a search for the given text [searchText].
  /// Result will be available via [currentState].
  void textSearch(String searchText) {
    if (!currentState.isSearching) {
      _addStack(GalleryModelState.searching(_sortOptionsRepository, SearchSortingKey(), title: searchText));
    }
    Directory? baseDir;
    if (stackPosition > 1) baseDir = _state.reversed.skip(1).first.baseDirectory;
    _cancelableApiRequest(() {
      return _itemRepository.search(baseDir, searchText);
    });
  }

  /// Flatten the current directory.
  /// Result will be available via [currentState].
  void flattenDir() {
    Directory? dirToFlatten = currentState.baseDirectory;
    _addStack(GalleryModelState.searching(_sortOptionsRepository, FlattenSortingKey(), title: dirToFlatten?.name));
    _cancelableApiRequest(() {
      return _itemRepository.flattenDirectory(dirToFlatten);
    });
  }
}
