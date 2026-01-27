import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pigallery2_android/data/backend/models/search/auto_complete.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query_parser.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'keyword_chips.dart';
import 'date_picker_dialog.dart' as date_dialog;
import 'rating_picker_dialog.dart';
import 'resolution_picker_dialog.dart';
import 'last_n_days_picker_dialog.dart';
import 'orientation_picker_dialog.dart';
import 'search_type_helper.dart';

const Duration _autocompleteDebounce = Duration(milliseconds: 250);

class SuggestionsOverlay extends StatefulWidget {
  final String query;
  final dynamic keywords; // SearchQueryParser.keywords object
  final void Function(String token) onInsertToken;
  final void Function(AutoCompleteItem item, BuildContext ctx) onApplyItem;
  final void Function(String newQuery) onReplaceQuery;
  final void Function(String token) onEditToken;

  const SuggestionsOverlay({
    super.key,
    required this.query,
    required this.keywords,
    required this.onInsertToken,
    required this.onApplyItem,
    required this.onReplaceQuery,
    required this.onEditToken,
  });

  @override
  State<SuggestionsOverlay> createState() => _SuggestionsOverlayState();
}

class _SuggestionsOverlayState extends State<SuggestionsOverlay> {
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
  void didUpdateWidget(covariant SuggestionsOverlay oldWidget) {
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

  void _scheduleFetch(String q) {
    _debounce?.cancel();
    final keywordsObj = widget.keywords;
    final repo = Provider.of<ItemRepository>(context, listen: false);

    final keywordToType = <String, SearchQueryTypes>{};
    // small mapping
    keywordToType[keywordsObj.directory] = SearchQueryTypes.directory;
    keywordToType[keywordsObj.fileName] = SearchQueryTypes.fileName;
    keywordToType[keywordsObj.caption] = SearchQueryTypes.caption;
    keywordToType[keywordsObj.person] = SearchQueryTypes.person;
    keywordToType[keywordsObj.position] = SearchQueryTypes.position;
    keywordToType[keywordsObj.keyword] = SearchQueryTypes.keyword;

    String? backendInput;
    SearchQueryTypes? type;

    // If the whole query is empty -> no suggestions
    if (q.trim().isEmpty) {
      backendInput = null;
    } else {
      final trailingSpace = RegExp(r'\s$').hasMatch(q);
      final tokenRegex = RegExp(r'"[^"]*"|\([^)]+\)|\S+');
      final matches = tokenRegex.allMatches(q).map((m) => m.group(0)!).toList();
      final lastToken = matches.isEmpty ? null : matches.last;

      if (trailingSpace) {
        // don't query on plain trailing space (backend doesn't support empty inputs)
        backendInput = null;
      } else {
        if (lastToken == null) {
          backendInput = null;
        } else if (lastToken.contains(':')) {
          final idx = lastToken.indexOf(':');
          final key = lastToken.substring(0, idx);
          final after = lastToken.substring(idx + 1);
          type = keywordToType[key];
          if (after.isEmpty) {
            // don't query yet, wait for at least one character after colon
            backendInput = null;
          } else {
            backendInput = after; // keep quotes/parenthesis intact
          }
        } else if (matches.length >= 2 && matches.take(matches.length - 1).any((t) => t.contains(':'))) {
          final tokenWithColon = matches.take(matches.length - 1).lastWhere((t) => t.contains(':'));
          final idx = tokenWithColon.indexOf(':');
          final key = tokenWithColon.substring(0, idx);
          final after = tokenWithColon.substring(idx + 1);
          if (after.isEmpty) {
            type = keywordToType[key];
          } else {
            type = null;
          }
          // send only the current last token (keeps quoted tokens intact), do not send the full query
          backendInput = lastToken;
        } else {
          // no keyword context; only autocomplete for the current token.
          // If the current token is a quoted or parenthesis group (kept together by the tokenizer), it may include spaces — send it as-is.
          backendInput = lastToken;
        }
      }
    }

    if (backendInput == null) {
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
        // Clean surrounding quotes or parentheses so the backend receives the raw token
        String cleanInput = backendInput!;
        if ((cleanInput.length >= 2 && cleanInput.startsWith('"') && cleanInput.endsWith('"')) ||
            (cleanInput.length >= 2 && cleanInput.startsWith('(') && cleanInput.endsWith(')'))) {
          cleanInput = cleanInput.substring(1, cleanInput.length - 1);
        }

        final request = AutoCompleteItem(cleanInput, type ?? SearchQueryTypes.anyText);
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
    final typeStr = type.name;
    return SearchTypeHelper.iconForType(typeStr);
  }

  String _subtitleForType(SearchQueryTypes type) {
    final typeStr = type.name;
    return SearchTypeHelper.subtitleForType(typeStr);
  }

  Future<void> _handleDatePicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const date_dialog.DateSearchPickerDialog(),
    );

    if (result != null) {
      widget.onInsertToken(result);
    }
  }

  Future<void> _handleLastNDaysPicker() async {
    final result = await showDialog<({int days, bool isRecurring, String unit, int count})>(
      context: context,
      builder: (context) => const LastNDaysPickerDialog(),
    );

    if (result != null) {
      final parser = SearchQueryParser();
      final keywords = parser.keywords;

      final daysStr = keywords.lastNDays.replaceAll('%d', result.days.toString());

      final frequencyStr = result.isRecurring ? 'every-${result.unit}' : '${result.count}-${result.unit}s-ago';

      widget.onInsertToken('$daysStr:$frequencyStr');
    }
  }

  Future<void> _handleRatingPicker() async {
    final result = await showDialog<({int rating, String operator, bool negated})>(
      context: context,
      builder: (context) => const RatingPickerDialog(),
    );

    if (result != null) {
      widget.onInsertToken('rating${result.negated ? '!' : ''}${result.operator}${result.rating}');
    }
  }

  Future<void> _handleResolutionPicker() async {
    final result = await showDialog<({double resolution, String operator, bool negated})>(
      context: context,
      builder: (context) => const ResolutionPickerDialog(),
    );

    if (result != null) {
      widget.onInsertToken(
        'resolution${result.negated ? '!' : ''}${result.operator}${result.resolution.toInt()}',
      );
    }
  }

  Future<void> _handleOrientationPicker() async {
    final parser = SearchQueryParser();
    final keywords = parser.keywords;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => const OrientationPickerDialog(),
    );

    if (selected != null) {
      widget.onInsertToken('${keywords.orientation}:$selected');
    }
  }

  Future<void> _handleKeywordChipPress(String keywordWithColon) async {
    final parser = SearchQueryParser();
    final keywords = parser.keywords;

    if (keywordWithColon == '${keywords.date}:') {
      await _handleDatePicker();
    } else if (keywordWithColon == '${keywords.lastNDays}:') {
      await _handleLastNDaysPicker();
    } else if (keywordWithColon == '${keywords.rating}:') {
      await _handleRatingPicker();
    } else if (keywordWithColon == '${keywords.resolution}:') {
      await _handleResolutionPicker();
    } else if (keywordWithColon == '${keywords.orientation}:') {
      await _handleOrientationPicker();
    } else {
      widget.onInsertToken(keywordWithColon);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.query.trimLeft();
    final keywordFilter = trimmed.isEmpty ? '' : trimmed.split(RegExp(r'\s+')).last;

    // Parse top-level tokens using parser so phrases like directory:"a trip" stay together
    final parsedTokens = <String>[];
    try {
      final parsed = SearchQueryParser().parse(widget.query);
      if (parsed is SearchListQuery) {
        parsedTokens.addAll(parsed.list.map((q) => SearchQueryParser().stringify(q)).where((s) => s.isNotEmpty));
      } else {
        final s = SearchQueryParser().stringify(parsed);
        if (s.isNotEmpty) parsedTokens.add(s);
      }
    } catch (e) {
      // fallback tokenization (keep quoted/parenthesis groups together)
      final matches = RegExp(r'"[^"]*"|\([^)]+\)|\S+').allMatches(widget.query);
      parsedTokens.addAll(matches.map((m) => m.group(0)!));
    }
    // If the user inserted an incomplete keyword like "directory:", ensure it shows up as a chip immediately
    final tokenRegexForLast = RegExp(r'"[^\"]*"|\([^)]+\)|\S+');
    final allMatches = tokenRegexForLast.allMatches(widget.query).map((m) => m.group(0)!).toList();
    if (allMatches.isNotEmpty) {
      final last = allMatches.last;
      if (last.endsWith(':') && !parsedTokens.contains(last)) {
        parsedTokens.add(last);
      }
    }
    Widget buildParsedChips() {
      if (parsedTokens.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surface.withAlpha(100),
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: parsedTokens.asMap().entries.map((e) {
            final i = e.key;
            final token = e.value;
            return InputChip(
              label: Text(token, style: const TextStyle(fontSize: 13)),
              backgroundColor: Colors.transparent,
              side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(20)),
              onPressed: () => widget.onEditToken(token),
              onDeleted: () {
                final newList = List<String>.from(parsedTokens)..removeAt(i);
                final newQuery = newList.join(' ').trim();
                widget.onReplaceQuery(newQuery);
              },
            );
          }).toList(),
        ),
      );
    }

    final visibleKeywords = <String>[
      widget.keywords.directory,
      widget.keywords.fileName,
      widget.keywords.caption,
      widget.keywords.person,
      widget.keywords.keyword,
      widget.keywords.position,
      widget.keywords.rating,
      widget.keywords.resolution,
      widget.keywords.orientation,
      widget.keywords.date,
      widget.keywords.lastNDays,
    ].whereType<String>().toList();

    // We still keep `visibleKeywords` for conditional rendering, but the actual widget
    // now uses KeywordChips with `keywordFilter`.
    final hasVisibleKeywords = keywordFilter.isEmpty
        ? visibleKeywords.isNotEmpty
        : visibleKeywords.any((k) => k.startsWith(keywordFilter));

    return SafeArea(
      child: Material(
        color: Theme.of(context).colorScheme.surface.withAlpha(240),
        child: Column(
          children: [
            // Parsed query chips (one chip per top-level term)
            buildParsedChips(),

            // Keywords wrapped (no horizontal scrolling)
            if (hasVisibleKeywords)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surface.withAlpha(100),
                padding: const EdgeInsets.all(8.0),
                child: KeywordChips(
                  keywords: widget.keywords,
                  filter: keywordFilter,
                  onPressed: _handleKeywordChipPress,
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
