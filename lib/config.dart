class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Web OAuth client ID from Google Cloud Console (APIs & Services → Credentials)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Test Supabase project ref; must match [supabaseUrl] host in integration tests.
  static const String integrationProjectRef = String.fromEnvironment(
    'INTEGRATION_PROJECT_REF',
    defaultValue: '',
  );

  static bool get hasGoogleAuth => googleWebClientId.isNotEmpty;

  /// When set (e.g. `en`), forces app locale during UI E2E runs.
  static const String e2eForceLocale = String.fromEnvironment(
    'E2E_FORCE_LOCALE',
    defaultValue: '',
  );

  /// When true, debug builds skip the offline test DB so lookups hit the network.
  static const bool e2eLiveLookup = bool.fromEnvironment(
    'E2E_LIVE_LOOKUP',
    defaultValue: false,
  );

  /// True when running UI E2E (`E2E_FORCE_LOCALE` set in `dart_defines.e2e.json`).
  static bool get isE2e => e2eForceLocale.isNotEmpty;

  /// When true, [HomeScreen] skips [MobileScanner] (set only by `run_ui_e2e_test`).
  static const bool e2eSkipCamera = bool.fromEnvironment(
    'E2E_SKIP_CAMERA',
    defaultValue: false,
  );
}
