import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../services/database_service.dart';
import '../services/product_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.itf14,
      BarcodeFormat.codabar,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.qrCode,
      BarcodeFormat.pdf417,
      BarcodeFormat.aztec,
    ],
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final TextEditingController _barcodeController = TextEditingController();
  bool _isLoading = false;
  bool _scanned = false;

  bool _isValidBarcode(String value) {
    final code = value.trim();
    // No spaces; standard barcode characters only; min 6 chars
    return RegExp(r'^[0-9A-Za-z\-\.\$+\%\/\*]{6,50}$').hasMatch(code);
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
            controller: _barcodeController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(hintText: 'e.g. 0123456789012'),
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
    _scannerController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
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
