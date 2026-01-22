import 'package:flutter/material.dart';

class KeywordChips extends StatelessWidget {
  final dynamic keywords;
  final String filter;
  final void Function(String keywordWithColon) onPressed;

  const KeywordChips({super.key, required this.keywords, this.filter = '', required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final keywordList = <String>[
      keywords.directory,
      keywords.fileName,
      keywords.caption,
      keywords.person,
      keywords.orientation,
      keywords.from,
      keywords.to,
      keywords.anyText,
    ].whereType<String>();

    final visible = filter.isEmpty ? keywordList : keywordList.where((k) => k.startsWith(filter));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visible
          .map(
            (k) => ActionChip(
              avatar: const Icon(Icons.label_outline, size: 16),
              label: Text('$k:', style: const TextStyle(fontSize: 13)),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(20)),
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () => onPressed('$k:'),
            ),
          )
          .toList(),
    );
  }
}
