import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/localization/app_localizations.dart';

void main() {
  // ── English locale ───────────────────────────────────────────────────────

  group('AppLocalizations — English', () {
    late AppLocalizations l10n;

    setUp(() => l10n = AppLocalizations(const Locale('en')));

    test('appTitle returns HalalScan', () {
      expect(l10n.appTitle, 'HalalScan');
    });

    test('halal returns HALAL', () {
      expect(l10n.halal, 'HALAL');
    });

    test('notHalal returns HARAM', () {
      expect(l10n.notHalal, 'HARAM');
    });

    test('scanButton returns Start Scan', () {
      expect(l10n.scanButton, 'Start Scan');
    });

    test('cancel returns Cancel', () {
      expect(l10n.cancel, 'Cancel');
    });

    test('submit returns Submit', () {
      expect(l10n.submit, 'Submit');
    });

    test('daysAgo interpolates count', () {
      expect(l10n.daysAgo(3), '3 days ago');
    });

    test('errorFetchingProduct interpolates error', () {
      expect(
        l10n.errorFetchingProduct('timeout'),
        'Error fetching product: timeout',
      );
    });

    test('errorSubmittingFeedback interpolates error', () {
      expect(
        l10n.errorSubmittingFeedback('network'),
        'Error submitting feedback: network',
      );
    });

    test('transparentRulesAvailable interpolates count', () {
      expect(
        l10n.transparentRulesAvailable(42),
        '42 rules available (nothing to check)',
      );
    });

    test('deleteRuleConfirm interpolates keyword', () {
      expect(l10n.deleteRuleConfirm('lard'), contains('lard'));
    });

    test('today returns Today', () {
      expect(l10n.today, 'Today');
    });

    test('yesterday returns Yesterday', () {
      expect(l10n.yesterday, 'Yesterday');
    });

    test('unknown returns expected string', () {
      expect(l10n.unknown, '? UNKNOWN');
    });

    test('nonFood returns expected string', () {
      expect(l10n.nonFood, contains('NOT FOOD'));
    });

    test('keywords returns Keywords', () {
      expect(l10n.keywords, 'Keywords');
    });

    test('about returns About', () {
      expect(l10n.about, 'About');
    });

    test('signIn returns Sign in', () {
      expect(l10n.signIn, 'Sign in');
    });

    test('signOut returns Sign out', () {
      expect(l10n.signOut, 'Sign out');
    });

    test('halalDirectory returns a non-empty string', () {
      expect(l10n.halalDirectory, isNotEmpty);
    });

    test('adminPanel returns Admin panel', () {
      expect(l10n.adminPanel, 'Admin panel');
    });

    test('productNotFound returns expected text', () {
      expect(l10n.productNotFound, 'Product not found');
    });

    test('ingredients returns Ingredients', () {
      expect(l10n.ingredients, 'Ingredients');
    });

    test('communityFeedback returns expected text', () {
      expect(l10n.communityFeedback, 'Community Feedback');
    });

    test('deepAnalysis returns expected text', () {
      expect(l10n.deepAnalysis, isNotEmpty);
    });

    test('reportWrongResult returns expected text', () {
      expect(l10n.reportWrongResult, 'Report Wrong Result');
    });

    test('contributeIngredients returns expected text', () {
      expect(l10n.contributeIngredients, 'Add Ingredients');
    });

    test('flaggedOnly returns expected text', () {
      expect(l10n.flaggedOnly, isNotEmpty);
    });

    test('allScans returns expected text', () {
      expect(l10n.allScans, isNotEmpty);
    });
  });

  // ── Turkish locale ─────────────────────────────────────────────────────

  group('AppLocalizations — Turkish', () {
    late AppLocalizations l10n;

    setUp(() => l10n = AppLocalizations(const Locale('tr')));

    test('appTitle returns HalalScan', () {
      expect(l10n.appTitle, 'HalalScan');
    });

    test('halal returns localized text', () {
      expect(l10n.halal, isNotEmpty);
    });

    test('notHalal returns localized text', () {
      expect(l10n.notHalal, isNotEmpty);
    });

    test('scanButton returns localized text', () {
      expect(l10n.scanButton, isNotEmpty);
    });

    test('daysAgo interpolates count', () {
      expect(l10n.daysAgo(5), contains('5'));
    });
  });

  // ── German locale ──────────────────────────────────────────────────────

  group('AppLocalizations — German', () {
    late AppLocalizations l10n;

    setUp(() => l10n = AppLocalizations(const Locale('de')));

    test('appTitle returns HalalScan', () {
      expect(l10n.appTitle, 'HalalScan');
    });

    test('halal returns localized text', () {
      expect(l10n.halal, isNotEmpty);
    });

    test('notHalal returns localized text', () {
      expect(l10n.notHalal, isNotEmpty);
    });

    test('scanButton returns localized text', () {
      expect(l10n.scanButton, isNotEmpty);
    });

    test('daysAgo interpolates count', () {
      expect(l10n.daysAgo(7), contains('7'));
    });
  });

  // ── Fallback for unsupported locale ─────────────────────────────────────

  group('AppLocalizations — unsupported locale falls back to English', () {
    late AppLocalizations l10n;

    setUp(() => l10n = AppLocalizations(const Locale('fr')));

    test('appTitle falls back to English', () {
      expect(l10n.appTitle, 'HalalScan');
    });

    test('halal falls back to HALAL', () {
      expect(l10n.halal, 'HALAL');
    });
  });

  // ── AppLocalizationsDelegate ────────────────────────────────────────────

  group('AppLocalizationsDelegate', () {
    const delegate = AppLocalizationsDelegate();

    test('supports English', () {
      expect(delegate.isSupported(const Locale('en')), isTrue);
    });

    test('supports Turkish', () {
      expect(delegate.isSupported(const Locale('tr')), isTrue);
    });

    test('supports German', () {
      expect(delegate.isSupported(const Locale('de')), isTrue);
    });

    test('does not support French', () {
      expect(delegate.isSupported(const Locale('fr')), isFalse);
    });

    test('load returns an AppLocalizations instance', () async {
      final l10n = await delegate.load(const Locale('en'));
      expect(l10n, isA<AppLocalizations>());
      expect(l10n.appTitle, 'HalalScan');
    });

    test('shouldReload returns false', () {
      expect(delegate.shouldReload(delegate), isFalse);
    });
  });
}
