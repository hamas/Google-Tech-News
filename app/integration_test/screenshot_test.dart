import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Note: This requires a running emulator/device.
// Run with: flutter test integration_test/screenshot_test.dart

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture Screenshots', (WidgetTester tester) async {
    // 1. Launch App
    await tester.pumpWidget(const ProviderScope(child: GoogleTechNewsApp()));
    await tester.pumpAndSettle();

    // 2. Capture Home
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_home_screen');

    // 3. Scroll Feed
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_feed_scrolled');

    // 4. Open Article (Simulated Tap if articles exist)
    // await tester.tap(find.byType(NewsCard).first);
    // await tester.pumpAndSettle();
    // await binding.takeScreenshot('03_article_detail');
  });
}
