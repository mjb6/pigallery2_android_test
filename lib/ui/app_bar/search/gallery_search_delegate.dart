import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/backend/models/search/auto_complete.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query_parser.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/domain/models/item.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'package:pigallery2_android/ui/app_bar/actions/sort_option_button.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model.dart';
import 'package:pigallery2_android/ui/gallery/gallery_view.dart';
import 'package:pigallery2_android/ui/gallery/viewmodels/gallery_model_provider.dart';
import 'package:pigallery2_android/ui/home/viewmodels/tab_state_model.dart';
import 'package:pigallery2_android/ui/themes.dart';
import 'package:provider/provider.dart';

// UI Configuration constants
const double _suggestionsChipHeight = 60;
const double _suggestionsChipHorizontalPadding = 8;
const double _suggestionsChipSpacing = 8;
const Duration _autocompleteDebounce = Duration(milliseconds: 250);

class GallerySearchDelegate extends SearchDelegate<String> {
  final int baseStackPosition;
  final Directory? baseDirectory;

  GallerySearchDelegate(this.baseStackPosition, {this.baseDirectory}) {
    if (baseDirectory != null && (query.isEmpty)) {
      // prefill query so user can remove it if desired
      query = '${SearchQueryParser().keywords.directory}:${baseDirectory!.relativeApiPath} ';
    }
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.appBarTheme.backgroundColor,
        titleTextStyle: theme.textTheme.titleLarge,
        toolbarTextStyle: theme.textTheme.bodyMedium,
        iconTheme: theme.iconTheme,
        toolbarHeight: toolbarHeight,
      ),
      // scaffoldBackgroundColor: theme.colorScheme.surface.withAlpha(100),
      inputDecorationTheme:
          searchFieldDecorationTheme ??
          InputDecorationTheme(
            hintStyle: searchFieldStyle ?? theme.inputDecorationTheme.hintStyle,
            border: InputBorder.none,
          ),
    );
  }

  @override
  void close(BuildContext context, String result) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    super.close(context, result);
  }

  void clearInput(BuildContext context) {
    query = '';
    showSuggestions(context);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => clearInput(context),
      ),
      const SortOptionWidget(),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, query),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Parse the query into a SearchQueryDTO using SearchQueryParser and forward it
    try {
      final dto = SearchQueryParser().parse(query);
      context.read<GalleryModelProvider>().model!.search(dto);
    } catch (e) {
      // fallback to passing the raw text as any-text search
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid search query: ${e.toString()}')));
    }

    return Provider.value(
      value: TabEntry.home,
      builder: (context, child) => ChangeNotifierProvider<GalleryModel>.value(
        value: context.read<GalleryModelProvider>().getModelByTab(0),
        child: GalleryView(baseStackPosition + 1),
      ),
    );
  }

  // scheduleFetch was moved into the _SuggestionsOverlay widget to avoid capturing
  // the outer BuildContext across async gaps. Suggestion fetching logic lives in the
  // widget's State instead.

  /// Returns the currently visible [GalleryView] with a suggestions overlay on top.
  /// While the user is editing, show a fullscreen suggestions overlay containing
  /// keyword tokens and merged autocomplete suggestions (from [ItemRepository]).
  @override
  Widget buildSuggestions(BuildContext context) {
    final parser = SearchQueryParser();
    final keywords = parser.keywords;

    // Use a dedicated widget to handle suggestions and async fetching (debounce, stream)
    final allKeywords = <_KeywordInfo>[
      _KeywordInfo(key: '${keywords.directory}:', icon: Icons.folder_outlined),
      _KeywordInfo(key: '${keywords.fileName}:', icon: Icons.description_outlined),
      _KeywordInfo(key: '${keywords.caption}:', icon: Icons.comment_outlined),
      _KeywordInfo(key: '${keywords.person}:', icon: Icons.person_outline),
      _KeywordInfo(key: '${keywords.orientation}:', icon: Icons.screen_rotation_outlined),
      _KeywordInfo(key: '${keywords.from}:', icon: Icons.date_range_outlined),
      _KeywordInfo(key: '${keywords.to}:', icon: Icons.date_range_outlined),
      _KeywordInfo(key: '${keywords.anyText}:', icon: Icons.search_outlined),
    ];
    GalleryModel model = context.read<GalleryModelProvider>().model!;
    int pos = model.stackPosition == baseStackPosition + 1 ? model.stackPosition : baseStackPosition;
    return Stack(
      children: [
        // Show gallery results in the background
        Provider.value(
          value: TabEntry.home,
          builder: (context, child) => ChangeNotifierProvider<GalleryModel>.value(
            value: context.read<GalleryModelProvider>().getModelByTab(0),
            child: GalleryView(pos),
          ),
        ),
        // Overlay suggestions on top
        _SuggestionsOverlay(
          query: query,
          keywords: allKeywords,
          onInsertToken: (token) {
            _replaceOrAppendToken(token);
          },
          onApplyItem: (item, ctx) {
            _applyAutoCompleteItem(item);
            showResults(ctx);
          },
        ),
      ],
    );
  }

  void _replaceOrAppendToken(String insertion) {
    final trimmedLeft = query.trimLeft();
    final leadingSpaces = query.length - trimmedLeft.length;
    final tokens = trimmedLeft.split(RegExp(r'\s+'));
    if (tokens.isEmpty || trimmedLeft.isEmpty) {
      query = ' ' * leadingSpaces + insertion;
      return;
    }

    final last = tokens.last;
    final index = trimmedLeft.lastIndexOf(last);
    final prefix = trimmedLeft.substring(0, index);
    query = ' ' * leadingSpaces + prefix + insertion;
  }

  /// Wraps text in quotes if it contains spaces and escapes internal quotes
  String _wrapIfNeeded(String text) {
    if (text.contains(' ')) {
      final escaped = text.replaceAll('"', '\\"');
      return '"$escaped"';
    }
    return text;
  }

  /// Returns the backend search keyword for the given type
  String? _getKeywordForType(SearchQueryTypes type) {
    final parser = SearchQueryParser();
    final keywords = parser.keywords;
    final metadata = _searchTypeMetadata[type];

    if (metadata?.keyword == null) return null;

    return switch (metadata!.keyword!) {
      'directory' => keywords.directory,
      'fileName' => keywords.fileName,
      'caption' => keywords.caption,
      'person' => keywords.person,
      'position' => keywords.position,
      'keyword' => keywords.keyword,
      _ => null,
    };
  }

  void _applyAutoCompleteItem(AutoCompleteItem item) {
    final trimmedLeft = query.trimLeft();
    final leadingSpaces = query.length - trimmedLeft.length;
    final tokens = trimmedLeft.split(RegExp(r'\s+'));

    final keyword = _getKeywordForType(item.type);
    final wrapped = _wrapIfNeeded(item.text);
    final replacementToken = keyword != null ? '$keyword:$wrapped' : wrapped;

    if (tokens.isEmpty || trimmedLeft.isEmpty) {
      query = '${' ' * leadingSpaces}$replacementToken ';
      return;
    }

    final last = tokens.last;
    final index = trimmedLeft.lastIndexOf(last);
    final prefix = trimmedLeft.substring(0, index);
    query = '${' ' * leadingSpaces}${prefix.isEmpty ? '' : prefix}$replacementToken ';
  }
}

class _KeywordInfo {
  final String key;
  final IconData icon;

  _KeywordInfo({required this.key, required this.icon});
}

/// Unified mapping of SearchQueryTypes to UI and backend metadata
class _SearchTypeMetadata {
  final IconData icon;
  final String subtitle;
  final String? keyword;

  const _SearchTypeMetadata({
    required this.icon,
    required this.subtitle,
    this.keyword,
  });
}

const Map<SearchQueryTypes, _SearchTypeMetadata> _searchTypeMetadata = {
  SearchQueryTypes.directory: _SearchTypeMetadata(
    icon: Icons.folder_outlined,
    subtitle: 'Directory',
    keyword: 'directory',
  ),
  SearchQueryTypes.fileName: _SearchTypeMetadata(
    icon: Icons.description_outlined,
    subtitle: 'File name',
    keyword: 'fileName',
  ),
  SearchQueryTypes.caption: _SearchTypeMetadata(
    icon: Icons.comment_outlined,
    subtitle: 'Caption',
    keyword: 'caption',
  ),
  SearchQueryTypes.person: _SearchTypeMetadata(
    icon: Icons.person_outline,
    subtitle: 'Person',
    keyword: 'person',
  ),
  SearchQueryTypes.keyword: _SearchTypeMetadata(
    icon: Icons.local_offer_outlined,
    subtitle: 'Keyword',
    keyword: 'keyword',
  ),
  SearchQueryTypes.position: _SearchTypeMetadata(
    icon: Icons.location_on_outlined,
    subtitle: 'Position',
    keyword: 'position',
  ),
  SearchQueryTypes.orientation: _SearchTypeMetadata(
    icon: Icons.screen_rotation_outlined,
    subtitle: 'Orientation',
  ),
  SearchQueryTypes.fromDate: _SearchTypeMetadata(
    icon: Icons.date_range_outlined,
    subtitle: 'After date',
  ),
  SearchQueryTypes.toDate: _SearchTypeMetadata(
    icon: Icons.date_range_outlined,
    subtitle: 'Before date',
  ),
};

class _SuggestionsOverlay extends StatefulWidget {
  final String query;
  final List<_KeywordInfo> keywords;
  final void Function(String token) onInsertToken;
  final void Function(AutoCompleteItem item, BuildContext ctx) onApplyItem;

  const _SuggestionsOverlay({
    required this.query,
    required this.keywords,
    required this.onInsertToken,
    required this.onApplyItem,
  });

  @override
  State<_SuggestionsOverlay> createState() => _SuggestionsOverlayState();
}

class _SuggestionsOverlayState extends State<_SuggestionsOverlay> {
  Timer? _debounce;
  List<AutoCompleteItem> _suggestions = [];
  bool _isLoading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scheduleFetch(widget.query);
  }

  @override
  void didUpdateWidget(covariant _SuggestionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _scheduleFetch(widget.query);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Handles date picker for from/to keywords
  Future<void> _handleDatePicker(String keyword) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.utc(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final ts = picked.toUtc().millisecondsSinceEpoch;
      final dateStr = SearchQueryParser.stringifyDate(ts);
      widget.onInsertToken('$keyword$dateStr');
    }
  }

  /// Handles orientation picker for orientation keyword
  Future<void> _handleOrientationPicker() async {
    final parser = SearchQueryParser();
    final keywords = parser.keywords;

    final selected = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.screen_lock_portrait_outlined),
              title: const Text('Portrait'),
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.screen_lock_landscape_outlined),
              title: const Text('Landscape'),
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      final value = selected ? keywords.landscape : keywords.portrait;
      widget.onInsertToken('${keywords.orientation}:$value');
    } else {
      widget.onInsertToken('${keywords.orientation}:');
    }
  }

  /// Determines backend input and type for autocomplete suggestions based on query
  void _scheduleFetch(String q) {
    _debounce?.cancel();
    final parser = SearchQueryParser();
    final keywords = parser.keywords;
    final repo = Provider.of<ItemRepository>(context, listen: false);

    // Build keyword to type mapping from metadata
    final keywordToType = <String, SearchQueryTypes>{};
    _searchTypeMetadata.forEach((type, metadata) {
      if (metadata.keyword != null) {
        final keyword = switch (metadata.keyword!) {
          'directory' => keywords.directory,
          'fileName' => keywords.fileName,
          'caption' => keywords.caption,
          'person' => keywords.person,
          'position' => keywords.position,
          'keyword' => keywords.keyword,
          _ => null,
        };
        if (keyword != null) {
          keywordToType[keyword] = type;
        }
      }
    });

    String? backendInput;
    SearchQueryTypes? type;

    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      backendInput = null;
    } else {
      final tokens = trimmed.split(RegExp(r'\s+'));
      final last = tokens.last;
      if (last.contains(':')) {
        final idx = last.indexOf(':');
        final key = last.substring(0, idx);
        final after = last.substring(idx + 1);
        type = keywordToType[key];
        if (after.isEmpty) {
          backendInput = '$key:';
        } else {
          backendInput = after;
        }
      } else if (tokens.length >= 2 && tokens.take(tokens.length - 1).any((t) => t.contains(':'))) {
        final tokenWithColon = tokens.take(tokens.length - 1).lastWhere((t) => t.contains(':'));
        final idx = tokenWithColon.indexOf(':');
        final key = tokenWithColon.substring(0, idx);
        final after = tokenWithColon.substring(idx + 1);
        if (after.isEmpty) {
          type = keywordToType[key];
        } else {
          type = null;
        }
        backendInput = last;
      } else {
        backendInput = last;
      }
    }

    if (backendInput == null || backendInput.isEmpty) {
      setState(() {
        _isLoading = false;
        _suggestions = [];
      });
      return;
    }

    final thisReq = ++_requestId;
    _debounce = Timer(_autocompleteDebounce, () async {
      setState(() {
        _isLoading = true;
        _suggestions = [];
      });

      try {
        final request = AutoCompleteItem(backendInput!, type ?? SearchQueryTypes.anyText);
        final res = await repo.autoComplete(request);
        if (thisReq == _requestId && mounted) {
          setState(() {
            _isLoading = false;
            _suggestions = res;
          });
        }
      } catch (e) {
        if (thisReq == _requestId && mounted) {
          setState(() {
            _isLoading = false;
            _suggestions = [];
          });
        }
      }
    });
  }

  Widget _iconForType(SearchQueryTypes type) {
    final metadata = _searchTypeMetadata[type];
    if (metadata != null) {
      return Icon(metadata.icon);
    }
    return const Icon(Icons.search_outlined);
  }

  String _subtitleForType(SearchQueryTypes type) {
    return _searchTypeMetadata[type]?.subtitle ?? '';
  }

  /// Handles keyword chip presses with special logic for date/orientation pickers
  Future<void> _handleKeywordChipPress(String keywordWithColon) async {
    final parser = SearchQueryParser();
    final keywords = parser.keywords;

    if (keywordWithColon == '${keywords.from}:') {
      await _handleDatePicker(keywordWithColon);
    } else if (keywordWithColon == '${keywords.to}:') {
      await _handleDatePicker(keywordWithColon);
    } else if (keywordWithColon == '${keywords.orientation}:') {
      await _handleOrientationPicker();
    } else {
      widget.onInsertToken(keywordWithColon);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleKeywords = () {
      final trimmed = widget.query.trimLeft();
      final keywordFilter = trimmed.isEmpty ? '' : trimmed.split(RegExp(r'\s+')).last;
      if (keywordFilter.isEmpty) return widget.keywords;
      return widget.keywords
          .where(
            (k) => k.key.startsWith(keywordFilter),
          )
          .toList();
    }();

    return SafeArea(
      child: Material(
        color: Theme.of(context).colorScheme.surface.withAlpha(240),
        child: Column(
          children: [
            // Keywords scroller
            if (visibleKeywords.isNotEmpty)
              Material(
                color: Theme.of(context).colorScheme.surface.withAlpha(200),
                child: SizedBox(
                  height: _suggestionsChipHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: _suggestionsChipHorizontalPadding),
                    itemBuilder: (context, index) {
                      final k = visibleKeywords[index];
                      return ActionChip(
                        avatar: Icon(k.icon, size: 16),
                        label: Text(k.key, style: const TextStyle(fontSize: 13)),
                        onPressed: () => _handleKeywordChipPress(k.key),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: _suggestionsChipSpacing),
                    itemCount: visibleKeywords.length,
                  ),
                ),
              ),

            const Divider(height: 1),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_suggestions.isEmpty
                        ? Center(
                            child: Text(
                              widget.query.trim().isEmpty ? 'Type to get suggestions' : 'No suggestions',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _suggestions.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final s = _suggestions[i];
                              return ListTile(
                                leading: _iconForType(s.type),
                                title: Text(s.text),
                                subtitle: Text(_subtitleForType(s.type)),
                                onTap: () => widget.onApplyItem(s, context),
                              );
                            },
                          )),
            ),
          ],
        ),
      ),
    );
  }
}
