# HalalScan — testing guide

How to run and extend tests at every layer: fast CI checks, live API integration, full-app UI E2E (no widget mocks), and on-device OCR.

**Prerequisites:**

- **App (dev / release):** `dart_defines.example.json` → `dart_defines.json` (your Supabase project for `flutter run`).
- **Pipeline integration:** `dart_defines.integration.example.json` → `dart_defines.integration.json` (**dedicated test Supabase project** — never production).
- **UI E2E:** `dart_defines.e2e.example.json` → `dart_defines.e2e.json` (local Docker Supabase) — see [Local Supabase for E2E](#local-supabase-for-e2e).

---

## Test pyramid

| Layer | What it exercises | Device? | CI? | Location |
|-------|-------------------|---------|-----|----------|
| **Unit / service** | Rules engine, keywords, cache, parsing, mocked HTTP | No | Yes | `test/services/`, `test/constants/`, `test/models/` |
| **Widget** | Individual screens with stubs (`test/helpers/`) | No | Yes | `test/screens/` |
| **Pipeline integration** | Real `ProductService` / Supabase services (test project) | No | Optional | `test/integration/` |
| **UI E2E** | Full app: navigation + real lookup + result UI | Yes | No | `integration_test/ui_barcode_flow_test.dart` |
| **OCR E2E** | ML Kit → sanitizer → keywords on a photo | Yes | No | `integration_test/ocr_pipeline_test.dart` |

Use **CI tests** on every change. Run **UI E2E** after refactors or features that touch navigation, scan flow, or result screens.

---

## CI — fast tests (no device)

```bash
./scripts/linux/format_dart.sh          # Linux/macOS/Git Bash
# .\scripts\windows\format_dart.ps1     # Windows PowerShell
flutter analyze --no-fatal-infos
flutter test test/services/ test/constants/ test/models/ test/config_test.dart
deno test --allow-env supabase/functions/lookup-product/
```

GitHub Actions (`.github/workflows/test.yml`) runs the same Flutter and Deno commands on every push and pull request.

**Widget tests** (`test/screens/`) use `wrapWithTestApp()` and optional service stubs — they catch layout and tab logic quickly but **do not** replace UI E2E.

---

## UI E2E — full app, no widget mocks

Use this when you need confidence that the **real UI** still works after refactors (Selenium-style, but native Flutter `integration_test`).

### What runs

- `app.main()` — real `MaterialApp`, `ProductService`, SQLite history, navigation
- User flow: **Home → Start Scan → Enter barcode manually → Result**
- Assertions on verdict UI via stable keys (not hardcoded fake `Product` objects)

### Requirements

- Android emulator, iOS simulator, or physical device connected
- **`dart_defines.e2e.json`** (local Supabase — **not** `dart_defines.json`)
- Local stack running: `scripts/start_e2e_supabase.ps1` + `supabase functions serve` (see below)

### Local Supabase for E2E

UI E2E uses a **separate** defines file so you never point tests at production by mistake.

| File | Purpose |
|------|---------|
| `dart_defines.e2e.example.json` | Template — `http://127.0.0.1:54321` + local demo anon key |
| `dart_defines.e2e.android-emulator.example.json` | Same, but `http://10.0.2.2:54321` for Android emulator |
| `dart_defines.e2e.json` | Your copy (gitignored) |
| `supabase/.env.e2e.example` | Optional AI keys for `functions serve` → copy to `supabase/.env.local` |

**1. Start local Supabase (Docker via Supabase CLI)**

```powershell
.\scripts\start_e2e_supabase.ps1
```

```bash
chmod +x scripts/start_e2e_supabase.sh run_ui_e2e_test.sh
./scripts/start_e2e_supabase.sh
```

This runs `supabase start` and `supabase db reset` (applies `supabase/migrations/`).

**2. Serve the lookup edge function** (second terminal)

```bash
cp supabase/.env.e2e.example supabase/.env.local   # optional AI keys
supabase functions serve lookup-product --no-verify-jwt --env-file supabase/.env.local
```

Without `CLAUDE_API_KEY`, lookup still works via Open Food Facts + keywords for many barcodes.

**3. Create E2E defines**

```bash
cp dart_defines.e2e.example.json dart_defines.e2e.json
# Android emulator only:
cp dart_defines.e2e.android-emulator.example.json dart_defines.e2e.json
```

The example sets `E2E_LIVE_LOOKUP=true` so lookups hit your **local** edge function instead of the debug offline test DB.

**4. Run UI E2E** (device connected)

```powershell
.\run_ui_e2e_test.ps1
```

**Writes:** E2E upserts go to your **local** `products` / `product_analysis` tables only (via `lookup-product`), plus local SQLite scan history on the device. Production Supabase is not used when `dart_defines.e2e.json` points at `127.0.0.1` / `10.0.2.2`.

**iOS simulator / desktop:** use `127.0.0.1`. **Android emulator:** use `10.0.2.2` (debug build allows HTTP via `network_security_config.xml`).

### Run

**Windows (PowerShell):**

```powershell
.\run_ui_e2e_test.ps1
.\run_ui_e2e_test.ps1 -DefinesFile dart_defines.e2e.android-emulator.json
.\run_ui_e2e_test.ps1 -BarcodesFile test/barcodes.txt -Timeout 300
```

**Linux / macOS:**

```bash
./run_ui_e2e_test.sh
DEFINES_FILE=dart_defines.e2e.android-emulator.json ./run_ui_e2e_test.sh
./run_ui_e2e_test.sh test/barcodes.txt 300
```

### Data file

Default: `test/barcodes_e2e.txt` (short list for quick runs).

Format (same as `test/barcodes.txt`):

```
<barcode> [expected: halal|haram|unknown|not_found]
```

- `unknown` — product exists but verdict is inconclusive (`e2e-result-unknown`).
- `not_found` — no product (`e2e-product-not-found`).

Lines starting with `#` are comments. Only rows with an `expected` value are asserted in UI E2E.

To use the full barcode list:

```powershell
.\run_ui_e2e_test.ps1 -BarcodesFile test/barcodes.txt -Timeout 300
```

### E2E dart-defines (`dart_defines.e2e.json`)

| Define | Typical value | Purpose |
|--------|---------------|---------|
| `SUPABASE_URL` | `http://127.0.0.1:54321` or `http://10.0.2.2:54321` | Local Docker API |
| `SUPABASE_ANON_KEY` | Local demo JWT (in example file) | From `supabase status` |
| `E2E_FORCE_LOCALE` | `en` | Stable English UI |
| `E2E_LIVE_LOOKUP` | `true` | Skip debug test DB; use network / local edge fn |
| `E2E_BARCODES_FILE` | Set by runner script | Barcode list path |
| `E2E_SKIP_CAMERA` | `true` (runner only) | Manual barcode UI; no `MobileScanner` |

Optional CLI override: `-LiveLookup` / `LIVE_LOOKUP=1` forces `E2E_LIVE_LOOKUP=true` even if omitted from JSON.

Read in `lib/config.dart`; test DB bypass is in `ProductService` when `AppConfig.e2eLiveLookup` is true.

### Stable keys

Production widgets expose keys from `lib/integration_test_keys.dart`:

| Key | Widget |
|-----|--------|
| `e2e-start-scan` | Home tab — Start Scan |
| `e2e-home-manual-entry` | Scanner / fallback — manual barcode |
| `e2e-barcode-field` | Manual entry dialog |
| `e2e-barcode-submit` | Manual entry dialog — Submit |
| `e2e-result-halal` / `haram` / `unknown` | Result status banner |
| `e2e-product-not-found` | Product not found body |
| `e2e-result-home` | Result bottom nav — Home (pop to scanner) |
| `e2e-scanner-back` | Scanner AppBar — back to start home tab |

When adding new E2E flows, prefer new keys in that file over `find.text(...)` (locale-safe). Grep `e2e-` in `lib/` for the full key list.

### UI E2E coverage

Tracked in three places (keep them in sync):

| Artifact | Role |
|----------|------|
| [`test/e2e_coverage.json`](test/e2e_coverage.json) | Machine-readable registry (scenarios, keys, gaps) |
| [`test/barcodes_e2e.txt`](test/barcodes_e2e.txt) | Barcodes exercised on device |
| [`lib/integration_test_keys.dart`](lib/integration_test_keys.dart) | Stable widget keys |
| Table below | Human-readable summary |

**Preview (read the registry):**

```bash
./scripts/preview_e2e_coverage.sh
# or: dart run tool/e2e_coverage_report.dart
```

Prints automated scenarios, gaps, and which barcodes/keys are wired — for humans, not consumed by the app.

**Validate (CI sync check):**

```bash
./scripts/validate_e2e_coverage.sh
# or: flutter test test/constants/e2e_coverage_test.dart
```

CI runs this via `flutter test test/constants/`. The check fails if you add an `e2e-*` key or SCN barcode line without updating the registry.

**How the pieces connect:**

```text
test/e2e_coverage.json          ← you edit (checklist + documentation)
        │
        ├─► dart run tool/e2e_coverage_report.dart     ← preview in terminal
        ├─► test/constants/e2e_coverage_test.dart      ← CI: JSON ↔ keys ↔ barcodes
        └─► TESTING.md table                         ← same info for reading in git

integration_test/ui_barcode_flow_test.dart  ← runs on device
        │
        └─► reads test/barcodes_e2e.txt only (NOT the JSON file)
```

**Line coverage:** UI E2E on a device does not feed CI Codecov (only unit tests do). Use the registry + scenario IDs for flow coverage, not `lcov` percentages.

Tracked by **scenario ID** (`SCN-xxx`). Update the JSON and this table when you add a scenario, key, or test file.

| ID | Screen / flow | UI E2E | Widget (`test/screens/`) | Pipeline (`test/integration/`) | Notes |
|----|---------------|--------|---------------------------|----------------------------------|-------|
| SCN-001 | Start → scan → manual entry → **halal** result | Yes | Partial | Via `90098369` in `barcodes.txt` | Default `barcodes_e2e.txt` |
| SCN-002 | Same path → **haram** result | Yes | Partial | Via `5014379008630` | Default `barcodes_e2e.txt` |
| SCN-003 | Same path → **inconclusive** (`unknown`) | Yes | Partial | — | `9999999999999 unknown` |
| SCN-004 | Same path → **not found** | Yes | Partial | — | use `not_found` when lookup returns no product |
| — | Camera scan | No | No | — | Manual entry only (camera never settles) |
| — | Result: ingredients, community, deep analysis, images | No | Partial | — | |
| — | Start tabs: Keywords, Directory, About, Admin | No | `start_screen_*` | — | Screenshots test opens Directory only |
| — | Batch scan, ingredient OCR, discussions | No | No | — | |
| — | Auth / sign-in sheets | No | No | — | |
| — | OCR pipeline (photo → keywords) | No | — | — | `ocr_pipeline_test.dart` (`@manual`) |

**Other integration tests (not UI regression):**

| File | Purpose |
|------|---------|
| `integration_test/ocr_pipeline_test.dart` | ML Kit OCR + sanitizer on device (`@manual`) |
| `integration_test/screenshots_test.dart` | Store screenshots; fake `Product` data |
| `test/integration/barcode_lookup_test.dart` | Live lookup API, no UI |

When adding new E2E flows, prefer new keys in that file over `find.text(...)` (locale-safe).

### Implementation notes

- **Camera:** Only automated UI E2E passes `E2E_SKIP_CAMERA=true` (manual entry UI; no `MobileScanner`). Normal runs with `dart_defines.e2e.json` still use the camera — grant permission on the emulator (**Allow**) or run `adb shell pm grant app.halalscan.dev android.permission.CAMERA`. `run_ui_e2e_test.sh` grants CAMERA when `adb` is available.
- **Stuck after lookup logs (result on emulator, test idle):** the test uses `LiveTestWidgetsFlutterBindingFramePolicy.fullyLive` and waits for `ResultScreen` / e2e keys after the manual-entry dialog closes. If it still hangs, check the failure text for the verdict actually shown vs `test/barcodes_e2e.txt`.
- **Debug test DB:** barcodes in `test_data/` may resolve offline in debug without `-LiveLookup`. UI is still real; use `-LiveLookup` to mirror production network behavior.
- **Tagged `e2e`:** skipped by default in `dart_test.yaml`; always run via `run_ui_e2e_test.ps1` / `.sh`.

### Adding a UI E2E scenario

1. Pick or add a **scenario ID** in the [UI E2E coverage](#ui-e2e-coverage) table (`SCN-xxx`).
2. Add a commented line to `test/barcodes_e2e.txt` with `halal`, `haram`, `unknown`, or `not_found` (or extend `ui_barcode_flow_test.dart` for non-barcode flows).
3. If a new control needs tapping, add a key in `integration_test_keys.dart`, wire it on the production widget, and document it in the table above.
4. Run `.\run_ui_e2e_test.ps1` / `./run_ui_e2e_test.sh` on a connected device.

Source: `integration_test/ui_barcode_flow_test.dart`, helpers in `integration_test/helpers/`.

---

## Pipeline integration — live API (no UI)

Exercises `ProductService` and Supabase-backed services against a **hosted test Supabase project** (not `dart_defines.json` / production).

### Setup (once per machine)

```bash
cp dart_defines.integration.example.json dart_defines.integration.json
```

Edit `dart_defines.integration.json`:

| Field | Purpose |
|-------|---------|
| `INTEGRATION_PROJECT_REF` | Test project ref (must match `SUPABASE_URL` host; blocks accidental prod URL) |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | **Test** Supabase project (apply the same migrations as prod) |
| `SUPABASE_TEST_EMAIL` / `SUPABASE_TEST_PASSWORD` | User for authenticated flows |
| `SUPABASE_TEST_ADMIN_EMAIL` / `SUPABASE_TEST_ADMIN_PASSWORD` | Admin for approve / RLS tests |
| `SUPABASE_SERVICE_ROLE_KEY` | Required for admin integration tests (sets `profiles.role`) and tear-down cleanup (never ship in the app) |

Create test users in the test project Auth dashboard (or seed script). Deploy `lookup-product` to the test project if you run barcode lookup integration.

### Helper scripts

All scripts use `dart_defines.integration.json` by default (`-DefinesFile` / `DEFINES_FILE` to override).

```bash
# Linux/macOS — single file
./run_integration_test.sh test/integration/barcode_lookup_test.dart
./run_integration_test.sh test/integration/supabase_services_integration_test.dart 300

# Both integration suites
./run_all_integration_tests.sh
./run_all_integration_tests.sh 300

# Windows
.\run_integration_test.ps1 -TestFile test/integration/barcode_lookup_test.dart
.\run_all_integration_tests.ps1 -Timeout 300
```

### CI (GitHub Actions)

Workflow [`.github/workflows/integration.yml`](.github/workflows/integration.yml) runs on `main` pushes (when integration paths change) and `workflow_dispatch`. It **skips** until repository secrets are set:

| Secret | Maps to define |
|--------|----------------|
| `INTEGRATION_SUPABASE_URL` | `SUPABASE_URL` |
| `INTEGRATION_SUPABASE_ANON_KEY` | `SUPABASE_ANON_KEY` |
| `INTEGRATION_SUPABASE_TEST_EMAIL` | `SUPABASE_TEST_EMAIL` |
| `INTEGRATION_SUPABASE_TEST_PASSWORD` | `SUPABASE_TEST_PASSWORD` |
| `INTEGRATION_SUPABASE_TEST_ADMIN_EMAIL` | `SUPABASE_TEST_ADMIN_EMAIL` |
| `INTEGRATION_SUPABASE_TEST_ADMIN_PASSWORD` | `SUPABASE_TEST_ADMIN_PASSWORD` |
| `INTEGRATION_SUPABASE_SERVICE_ROLE_KEY` | `SUPABASE_SERVICE_ROLE_KEY` |

Unit tests in [`.github/workflows/test.yml`](.github/workflows/test.yml) stay fast and do **not** call Supabase.

### Barcode lookup

`test/integration/barcode_lookup_test.dart` reads `test/barcodes.txt`, calls `ProductService.refreshProduct()` for each barcode, prints a table, and asserts optional expected outcomes.

```bash
./run_integration_test.sh test/integration/barcode_lookup_test.dart
```

Without credentials (OpenFoodFacts + keywords only):

```bash
flutter test test/integration/barcode_lookup_test.dart --timeout 120s
```

### Supabase services

`test/integration/supabase_services_integration_test.dart` — real PostgREST / storage for ingredient reports, AI requests, and product images (no fakes).

```bash
./run_integration_test.sh test/integration/supabase_services_integration_test.dart
```

---

## OCR testing

ML Kit requires a real device; sanitizer logic is covered in the VM.

### Layer 1 — unit (CI)

`test/services/ingredient_sanitizer_test.dart` — sanitize → keyword analysis on realistic label text (no camera).

```bash
flutter test test/services/ingredient_sanitizer_test.dart
```

### Layer 2 — device integration

`integration_test/ocr_pipeline_test.dart`:

```
image → ML Kit OCR → IngredientSanitizer → analyzeWithKeywords → assertions
```

1. Place label photo at `test/assets/soletti_ingredients.jpeg` (see existing test).
2. Connect device or emulator.
3. Run:

```bash
flutter test integration_test/ocr_pipeline_test.dart
```

Tagged `manual` in `dart_test.yaml` — run explicitly.

#### Adding a new product image

1. Save a clear label photo to `test/assets/<product-name>.jpg` (`pubspec.yaml` already includes `test/assets/`).
2. List expected ingredients as **lowercase substrings** (tolerates OCR capitalization).
3. Copy the Soletti group in `integration_test/ocr_pipeline_test.dart`:

```dart
const _myProductExpectedIngredients = <String>[
  'zucker',
  'wheat flour',
  'whey powder', // suspicious — assert in analysis test too
];

group('OCR → Sanitize → Analyze — My Product label', () {
  File? imageFile;
  String? rawOcrText;
  List<String> ingredients = const [];

  setUpAll(() async {
    final data = await rootBundle.load('test/assets/my-product.jpg');
    final dir = await getTemporaryDirectory();
    imageFile = File('${dir.path}/my_product_test.jpg');
    await imageFile!.writeAsBytes(data.buffer.asUint8List());
    rawOcrText = await OcrService.extractIngredientsFromFile(imageFile!);
    ingredients = rawOcrText != null
        ? IngredientSanitizer.sanitize(rawOcrText!)
        : [];
  });

  tearDownAll(() async {
    await imageFile?.delete().catchError((_) => imageFile!);
  });

  for (final expected in _myProductExpectedIngredients) {
    test('sanitized output contains "$expected"', () {
      final lower = ingredients.map((e) => e.toLowerCase()).toList();
      expect(
        lower.any((e) => e.contains(expected)),
        isTrue,
        reason:
            '"$expected" not found.\nSanitized:\n  ${ingredients.join('\n  ')}',
      );
    });
  }

  test('analysis verdict is correct', () {
    final result = ProductService.analyzeWithKeywords(ingredients);
    expect(result.isHalal, isTrue); // or isFalse for haram products
    expect(result.haram, isEmpty);
  });
});
```

For sub-ingredient parents (`raising agents (…)`), also assert the token still contains `(`.

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Ingredient missing | OCR missed region | Retake photo or drop from expected list |
| Split across entries | Line-wrap | Fix `IngredientSanitizer` + unit test |
| `(…)` list split | Comma inside parens | `_smartSplit` + `ingredient_sanitizer_test.dart` |
| Not flagged | Missing keyword | `IngredientKeywords` + `keyword_analysis_test.dart` |

---

## Screenshots (optional)

`integration_test/screenshots_test.dart` drives the app for store screenshots. Some steps push screens with **sample** `Product` data — fine for marketing assets, not for regression of live lookup.

Run on device with `flutter test integration_test/screenshots_test.dart` and `test_driver/integration_test.dart` for screenshot capture.

---

## Offline fixtures (debug app)

- `test_data/seed_products.json` — pre-classified products in `halal_test.db` (debug only).
- Append barcodes to `test_data/seed_barcodes.txt`; next debug launch fetches and freezes them.

Used for offline dev, not for UI E2E unless you intentionally test fixture barcodes.

---

## Which test should I write?

| Change | Run |
|--------|-----|
| Keyword / rules / cache logic | Unit tests in `test/services/` |
| Tab layout, admin visibility | Widget tests in `test/screens/` |
| Lookup pipeline / edge function behavior | `barcode_lookup_test.dart` |
| Scan flow, result screen, navigation | **UI E2E** (`run_ui_e2e_test.ps1`) |
| OCR / sanitizer on real labels | `ingredient_sanitizer_test.dart` + `ocr_pipeline_test.dart` |
| Before merge (default) | CI command at top of this doc |

---

## File reference

| Path | Role |
|------|------|
| `test/barcodes.txt` | Pipeline integration barcode list |
| `test/barcodes_e2e.txt` | Default UI E2E barcode list |
| `test/e2e_coverage.json` | UI E2E scenario + gap registry |
| `scripts/preview_e2e_coverage.sh` | Print human-readable coverage report |
| `tool/e2e_coverage_report.dart` | Same report (`dart run tool/...`) |
| `scripts/validate_e2e_coverage.sh` | Validate registry vs keys/barcodes (no device) |
| `run_integration_test.ps1` / `.sh` | Pipeline integration runner (`dart_defines.integration.json`) |
| `run_all_integration_tests.ps1` / `.sh` | Barcode lookup + Supabase services |
| `dart_defines.integration.example.json` | Integration defines template (test Supabase project) |
| `dart_defines.e2e.example.json` | E2E defines template (local Supabase) |
| `.github/workflows/integration.yml` | Optional CI against test Supabase secrets |
| `scripts/start_e2e_supabase.ps1` / `.sh` | Start Docker Supabase + migrations |
| `run_ui_e2e_test.ps1` / `.sh` | UI E2E runner (uses `dart_defines.e2e.json`) |
| `lib/integration_test_keys.dart` | E2E widget keys |
| `dart_test.yaml` | Tags: `manual`, `e2e` (skipped unless explicit) |
| `.github/workflows/test.yml` | CI unit tests |
