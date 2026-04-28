import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization/app_localizations.dart';
import 'screens/start_screen.dart';
import 'services/seed_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SeedDataService.seedIfNeeded();           // fast: JSON fixtures only
  unawaited(SeedDataService.seedFromBarcodes());  // slow: network fetches, non-blocking
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
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
        Locale('de'),
      ],
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
