import 'package:drift/drift.dart';

@DataClassName('NewsArticleTableData')
class NewsArticles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get content => text()(); // Full body or description
  TextColumn get fullContent =>
      text().nullable()(); // Scraped Reader Mode content
  TextColumn get url => text()(); // Original article link
  TextColumn get imageUrl => text().nullable()();
  TextColumn get source => text()();
  TextColumn get category => text()();
  DateTimeColumn get publishedAt => dateTime()();
  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();

  /// Unique hash generated from URL to prevent duplicates
  TextColumn get urlHash => text().unique()();
}

@DataClassName('MetadataTableData')
class AppMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

@DataClassName('NewsSourceTableData')
class NewsSources extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().unique()();
  TextColumn get name => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
}

@DataClassName('MutedKeywordTableData')
class MutedKeywords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get keyword => text().unique()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
}
