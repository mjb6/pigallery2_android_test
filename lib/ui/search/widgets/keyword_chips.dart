import 'package:flutter/material.dart';

class KeywordChips extends StatelessWidget {
  final dynamic keywords;
  final String filter;
  final void Function(String keywordWithColon) onPressed;

  const KeywordChips({super.key, required this.keywords, this.filter = '', required this.onPressed});

  static const _chipTextStyle = TextStyle(fontSize: 13);
  static const _iconSize = 16.0;

  Widget _buildKeywordChip(
    BuildContext context,
    String keyword,
    IconData icon,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: _iconSize),
      label: Text('$keyword:', style: _chipTextStyle),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(20)),
        borderRadius: BorderRadius.circular(16),
      ),
      onPressed: () => onPressed('$keyword:'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keywordList = <String>[
      keywords.directory,
      keywords.fileName,
      keywords.caption,
      keywords.person,
      keywords.keyword,
      keywords.position,
      keywords.rating,
      keywords.resolution,
      keywords.orientation,
      keywords.date,
      keywords.lastNDays,
    ].whereType<String>();

    final visible = filter.isEmpty ? keywordList : keywordList.where((k) => k.startsWith(filter));

    // Map keywords to their icons
    final keywordIcons = <String, IconData>{
      keywords.orientation: Icons.crop_rotate_outlined,
      keywords.rating: Icons.star_outline,
      keywords.resolution: Icons.image_search_outlined,
      keywords.date: Icons.date_range_outlined,
      keywords.lastNDays: Icons.calendar_month_outlined,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visible
          .map<Widget>(
            (k) => _buildKeywordChip(
              context,
              k,
              keywordIcons[k] ?? Icons.label_outline,
            ),
          )
          .toList(),
    );
  }
}
