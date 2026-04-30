import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization/app_localizations.dart';
import 'screens/start_screen.dart';
import 'services/auth_service.dart';
import 'services/seed_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add global error handler to catch any unhandled errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    // Continue running the app instead of crashing
  };

  // Handle platform errors (like native plugin crashes)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error caught: $error');
    debugPrint('Stack trace: $stack');
    // Return true to prevent the app from crashing
    return true;
  };

  await AuthService.initializeIfSessionExists();
  await SeedDataService.seedIfNeeded(); // fast: JSON fixtures only
  unawaited(
    SeedDataService.seedFromBarcodes(),
  ); // slow: network fetches, non-blocking
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale') ?? 'en';
  runApp(HalalCheckerApp(initialLocale: Locale(savedLocale)));
}

class HalalCheckerApp extends StatefulWidget {
  final Locale initialLocale;

  const HalalCheckerApp({super.key, required this.initialLocale});

  static HalalCheckerAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<HalalCheckerAppState>();

  @override
  State<HalalCheckerApp> createState() => HalalCheckerAppState();
}

class HalalCheckerAppState extends State<HalalCheckerApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    if (mounted) setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HalalScan',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tr'), Locale('de')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      home: const ErrorBoundary(child: StartScreen()),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Catch any errors in the widget tree
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('Flutter error caught in ErrorBoundary: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
      return Container(
        color: Colors.white,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Please restart the app.', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Scaffold(
        body: Center(child: Text('An error occurred. Please restart the app.')),
      );
    }

    return widget.child;
  }
}
