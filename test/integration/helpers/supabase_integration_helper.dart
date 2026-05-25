import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/config.dart';
import 'package:halal_checker/services/ai_ingredient_request_service.dart';
import 'package:halal_checker/services/auth_service.dart';
import 'package:halal_checker/services/ingredient_report_service.dart';
import 'package:halal_checker/services/product_image_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared setup for live Supabase integration tests (test project only).
///
/// Requires `--dart-define-from-file=dart_defines.integration.json` (or
/// equivalent `SUPABASE_URL` + `SUPABASE_ANON_KEY` defines).
///
/// Optional defines for broader coverage:
/// - `SUPABASE_TEST_EMAIL` / `SUPABASE_TEST_PASSWORD` — authenticated user
/// - `SUPABASE_TEST_ADMIN_EMAIL` / `SUPABASE_TEST_ADMIN_PASSWORD` — admin user
/// - `SUPABASE_SERVICE_ROLE_KEY` — cleanup only (never shipped in the app)
class SupabaseIntegrationHelper {
  SupabaseIntegrationHelper._();

  static const _testEmail = String.fromEnvironment(
    'SUPABASE_TEST_EMAIL',
    defaultValue: '',
  );
  static const _testPassword = String.fromEnvironment(
    'SUPABASE_TEST_PASSWORD',
    defaultValue: '',
  );
  static const _adminEmail = String.fromEnvironment(
    'SUPABASE_TEST_ADMIN_EMAIL',
    defaultValue: '',
  );
  static const _adminPassword = String.fromEnvironment(
    'SUPABASE_TEST_ADMIN_PASSWORD',
    defaultValue: '',
  );
  static const _serviceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: '',
  );

  static bool _initialized = false;

  static bool get hasSupabase => AppConfig.hasSupabase;

  static bool get hasTestUser =>
      _testEmail.isNotEmpty && _testPassword.isNotEmpty;

  static bool get hasTestAdmin =>
      _adminEmail.isNotEmpty && _adminPassword.isNotEmpty;

  static bool get hasServiceRole => hasSupabase && _serviceRoleKey.isNotEmpty;

  static String uniqueBarcode({String prefix = '9999999'}) {
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
    return '$prefix${suffix.toString().padLeft(5, '0')}';
  }

  static void skipIfNoSupabase() {
    if (!hasSupabase) {
      markTestSkipped(
        'Requires SUPABASE_URL and SUPABASE_ANON_KEY '
        '(use --dart-define-from-file=dart_defines.integration.json)',
      );
    }
    assertIntegrationProjectOnly();
  }

  /// Fails fast when [dart_defines.json] / prod URL is used instead of integration defines.
  static void assertIntegrationProjectOnly() {
    if (!hasSupabase) return;

    final ref = AppConfig.integrationProjectRef.trim();
    if (ref.isEmpty) {
      fail(
        'INTEGRATION_PROJECT_REF must be set in dart_defines.integration.json '
        '(test Supabase project ref from the dashboard URL).',
      );
    }

    final host = Uri.tryParse(AppConfig.supabaseUrl)?.host ?? '';
    if (!host.startsWith(ref)) {
      fail(
        'SUPABASE_URL ($host) does not match INTEGRATION_PROJECT_REF ($ref). '
        'Pipeline tests must use dart_defines.integration.json for the test project, '
        'not dart_defines.json / production.',
      );
    }
  }

  static void skipIfNoTestUser() {
    if (!hasTestUser) {
      markTestSkipped(
        'Requires SUPABASE_TEST_EMAIL and SUPABASE_TEST_PASSWORD dart-defines',
      );
    }
  }

  static void skipIfNoTestAdmin() {
    if (!hasTestAdmin) {
      markTestSkipped(
        'Requires SUPABASE_TEST_ADMIN_EMAIL and '
        'SUPABASE_TEST_ADMIN_PASSWORD dart-defines',
      );
    }
  }

  /// One-time Supabase init for the whole test file.
  static Future<void> initOnce() async {
    skipIfNoSupabase();
    if (_initialized) return;

    SharedPreferences.setMockInitialValues({});
    resetServiceFakes();

    final ready = await AuthService.ensureInitialized();
    if (!ready) {
      markTestSkipped('Supabase initialization failed — check dart_defines');
    }
    _initialized = true;
  }

  /// Clears test fakes between tests without tearing down Supabase.
  static void resetServiceFakes() {
    IngredientReportService.resetForTesting();
    AiIngredientRequestService.resetForTesting();
    ProductImageService.resetForTesting();
  }

  static Future<void> signInTestUser() async {
    await _signIn(_testEmail, _testPassword);
  }

  static Future<void> signInTestAdmin() async {
    await _signIn(_adminEmail, _adminPassword);
    await _ensureProfileRole('admin');
  }

  /// Integration admin tests need RLS admin/superadmin; users cannot self-promote.
  static Future<void> _ensureProfileRole(String role) async {
    final client = _serviceClient;
    final uid = AuthService.currentUser?.id;
    if (client == null || uid == null) {
      fail(
        'SUPABASE_SERVICE_ROLE_KEY is required in dart_defines.integration.json '
        'so integration tests can set profiles.role=$role for test accounts.',
      );
    }
    await client.from('profiles').upsert({'id': uid, 'role': role});
  }

  static Future<void> _signIn(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      fail('Sign-in failed ($email): ${e.message}');
    }
    if (AuthService.currentUser == null) {
      fail('Sign-in succeeded but AuthService.currentUser is null');
    }
  }

  static Future<void> signOut() async {
    await AuthService.signOut();
  }

  static SupabaseClient? get _serviceClient {
    if (!hasServiceRole) return null;
    return SupabaseClient(AppConfig.supabaseUrl, _serviceRoleKey);
  }

  static Future<void> deleteIngredientReportsForBarcode(String barcode) async {
    final client = _serviceClient;
    if (client == null) return;
    await client.from('ingredient_reports').delete().eq('barcode', barcode);
  }

  static Future<void> deleteAiRequestsForBarcode(String barcode) async {
    final client = _serviceClient;
    if (client == null) return;
    await client.from('ai_ingredient_requests').delete().eq('barcode', barcode);
  }

  static Future<void> deleteImageSubmissionsForBarcode(String barcode) async {
    final client = _serviceClient;
    if (client == null) return;
    final rows = await client
        .from('product_image_submissions')
        .select('id, storage_path')
        .eq('barcode', barcode);
    for (final row in List<Map<String, dynamic>>.from(rows)) {
      final path = row['storage_path'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          await client.storage.from('product-images').remove([path]);
        } on Object {
          // Best-effort cleanup — storage object may already be gone.
        }
      }
      await client
          .from('product_image_submissions')
          .delete()
          .eq('id', row['id']);
    }
  }
}
