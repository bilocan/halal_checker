import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, HapticFeedback, FilteringTextInputFormatter;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_colors.dart';
import '../integration_test_keys.dart';
import '../localization/app_localizations.dart';
import '../services/database_service.dart';
import '../services/product_service.dart';
import 'admin_panel_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  MobileScannerController? _scannerController;
  final TextEditingController _barcodeController = TextEditingController();
  bool _isLoading = false;
  bool _scanned = false;
  bool _scannerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      // Try to initialize scanner - this may fail on devices without Google Play Services
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        formats: const [
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
        ],
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      _scannerInitialized = true;
      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      debugPrint('Scanner initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      // Scanner failed to initialize - app will work with manual entry only
      _scannerInitialized = false;
      if (mounted) setState(() {});
    }
  }

  Widget _buildScannerWidget() {
    try {
      if (_scannerController == null) {
        return Container(color: Colors.black);
      }
      return MobileScanner(
        controller: _scannerController!,
        onDetect: _onDetect,
      );
    } catch (e) {
      debugPrint('Scanner widget failed: $e');
      // If scanner widget fails, show fallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _scannerInitialized = false;
          });
        }
      });
      return Container(color: Colors.black);
    }
  }

  bool _isValidBarcode(String value) {
    final code = value.trim();
    return RegExp(r'^\d{6,50}$').hasMatch(code);
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned || _isLoading) return;

    final barcodes = capture.barcodes
        .map((b) => b.rawValue)
        .where((v) => v != null && v.isNotEmpty)
        .cast<String>()
        .toList();

    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      if (_isValidBarcode(barcode)) {
        await _submitBarcode(barcode);
        return;
      }
    }

    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.barcodeNotSupported),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitBarcode(String barcode) async {
    if (_isLoading) return;
    if (!_isValidBarcode(barcode)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseEnterValidBarcode),
        ),
      );
      return;
    }

    setState(() {
      _scanned = true;
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final product = await _productService.getProduct(barcode);
      if (!mounted) return;
      if (product != null) {
        await DatabaseService.instance.insertScan(
          barcode: barcode,
          productName: product.name,
          isHalal: product.isHalal,
        );
      }
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(product: product, barcode: barcode),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).productCouldNotBeRefreshed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _scanned = false;
        });
      }
    }
  }

  Future<void> _showManualEntryDialog() async {
    _barcodeController.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(loc.enterBarcodeManually),
          content: TextField(
            key: IntegrationTestKeys.barcodeField,
            controller: _barcodeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: '0123456789012',
              labelText: loc.enterBarcodeManually,
              prefixIcon: const Icon(Icons.barcode_reader),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste),
                tooltip: 'Paste',
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    final digits = data!.text!.replaceAll(RegExp(r'\D'), '');
                    _barcodeController.text = digits;
                    _barcodeController.selection = TextSelection.collapsed(
                      offset: digits.length,
                    );
                  }
                },
              ),
            ),
            onSubmitted: (value) {
              Navigator.of(dialogContext).pop();
              _submitBarcode(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              key: IntegrationTestKeys.barcodeSubmit,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _submitBarcode(_barcodeController.text);
              },
              child: Text(loc.submit),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Widget _adminButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.admin_panel_settings_outlined),
    tooltip: 'Admin panel',
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // If scanner failed to initialize, show manual entry screen
    if (!_scannerInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.appTitle),
          backgroundColor: kGreen,
          foregroundColor: Colors.white,
          actions: [_adminButton(context)],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'Camera scanner unavailable',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Please enter barcode manually',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                key: IntegrationTestKeys.homeManualEntry,
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.edit),
                label: Text(loc.manualEntry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal scanner UI
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        actions: [_adminButton(context)],
      ),
      body: Stack(
        children: [
          Semantics(
            label: 'Barcode scanner camera view',
            child: _buildScannerWidget(),
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: kGreen, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner, color: kGreen, size: 48),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isLoading ? loc.analyzingBarcode : loc.readyToScan,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.pointCameraAtBarcode,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: ElevatedButton(
              key: IntegrationTestKeys.homeManualEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white70,
                foregroundColor: kGreenDark,
              ),
              onPressed: _showManualEntryDialog,
              child: Text(loc.manualEntry),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: kGreen),
              ),
            ),
        ],
      ),
    );
  }
}
