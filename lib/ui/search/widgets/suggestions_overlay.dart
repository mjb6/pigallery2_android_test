import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pigallery2_android/data/backend/models/search/auto_complete.dart';
import 'package:pigallery2_android/data/backend/models/search/search.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query_parser.dart';
import 'package:pigallery2_android/domain/repositories/item_repository.dart';
import 'keyword_chips.dart';

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
    switch (type) {
      case SearchQueryTypes.directory:
        return const Icon(Icons.folder_outlined);
      case SearchQueryTypes.fileName:
        return const Icon(Icons.description_outlined);
      case SearchQueryTypes.caption:
        return const Icon(Icons.comment_outlined);
      case SearchQueryTypes.person:
        return const Icon(Icons.person_outline);
      case SearchQueryTypes.keyword:
        return const Icon(Icons.local_offer_outlined);
      case SearchQueryTypes.position:
        return const Icon(Icons.location_on_outlined);
      default:
        return const Icon(Icons.search_outlined);
    }
  }

  String _subtitleForType(SearchQueryTypes type) {
    switch (type) {
      case SearchQueryTypes.directory:
        return 'Directory';
      case SearchQueryTypes.fileName:
        return 'File name';
      case SearchQueryTypes.caption:
        return 'Caption';
      case SearchQueryTypes.person:
        return 'Person';
      case SearchQueryTypes.keyword:
        return 'Keyword';
      case SearchQueryTypes.position:
        return 'Position';
      default:
        return '';
    }
  }

  Future<void> _handleDatePicker(String keyword) async {
    final now = DateTime.now();
    DateTime startDate = now;
    DateTime endDate = now;
    String operator = '=';
    bool isRange = false;
    bool negated = false;

    final result = await showDialog<({DateTime start, DateTime end, String operator, bool isRange, bool isNegated})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Date Filter',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search by date or date range',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Query Type
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(label: Text('Specific Date'), value: false),
                            ButtonSegment(label: Text('Date Range'), value: true),
                          ],
                          selected: {isRange},
                          onSelectionChanged: (v) => setState(() => isRange = v.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Date Selection
                    if (isRange) ...[
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.utc(1900),
                            lastDate: DateTime.now(),
                            initialDateRange: DateTimeRange(start: startDate, end: endDate),
                          );
                          if (picked != null) {
                            setState(() {
                              startDate = picked.start;
                              endDate = picked.end;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withAlpha(128),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date Range', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('From', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(startDate),
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.primary),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('To', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(endDate),
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to change range',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.utc(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                          }
                        },
                        child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isRange ? 'From' : 'Date', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime.utc(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => startDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatDate(startDate),
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to change date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),),
                      const SizedBox(height: 24),
                      // Operator selection (only for specific date)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comparison', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withAlpha(128),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                            ),
                            child: GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              children: [
                                _buildOperatorChip(context, '=', 'Equal', operator, () => setState(() => operator = '=')),
                                _buildOperatorChip(context, '>', 'After', operator, () => setState(() => operator = '>')),
                                _buildOperatorChip(context, '<', 'Before', operator, () => setState(() => operator = '<')),
                                _buildOperatorChip(context, '>=', 'On or after', operator, () => setState(() => operator = '>=')),
                                _buildOperatorChip(context, '<=', 'On or before', operator, () => setState(() => operator = '<=')),
                                _buildNegationToggle(context, negated, () => setState(() => negated = !negated)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Preview
                    _buildPreviewBox(
                      context,
                      isRange
                              ? 'date${negated ? '!' : ''}:${_formatDate(startDate)}..${_formatDate(endDate)}'
                              : 'date${negated ? '!' : ''}$operator${_formatDate(startDate)}'),
                  const SizedBox(height: 32),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, (start: startDate, end: endDate, operator: operator, isRange: isRange, isNegated: negated)),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      final startStr = SearchQueryParser.stringifyDate(result.start.toUtc().millisecondsSinceEpoch);
      if (startStr == null) return;

      final negationPrefix = result.isNegated ? '!' : '';
      if (result.isRange) {
        final endStr = SearchQueryParser.stringifyDate(result.end.toUtc().millisecondsSinceEpoch);
        if (endStr == null) return;
        widget.onInsertToken('$negationPrefix$keyword$startStr..$endStr');
      } else {
        widget.onInsertToken('$negationPrefix$keyword${result.operator}$startStr');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleLastNDaysPicker() async {
    int daysLength = 7;
    bool isRecurring = true; // true for recurring, false for historical
    String frequencyUnit = 'year';
    int frequencyCount = 1;

    final result = await showDialog<({int days, bool isRecurring, String unit, int count})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Date Range Pattern',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure when to search for items',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Days length section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Days Length',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$daysLength days',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: daysLength.toDouble(),
                          min: 1,
                          max: 365,
                          divisions: 364,
                          label: '$daysLength',
                          onChanged: (value) => setState(() => daysLength = value.toInt()),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search items from the last $daysLength days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pattern type section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pattern Type',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(label: Text('Recurring'), value: true),
                          ButtonSegment(label: Text('Historical'), value: false),
                        ],
                        selected: {isRecurring},
                        onSelectionChanged: (v) => setState(() => isRecurring = v.first),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRecurring ? 'Find items that repeat on a schedule' : 'Find items from a past time period',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Frequency controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                    ),
                    child: isRecurring
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Repeat Every',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ['week', 'month', 'year']
                                    .map(
                                      (unit) => ChoiceChip(
                                        label: Text(unit),
                                        selected: frequencyUnit == unit,
                                        onSelected: (_) => setState(() => frequencyUnit = unit),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Matches every $frequencyUnit',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time Unit',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ['day', 'week', 'month', 'year']
                                    .map(
                                      (unit) => ChoiceChip(
                                        label: Text(unit),
                                        selected: frequencyUnit == unit,
                                        onSelected: (_) => setState(() => frequencyUnit = unit),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'How Many Ago',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary.withAlpha(30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$frequencyCount',
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Slider(
                                value: frequencyCount.toDouble(),
                                min: 1,
                                max: 100,
                                divisions: 99,
                                label: frequencyCount.toString(),
                                onChanged: (value) => setState(() => frequencyCount = value.toInt()),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.secondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$frequencyCount $frequencyUnit${frequencyCount > 1 ? 's' : ''} ago',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, (
                          days: daysLength,
                          isRecurring: isRecurring,
                          unit: frequencyUnit,
                          count: frequencyCount,
                        )),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    int ratingValue = 3;
    String operator = '=';
    bool negated = false;

    final result = await showDialog<({int rating, String operator, bool negated})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Rating Filter',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a rating and comparison method',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Rating value section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rating Value',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  ...List.generate(
                                    ratingValue,
                                    (i) => Icon(Icons.star, size: 14, color: Theme.of(context).colorScheme.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$ratingValue / 5',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: ratingValue.toDouble(),
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: '$ratingValue',
                          onChanged: (value) => setState(() => ratingValue = value.toInt()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Operator section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparison',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withAlpha(128),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                        ),
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: [
                            _buildOperatorChip(context, '=', 'Equal', operator, () => setState(() => operator = '=')),
                            _buildOperatorChip(context, '>', 'Greater', operator, () => setState(() => operator = '>')),
                            _buildOperatorChip(context, '<', 'Less', operator, () => setState(() => operator = '<')),
                            _buildOperatorChip(
                              context,
                              '>=',
                              'Greater or equal',
                              operator,
                              () => setState(() => operator = '>='),
                            ),
                            _buildOperatorChip(
                              context,
                              '<=',
                              'Less or equal',
                              operator,
                              () => setState(() => operator = '<='),
                            ),
                            _buildNegationToggle(context, negated, () => setState(() => negated = !negated)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPreviewBox(context, 'rating${negated ? '!' : ''}$operator$ratingValue'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, (rating: ratingValue, operator: operator, negated: negated)),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      widget.onInsertToken('rating${result.negated ? '!' : ''}${result.operator}${result.rating}');
    }
  }

  Widget _buildPreviewBox(BuildContext context, String text, {Color? color}) {
    final bgColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: bgColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: bgColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorChip(
    BuildContext context,
    String op,
    String label,
    String selected,
    VoidCallback onTap,
  ) {
    final isSelected = op == selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(50) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withAlpha(50),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  op,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNegationToggle(BuildContext context, bool isNegated, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isNegated ? Theme.of(context).colorScheme.error.withAlpha(50) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isNegated ? Theme.of(context).colorScheme.error : Theme.of(context).dividerColor.withAlpha(50),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.not_interested,
                  size: 20,
                  color: isNegated ? Theme.of(context).colorScheme.error : Colors.grey,
                ),
                Text(
                  'Negate',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isNegated ? Theme.of(context).colorScheme.error : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleResolutionPicker() async {
    double resolutionValue = 10.0;
    String operator = '=';
    bool negated = false;

    final result = await showDialog<({double resolution, String operator, bool negated})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Resolution Filter',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search by image resolution in megapixels',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Resolution value section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Resolution',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${resolutionValue.toStringAsFixed(1)} MP',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: resolutionValue,
                          min: 0.1,
                          max: 50,
                          divisions: 499,
                          label: '${resolutionValue.toStringAsFixed(1)} MP',
                          onChanged: (value) => setState(() => resolutionValue = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Operator section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparison',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withAlpha(128),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
                        ),
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: [
                            _buildOperatorChip(context, '=', 'Equal', operator, () => setState(() => operator = '=')),
                            _buildOperatorChip(context, '>', 'Greater', operator, () => setState(() => operator = '>')),
                            _buildOperatorChip(context, '<', 'Less', operator, () => setState(() => operator = '<')),
                            _buildOperatorChip(
                              context,
                              '>=',
                              'Greater or equal',
                              operator,
                              () => setState(() => operator = '>='),
                            ),
                            _buildOperatorChip(
                              context,
                              '<=',
                              'Less or equal',
                              operator,
                              () => setState(() => operator = '<='),
                            ),
                            _buildNegationToggle(context, negated, () => setState(() => negated = !negated)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPreviewBox(
                        context,
                        'resolution${negated ? '!' : ''}$operator${resolutionValue.toStringAsFixed(1)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, (resolution: resolutionValue, operator: operator, negated: negated)),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      widget.onInsertToken(
        'resolution${result.negated ? '!' : ''}${result.operator}${result.resolution.toStringAsFixed(1)}',
      );
    }
  }

  Future<void> _handleOrientationPicker() async {
    final parser = SearchQueryParser();
    final keywords = parser.keywords;
    String? selected;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Orientation'),
        content: SizedBox(
          width: double.maxFinite,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.portrait_outlined),
                  label: const Text('Portrait'),
                  onPressed: () {
                    selected = keywords.portrait;
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.landscape_outlined),
                  label: const Text('Landscape'),
                  onPressed: () {
                    selected = keywords.landscape;
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      widget.onInsertToken('${keywords.orientation}:$selected');
    }
  }

  Future<void> _handleKeywordChipPress(String keywordWithColon) async {
    final parser = SearchQueryParser();
    final keywords = parser.keywords;

    if (keywordWithColon == '${keywords.date}:') {
      await _handleDatePicker(keywordWithColon);
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
