class TaggingService {
  static const List<String> keywords = [
    'Gemini',
    'AI',
    'Android',
    'ChromeOS',
    'Aluminum',
    'Pixel',
    'Material',
  ];

  static List<String> extractTags(String title) {
    final tags = <String>[];
    final lowercaseTitle = title.toLowerCase();

    for (final keyword in keywords) {
      if (lowercaseTitle.contains(keyword.toLowerCase())) {
        tags.add(keyword);
      }
    }
    return tags;
  }
}
