import 'package:flutter_test/flutter_test.dart';
import 'package:app/src/features/news/data/datasources/dlp_rss_parser.dart';

void main() {
  group('DlpRssParser', () {
    test('extracts standard RSS item correctly', () {
      const xmlString = '''
        <rss>
          <channel>
            <item>
              <title>Test DeepMind Article</title>
              <link>https://deepmind.google/test</link>
              <pubDate>Tue, 04 Feb 2026 10:00:00 GMT</pubDate>
              <description>A breakthrough in AI.</description>
              <media:content url="https://deepmind.google/image.jpg" medium="image" />
            </item>
          </channel>
        </rss>
      ''';

      final article = DlpRssParser().parse(xmlString, 'Google DeepMind').first;

      expect(article.title, 'Test DeepMind Article');
      expect(article.url, 'https://deepmind.google/test');
      expect(article.source, 'Google DeepMind');
      expect(article.imageUrl, 'https://deepmind.google/image.jpg');
    });

    test('extracts Atom entry correctly', () {
      const xmlString = '''
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry>
            <title>Android Update</title>
            <link href="https://android-developers.googleblog.com/update" />
            <updated>2026-02-04T10:00:00Z</updated>
            <content>New features available.</content>
            <media:thumbnail url="https://example.com/thumbnail.png" />
          </entry>
        </feed>
      ''';

      final article = DlpRssParser()
          .parse(xmlString, 'Android Developers')
          .first;

      expect(article.title, 'Android Update');
      expect(article.url, 'https://android-developers.googleblog.com/update');
      expect(article.imageUrl, 'https://example.com/thumbnail.png');
    });

    test('prioritizes media:content over regex', () {
      const xmlString = '''
        <rss>
          <channel>
            <item>
              <title>Mixed Media</title>
              <link>https://example.com/mixed</link>
              <description>&lt;img src="https://example.com/fallback.jpg"&gt;</description>
              <media:content url="https://example.com/highres.jpg" />
            </item>
          </channel>
        </rss>
      ''';

      final article = DlpRssParser().parse(xmlString, 'Test Source').first;

      expect(article.imageUrl, 'https://example.com/highres.jpg');
    });

    test('falls back to regex if no media tags present', () {
      const xmlString = '''
        <rss>
          <channel>
            <item>
              <title>Regex Fallback</title>
              <link>https://example.com/regex</link>
              <description>
                Some text.
                &lt;img src="https://example.com/embedded.jpg" alt="test"&gt;
              </description>
            </item>
          </channel>
        </rss>
      ''';

      final article = DlpRssParser().parse(xmlString, 'Test Source').first;

      expect(article.imageUrl, 'https://example.com/embedded.jpg');
    });
  });
}
