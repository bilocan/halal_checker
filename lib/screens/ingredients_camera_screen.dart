import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/ingredient_sanitizer.dart';
import '../services/ocr_service.dart';
import '../services/product_service.dart';
import 'result_screen.dart';

class IngredientsCameraScreen extends StatefulWidget {
  const IngredientsCameraScreen({super.key});

  @override
  State<IngredientsCameraScreen> createState() =>
      _IngredientsCameraScreenState();
}

class _IngredientsCameraScreenState extends State<IngredientsCameraScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndAnalyze());
  }

  Future<void> _captureAndAnalyze() async {
    final loc = AppLocalizations.of(context);

    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.cameraError)));
        Navigator.pop(context);
      }
      return;
    }

    if (photo == null || !mounted) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final text = await OcrService.extractIngredientsFromFile(
        File(photo.path),
      );
      if (!mounted) return;

      if (text == null || text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.ocrFailed)));
        setState(() => _isProcessing = false);
        return;
      }

      final ingredients = IngredientSanitizer.sanitize(text);
      final analysis = ProductService.analyzeWithKeywords(ingredients);
      final barcode = 'photo_${DateTime.now().millisecondsSinceEpoch}';

      final product = Product(
        barcode: barcode,
        name: loc.photoAnalysisProductName,
        ingredients: ingredients,
        isHalal: analysis.isHalal,
        haramIngredients: analysis.haram,
        suspiciousIngredients: analysis.suspicious,
        ingredientWarnings: analysis.warnings,
        ingredientTranslations: analysis.translations,
        labels: const [],
        explanation: analysis.explanation,
        analyzedByAI: false,
        analysisMethod: 'keyword',
      );

      await DatabaseService.instance.insertScan(
        barcode: barcode,
        productName: product.name,
        isHalal: product.isHalal,
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(product: product, barcode: barcode),
        ),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.photoIngredientsButton),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator(color: kGreen)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _captureAndAnalyze,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(loc.takePhotoOfIngredients),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
