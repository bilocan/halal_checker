import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_colors.dart';
import '../config.dart';
import '../localization/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/product_image_service.dart';
import '../utils/submission_photo_validator.dart';
import 'result/widgets/copy_barcode_row.dart';

/// Guided flow when a barcode is missing from Open Food Facts: collect
/// front-of-pack and ingredients-list photos and upload to
/// [ProductImageService] for admin review.
class MissingProductPhotoContributionScreen extends StatefulWidget {
  const MissingProductPhotoContributionScreen({
    super.key,
    required this.barcode,
  });

  final String barcode;

  @override
  State<MissingProductPhotoContributionScreen> createState() =>
      _MissingProductPhotoContributionScreenState();
}

class _MissingProductPhotoContributionScreenState
    extends State<MissingProductPhotoContributionScreen> {
  static const int _totalSteps = 4;

  int _step = 0;
  File? _frontFile;
  File? _ingredientsFile;
  bool _uploading = false;

  int get _maxMb =>
      (SubmissionPhotoValidator.defaultMaxBytes / (1024 * 1024)).ceil();

  void _copyBarcode() {
    Clipboard.setData(ClipboardData(text: widget.barcode));
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.labelCopied(loc.barcodeLabel)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  bool get _canGoNext {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return _frontFile != null;
      case 2:
        return _ingredientsFile != null;
      case 3:
        return _frontFile != null && _ingredientsFile != null && !_uploading;
      default:
        return false;
    }
  }

  Future<void> _pickPhoto({required bool front}) async {
    final loc = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(loc.missingProductPickCamera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(loc.missingProductPickGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(source: source, imageQuality: 85);
    } catch (e) {
      debugPrint('ImagePicker error ($source): $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.cameraError)));
      return;
    }
    if (photo == null || !mounted) return;

    final file = await _persistPick(photo);
    final issue = await SubmissionPhotoValidator.validate(file);
    if (!mounted) return;
    if (issue != null) {
      final msg = switch (issue) {
        SubmissionPhotoIssue.tooLarge => loc.missingProductPhotoTooLarge(
          _maxMb,
        ),
        SubmissionPhotoIssue.unreadable => loc.missingProductPhotoUnreadable,
        SubmissionPhotoIssue.resolutionTooLow =>
          loc.missingProductPhotoTooSmall,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    setState(() {
      if (front) {
        _frontFile = file;
      } else {
        _ingredientsFile = file;
      }
    });
  }

  /// Copy gallery/camera output into app temp so paths stay readable at submit.
  Future<File> _persistPick(XFile photo) async {
    final dir = await getTemporaryDirectory();
    final ext = p.extension(photo.path);
    final suffix = ext.isNotEmpty ? ext : '.jpg';
    final dest = File(
      '${dir.path}/pack_${DateTime.now().microsecondsSinceEpoch}$suffix',
    );
    await dest.writeAsBytes(await photo.readAsBytes());
    return dest;
  }

  Future<void> _primaryAction(AppLocalizations loc) async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    await _submit(loc);
  }

  Future<void> _submit(AppLocalizations loc) async {
    if (_frontFile == null || _ingredientsFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.missingProductNeedBoth)));
      return;
    }

    if (!AppConfig.hasSupabase) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.missingProductUploadFailed)));
      return;
    }
    await AuthService.ensureInitialized();
    if (!mounted) return;
    if (AuthService.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.signInRequired)));
      return;
    }

    setState(() => _uploading = true);
    final frontOk = await ProductImageService.uploadImage(
      barcode: widget.barcode,
      imageFile: _frontFile!,
      type: ProductImageType.front,
    );
    final ingOk = await ProductImageService.uploadImage(
      barcode: widget.barcode,
      imageFile: _ingredientsFile!,
      type: ProductImageType.ingredients,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (frontOk && ingOk) {
      Navigator.pop(context, true);
      return;
    }
    if (frontOk || ingOk) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.missingProductOneOfTwoFailed)));
      Navigator.pop(context, false);
      return;
    }
    final detail = ProductImageService.uploadFailureDetail;
    final message = detail != null && detail.isNotEmpty
        ? '${loc.missingProductUploadFailed}\n$detail'
        : loc.missingProductUploadFailed;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _diagram(AppLocalizations loc, {required bool ingredients}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.missingProductExampleLayout,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: CustomPaint(
            painter: _PackPhotoExamplePainter(ingredients: ingredients),
          ),
        ),
      ],
    );
  }

  Widget _stepBody(AppLocalizations loc) {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.missingProductFlowIntro,
              style: TextStyle(height: 1.35, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 12),
            Text(
              loc.missingProductFlowHelpHint,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Text(
              loc.missingProductStepBarcodeTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(loc.missingProductStepBarcodeSubtitle),
            const SizedBox(height: 12),
            CopyBarcodeRow(barcode: widget.barcode, onCopy: _copyBarcode),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.missingProductStepFrontTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              loc.missingProductStepFrontSubtitle,
              style: TextStyle(color: Colors.grey.shade800, height: 1.35),
            ),
            const SizedBox(height: 16),
            _diagram(loc, ingredients: false),
            const SizedBox(height: 16),
            if (_frontFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(_frontFile!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: _uploading ? null : () => _pickPhoto(front: true),
              icon: Icon(
                _frontFile != null ? Icons.refresh : Icons.add_a_photo,
              ),
              label: Text(
                _frontFile != null
                    ? loc.missingProductRetake
                    : loc.missingProductPickCamera,
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.missingProductStepIngredientsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              loc.missingProductStepIngredientsSubtitle,
              style: TextStyle(color: Colors.grey.shade800, height: 1.35),
            ),
            const SizedBox(height: 16),
            _diagram(loc, ingredients: true),
            const SizedBox(height: 16),
            if (_ingredientsFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(_ingredientsFile!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: _uploading ? null : () => _pickPhoto(front: false),
              icon: Icon(
                _ingredientsFile != null ? Icons.refresh : Icons.add_a_photo,
              ),
              label: Text(
                _ingredientsFile != null
                    ? loc.missingProductRetake
                    : loc.missingProductPickCamera,
              ),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.missingProductSubmit,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              loc.missingProductReviewHint,
              style: TextStyle(color: Colors.grey.shade800, height: 1.35),
            ),
            const SizedBox(height: 16),
            if (_frontFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(_frontFile!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 12),
            if (_ingredientsFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(_ingredientsFile!, fit: BoxFit.cover),
                ),
              ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.missingProductFlowTitle),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / _totalSteps,
            backgroundColor: Colors.grey.shade200,
            color: kGreen,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _stepBody(loc),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _uploading
                          ? null
                          : () => setState(() => _step--),
                      child: Text(loc.missingProductBack),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: kGreen),
                        onPressed: !_canGoNext || (_uploading && _step == 3)
                            ? null
                            : () => _primaryAction(loc),
                        child: _uploading && _step == 3
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(loc.missingProductSubmitting),
                                ],
                              )
                            : Text(
                                _step == 3
                                    ? loc.missingProductSubmit
                                    : loc.missingProductContinue,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackPhotoExamplePainter extends CustomPainter {
  _PackPhotoExamplePainter({required this.ingredients});

  final bool ingredients;

  @override
  void paint(Canvas canvas, Size size) {
    final rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    canvas.drawRRect(rRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    if (!ingredients) {
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.32),
        size.width * 0.12,
        Paint()..color = Colors.grey.shade300,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.14,
            size.height * 0.52,
            size.width * 0.72,
            size.height * 0.06,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.grey.shade700,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.08,
            size.height * 0.76,
            size.width * 0.84,
            size.height * 0.09,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.grey.shade800,
      );
      final bc = Paint()..color = Colors.white;
      final barW = size.width * 0.07;
      var x = size.width * 0.22;
      for (var i = 0; i < 8; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            x + i * barW * 1.08,
            size.height * 0.79,
            barW * 0.72,
            size.height * 0.046,
          ),
          bc,
        );
      }
    } else {
      for (var i = 0; i < 7; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.06,
              size.height * 0.08 + i * size.height * 0.085,
              size.width * 0.88,
              size.height * 0.055,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = Colors.grey.shade300,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.06,
            size.height * 0.64,
            size.width * 0.55,
            size.height * 0.055,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.blueGrey.shade200,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PackPhotoExamplePainter oldDelegate) =>
      oldDelegate.ingredients != ingredients;
}
