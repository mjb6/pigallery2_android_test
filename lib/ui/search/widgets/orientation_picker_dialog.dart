import 'package:flutter/material.dart';
import 'package:pigallery2_android/data/backend/models/search/search_query_parser.dart';

class OrientationPickerDialog extends StatelessWidget {
  const OrientationPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final parser = SearchQueryParser();
    final keywords = parser.keywords;

    return AlertDialog(
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
                onPressed: () => Navigator.pop(context, keywords.portrait),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.landscape_outlined),
                label: const Text('Landscape'),
                onPressed: () => Navigator.pop(context, keywords.landscape),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
