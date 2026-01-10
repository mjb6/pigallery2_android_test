import 'package:pigallery2_android/data/storage/models/sort_option.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:async/async.dart';
import 'package:pigallery2_android/domain/models/sort_option.dart';
import 'package:pigallery2_android/domain/repositories/album_repository.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/domain/repositories/sort_options_repository.dart';
import 'package:pigallery2_android/ui/shared/viewmodels/safe_change_notifier.dart';
import 'package:pigallery2_android/util/strings.dart';

import 'gallery_model_state.dart';

class GalleryModel extends SafeChangeNotifier {
  final AlbumRepository _albumRepository;
  final ItemRepository _itemRepository;
  final SortOptionsRepository _sortOptionsRepository;
  final List<GalleryModelState> _state;
  final bool isAlbumView;

  GalleryModel(this._albumRepository, this._itemRepository, this._sortOptionsRepository, this.isAlbumView)
    : _state = [GalleryModelState(DirectoryGalleryModelStateType(), null, _sortOptionsRepository)] {
    fetch();
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
    _addStack(GalleryModelState(DirectoryGalleryModelStateType(), baseDirectory, _sortOptionsRepository));
    fetch();
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
  Future<void> _apiRequest(CancelableOperation<Directory?> request, bool isRefresh) async {
    currentState.error = null;
    if (!isRefresh) _setIsLoadingDelayed(_currentRequest);

    return request.then((result) {
      _updateCurrentState(result);
      notifyListeners();
    }).value;
  }

  /// Cancels the previous request when invoking the given [request].
  Future<void> _cancelableApiRequest(Future<Directory?> Function() request, bool isRefresh) async {
    _currentRequest?.cancel();
    try {
      CancelableOperation<Directory?> cancelableRequest = CancelableOperation.fromFuture(request());
      _currentRequest = cancelableRequest;
      await _apiRequest(cancelableRequest, isRefresh);
    } on Exception catch (e) {
      _updateCurrentState(null);
      currentState.error = e.toString().replaceAll(Strings.exceptionPrefix, "");
      notifyListeners();
      return Future.value();
    }
  }

  Future<void> fetch({bool isRefresh = false}) => switch (currentState.type) {
    SearchGalleryModelStateType(:final directory, :final searchText) => _cancelableApiRequest(() {
      return _itemRepository.search(directory, searchText);
    }, isRefresh),
    FlattenGalleryModelStateType(:final target) => _cancelableApiRequest(() {
      return _itemRepository.flattenDirectory(target);
    }, isRefresh),
    DirectoryGalleryModelStateType() => _cancelableApiRequest(() {
      if (stackPosition == 0 && isAlbumView) {
        return _albumRepository.getAlbums();
      }
      Directory? baseDirectory = currentState.baseDirectory;
      if (baseDirectory is Album) {
        return _albumRepository.getAlbumContent(baseDirectory);
      }
      return _itemRepository.getDirectories(path: baseDirectory?.relativeApiPath);
    }, isRefresh),
    _ => Future.value(),
  };

  /// Start a search for the given text [searchText].
  /// Result will be available via [currentState].
  void textSearch(String searchText) {
    if (!currentState.isSearching) {
      var type = SearchGalleryModelStateType(directory: currentState.baseDirectory, searchText: searchText);
      _addStack(GalleryModelState(type, null, _sortOptionsRepository));
    }
    fetch();
  }

  /// Flatten the current directory.
  /// Result will be available via [currentState].
  void flattenDir() {
    var type = FlattenGalleryModelStateType(target: currentState.baseDirectory);
    _addStack(GalleryModelState(type, null, _sortOptionsRepository));
    fetch();
  }

  /// Add a new stack displaying the content of the given [directory]. No api requests done here.
  void topPicksSearch(Directory directory) {
    _addStack(GalleryModelState(TopPicksGalleryModelStateType(), directory, _sortOptionsRepository));
    currentState.items = directory.media;
    notifyListeners();
  }
}
