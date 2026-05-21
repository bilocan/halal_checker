import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localization/app_localizations.dart';
import 'models/product.dart';
import 'screens/directory_screen.dart';
import 'screens/result_screen.dart';
import 'screens/start_screen.dart';
import 'services/auth_service.dart';
import 'services/seed_data_service.dart';

// Entry point used exclusively by the ios_screenshots CI workflow.
// Auto-navigates through screens on a timer so xcrun simctl io screenshot
// can capture each one without flutter drive.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initializeIfSessionExists();
  await SeedDataService.seedIfNeeded();
  final prefs = await SharedPreferences.getInstance();
  final locale = prefs.getString('locale') ?? 'en';
  runApp(_ScreenshotApp(locale: Locale(locale)));
}

class _ScreenshotApp extends StatelessWidget {
  final Locale locale;
  const _ScreenshotApp({required this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HalalScan',
      debugShowCheckedModeBanner: false,
      locale: locale,
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
      home: const _ScreenshotNavigator(),
    );
  }
}

class _ScreenshotNavigator extends StatefulWidget {
  const _ScreenshotNavigator();

  @override
  State<_ScreenshotNavigator> createState() => _ScreenshotNavigatorState();
}

class _ScreenshotNavigatorState extends State<_ScreenshotNavigator> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedule());
  }

  void _schedule() {
    // t=15s — push DirectoryScreen (screenshot 02)
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const DirectoryScreen()));
    });

    // t=30s — push halal ResultScreen (screenshot 03)
    Future.delayed(const Duration(seconds: 30), () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(product: _halal, barcode: _halal.barcode),
        ),
      );
    });

    // t=45s — push haram ResultScreen (screenshot 04)
    Future.delayed(const Duration(seconds: 45), () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(product: _haram, barcode: _haram.barcode),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const StartScreen();
}

final _halal = Product(
  barcode: '3068320114094',
  name: 'Evian Natural Mineral Water 1.5L',
  ingredients: ['Natural mineral water'],
  isHalal: true,
  haramIngredients: [],
  suspiciousIngredients: [],
  ingredientWarnings: {},
  labels: ['en:halal', 'en:mineral-water'],
  explanation:
      'This product contains only natural mineral water. '
      'No haram or suspicious ingredients detected.',
  analyzedByAI: true,
  analysisMethod: 'ai',
);

final _haram = Product(
  barcode: '0037600000871',
  name: 'Spam Classic',
  ingredients: [
    'Pork with Ham',
    'Salt',
    'Water',
    'Modified Potato Starch',
    'Sugar',
    'Sodium Nitrite',
  ],
  isHalal: false,
  haramIngredients: ['Pork with Ham'],
  suspiciousIngredients: [],
  ingredientWarnings: {'Pork with Ham': 'Contains pork — haram'},
  labels: [],
  explanation:
      'This product contains pork (Pork with Ham), which is haram. '
      'Do not consume.',
  analyzedByAI: true,
  analysisMethod: 'ai',
);
