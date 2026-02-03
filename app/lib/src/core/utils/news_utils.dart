class NewsUtils {
  /// Calculates reading time based on 200 words per minute.
  static int calculateReadingTime(String content) {
    if (content.isEmpty) return 1;
    final wordCount = content.split(RegExp(r'\s+')).length;
    final minutes = (wordCount / 200).ceil();
    return minutes > 0 ? minutes : 1;
  }
}
