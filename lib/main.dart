import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'localization/app_localizations.dart';
import 'screens/start_screen.dart';
import 'services/auth_service.dart';
import 'services/seed_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error caught: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
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

  await AuthService.initializeIfSessionExists();
  await SeedDataService.seedIfNeeded(); // fast: JSON fixtures only
  if (!AppConfig.isE2e) {
    unawaited(
      SeedDataService.seedFromBarcodes(),
    ); // slow: network fetches, non-blocking
  }
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale') ?? 'en';
  final localeCode = AppConfig.e2eForceLocale.isNotEmpty
      ? AppConfig.e2eForceLocale
      : savedLocale;
  runApp(HalalCheckerApp(initialLocale: Locale(localeCode)));
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
        AppLocalizations.delegate,
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
      home: const StartScreen(),
    );
  }
}
