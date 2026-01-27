import 'package:flutter/material.dart';

/// Helper utility for search query type icons and subtitles
class SearchTypeHelper {
  /// Returns the appropriate icon for a search query type
  static Widget iconForType(String? type) {
    switch (type) {
      case 'directory':
        return const Icon(Icons.folder_outlined);
      case 'fileName':
        return const Icon(Icons.description_outlined);
      case 'caption':
        return const Icon(Icons.comment_outlined);
      case 'person':
        return const Icon(Icons.person_outline);
      case 'keyword':
        return const Icon(Icons.local_offer_outlined);
      case 'position':
        return const Icon(Icons.location_on_outlined);
      default:
        return const Icon(Icons.search_outlined);
    }
  }

  /// Returns the subtitle string for a search query type
  static String subtitleForType(String? type) {
    switch (type) {
      case 'directory':
        return 'Directory';
      case 'fileName':
        return 'File name';
      case 'caption':
        return 'Caption';
      case 'person':
        return 'Person';
      case 'keyword':
        return 'Keyword';
      case 'position':
        return 'Position';
      default:
        return '';
    }
  }
}
