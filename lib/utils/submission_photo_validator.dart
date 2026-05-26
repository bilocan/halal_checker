import 'dart:io';
import 'dart:ui' as ui;

/// Client-side checks before uploading pack photos for missing products.
class SubmissionPhotoValidator {
  SubmissionPhotoValidator._();

  /// Default max file size (bytes) for a single photo.
  static const int defaultMaxBytes = 10 * 1024 * 1024;

  /// Minimum shorter side in pixels (sharp enough for OCR / review).
  static const int defaultMinShortEdge = 360;

  /// Returns `null` if the file is acceptable; otherwise a reason code.
  static Future<SubmissionPhotoIssue?> validate(
    File file, {
    int maxBytes = defaultMaxBytes,
    int minShortEdge = defaultMinShortEdge,
  }) async {
    final len = await file.length();
    if (len > maxBytes) {
      return SubmissionPhotoIssue.tooLarge;
    }
    final bytes = await file.readAsBytes();
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      final w = image.width;
      final h = image.height;
      image.dispose();
      final short = w < h ? w : h;
      if (short < minShortEdge) {
        return SubmissionPhotoIssue.resolutionTooLow;
      }
      return null;
    } catch (_) {
      return SubmissionPhotoIssue.unreadable;
    }
  }
}

enum SubmissionPhotoIssue { tooLarge, unreadable, resolutionTooLow }
