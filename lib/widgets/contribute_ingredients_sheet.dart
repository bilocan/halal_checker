import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../models/product.dart';
import '../services/ingredient_contribution_service.dart';
import '../services/ingredient_sanitizer.dart';
import '../services/ocr_service.dart';

// Picks an image outside the bottom sheet (avoids Android ActivityResult issues),
// runs OCR, then reopens the contribution sheet pre-filled with the result.
Future<void> pickImageAndContribute(
  BuildContext context,
  Product product,
  AppLocalizations loc,
  ImageSource source, {
  required VoidCallback onContributed,
}) async {
  XFile? photo;
  try {
    photo = await ImagePicker().pickImage(source: source, imageQuality: 85);
  } catch (e) {
    debugPrint('ImagePicker error ($source): $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          source == ImageSource.camera ? loc.cameraError : loc.ocrFailed,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  if (photo == null || !context.mounted) return;

  final file = File(photo.path);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  final text = await OcrService.extractIngredientsFromFile(file);
  debugPrint(
    'OCR result: ${text == null ? "null" : "${text.length} chars: ${text.substring(0, text.length.clamp(0, 120))}"}',
  );

  if (!context.mounted) return;
  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text != null && text.isNotEmpty ? loc.ocrSuccess : loc.ocrFailed,
      ),
      duration: Duration(seconds: text != null && text.isNotEmpty ? 3 : 5),
    ),
  );

  if (!context.mounted) return;
  showContributeIngredientsSheet(
    context,
    product,
    loc,
    initialPreviewFile: file,
    initialOcrText: text,
    onContributed: onContributed,
  );
}

void showContributeIngredientsSheet(
  BuildContext context,
  Product product,
  AppLocalizations loc, {
  File? initialPreviewFile,
  String? initialOcrText,
  required VoidCallback onContributed,
}) {
  final initSections = initialOcrText != null
      ? IngredientSanitizer.sanitizeByLanguage(initialOcrText)
      : <String, List<String>>{};
  var rawOcrSections = initSections;
  var selectedLangs = initSections.keys.toSet();

  List<String> chipsFromSections() => [
    for (final l in rawOcrSections.keys)
      if (selectedLangs.contains(l)) ...rawOcrSections[l]!,
  ];

  var chips = selectedLangs.isEmpty ? <String>[] : chipsFromSections();
  final addController = TextEditingController();
  var isLoading = false;
  var isExtracting = false;
  File? previewFile = initialPreviewFile;
  String? previewUrl;

  Future<void> runOcrOnUrl(
    String url,
    StateSetter setSheetState,
    BuildContext ctx,
  ) async {
    if (ctx.mounted) setSheetState(() => isExtracting = true);
    final text = await OcrService.extractIngredientsFromImage(url);
    if (!context.mounted) return;
    if (ctx.mounted) {
      setSheetState(() => isExtracting = false);
      if (text != null && text.isNotEmpty) {
        final sections = IngredientSanitizer.sanitizeByLanguage(text);
        setSheetState(() {
          rawOcrSections = sections;
          selectedLangs = sections.keys.toSet();
          chips = chipsFromSections();
          addController.clear();
        });
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text != null && text.isNotEmpty
              ? loc.ocrSuccess
              : loc.ocrNoIngredientsFound,
        ),
        duration: Duration(seconds: text != null && text.isNotEmpty ? 3 : 5),
      ),
    );
  }

  final offImages = _candidateImageUrls(product);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  loc.contributeIngredients,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              loc.contributeIngredientsHint,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (offImages.isNotEmpty) ...[
              Text(
                loc.productImages,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: offImages.map((url) {
                    final selected = previewUrl == url && previewFile == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: isExtracting || isLoading
                            ? null
                            : () async {
                                setSheetState(() {
                                  previewUrl = url;
                                  previewFile = null;
                                });
                                await runOcrOnUrl(url, setSheetState, ctx);
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 80,
                                width: 80,
                                color: Colors.grey.shade200,
                              ),
                              errorWidget: (context, url, e) => Container(
                                height: 80,
                                width: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (previewFile != null || previewUrl != null) ...[
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.black,
                    insetPadding: EdgeInsets.zero,
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 6,
                      child: previewFile != null
                          ? Image.file(previewFile!, fit: BoxFit.contain)
                          : CachedNetworkImage(
                              imageUrl: previewUrl!,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: previewFile != null
                          ? Image.file(
                              previewFile!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            )
                          : CachedNetworkImage(
                              imageUrl: previewUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.zoom_in,
                        color: Colors.white.withValues(alpha: 0.8),
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              icon: isExtracting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library, size: 18),
              label: Text(
                isExtracting
                    ? loc.extractingIngredients
                    : loc.extractFromExistingImage,
              ),
              onPressed: isExtracting || isLoading
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      pickImageAndContribute(
                        context,
                        product,
                        loc,
                        ImageSource.gallery,
                        onContributed: onContributed,
                      );
                    },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: isExtracting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt, size: 18),
              label: Text(
                isExtracting
                    ? loc.extractingIngredients
                    : loc.takePhotoOfIngredients,
              ),
              onPressed: isExtracting || isLoading
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      pickImageAndContribute(
                        context,
                        product,
                        loc,
                        ImageSource.camera,
                        onContributed: onContributed,
                      );
                    },
            ),
            const SizedBox(height: 12),
            if (rawOcrSections.length > 1) ...[
              const SizedBox(height: 4),
              Text(
                'Language',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: rawOcrSections.keys.map((lang) {
                  return FilterChip(
                    label: Text(IngredientSanitizer.langDisplayName(lang)),
                    selected: selectedLangs.contains(lang),
                    selectedColor: Colors.orange.shade100,
                    onSelected: (val) {
                      setSheetState(() {
                        if (val) {
                          selectedLangs.add(lang);
                        } else {
                          selectedLangs.remove(lang);
                        }
                        chips = chipsFromSections();
                        addController.clear();
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            if (chips.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'No ingredients added yet.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: chips.asMap().entries.map((entry) {
                  return InputChip(
                    label: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 13),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () =>
                        setSheetState(() => chips.removeAt(entry.key)),
                    onPressed: () {
                      final editCtrl = TextEditingController(
                        text: chips[entry.key],
                      );
                      showDialog<void>(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Edit ingredient'),
                          content: TextField(
                            controller: editCtrl,
                            autofocus: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) {
                              final v = editCtrl.text.trim();
                              setSheetState(() {
                                if (v.isEmpty) {
                                  chips.removeAt(entry.key);
                                } else {
                                  chips[entry.key] = v;
                                }
                              });
                              Navigator.pop(dialogCtx);
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                final v = editCtrl.text.trim();
                                setSheetState(() {
                                  if (v.isEmpty) {
                                    chips.removeAt(entry.key);
                                  } else {
                                    chips[entry.key] = v;
                                  }
                                });
                                Navigator.pop(dialogCtx);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: addController,
                    decoration: InputDecoration(
                      hintText: loc.ingredientTextHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) {
                      final parts = v
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      if (parts.isEmpty) return;
                      setSheetState(() {
                        chips.addAll(parts);
                        addController.clear();
                      });
                    },
                    onChanged: (v) {
                      if (!v.contains(',')) return;
                      final parts = v
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      if (parts.isEmpty) return;
                      setSheetState(() {
                        chips.addAll(parts);
                        addController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isExtracting || isLoading
                      ? null
                      : () {
                          final parts = addController.text
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();
                          if (parts.isEmpty) return;
                          setSheetState(() {
                            chips.addAll(parts);
                            addController.clear();
                          });
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(loc.submit),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading || isExtracting
                  ? null
                  : () async {
                      if (chips.isEmpty) return;
                      final text = chips.join(', ');
                      setSheetState(() => isLoading = true);
                      final ok =
                          await IngredientContributionService.submitIngredients(
                            barcode: product.barcode,
                            ingredientText: text,
                          );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? loc.ingredientSubmitted
                                : loc.ingredientSubmitFailed,
                          ),
                        ),
                      );
                      if (ok) onContributed();
                    },
            ),
          ],
        ),
      ),
    ),
  );
}

List<String> _candidateImageUrls(Product product) {
  final urls = <String>[];
  if (product.imageIngredientsUrl != null) {
    urls.add(product.imageIngredientsUrl!);
  }
  if (product.imageFrontUrl != null && !urls.contains(product.imageFrontUrl)) {
    urls.add(product.imageFrontUrl!);
  }
  if (product.imageUrl != null && !urls.contains(product.imageUrl)) {
    urls.add(product.imageUrl!);
  }
  return urls;
}
