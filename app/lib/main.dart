import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/core/generated/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'dart:ui';
import 'src/core/error/error_boundary.dart';
import 'src/core/services/monitoring_service.dart';
import 'src/core/services/notification_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'src/core/services/background_service.dart';

void main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Global Error Handling
  GlobalErrorBoundary.init();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    MonitoringService().logError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    MonitoringService().logError(error, stack);
    return true;
  };

  // Initialize services with safety wrappers to prevent release mode blocking
  try {
    await NotificationService().initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('NotificationService initialization timed out');
      },
    );
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }

  try {
    await BackgroundService.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('BackgroundService initialization timed out');
      },
    );
  } catch (e) {
    debugPrint('BackgroundService initialization failed: $e');
  }

  runApp(
    const ProviderScope(child: GlobalErrorBoundary(child: GoogleTechNewsApp())),
  );
}

class GoogleTechNewsApp extends ConsumerWidget {
  const GoogleTechNewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlutterNativeSplash.remove();
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: 'Google Tech News',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),
          themeMode: ThemeMode.system,
          routerConfig: appRouter,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
          ],
        );
      },
    );
  }
}
