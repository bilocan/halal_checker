// Run with: dart run scripts/generate_icon.dart
// Generates assets/icon/icon.png and assets/icon/icon_fg.png (adaptive foreground)

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  _generateIcon('assets/icon/icon.png', size: 1024, withBackground: true);
  _generateIcon('assets/icon/icon_fg.png', size: 1024, withBackground: false);
  print('Icons written to assets/icon/');
}

void _generateIcon(String path, {required int size, required bool withBackground}) {
  final image = img.Image(width: size, height: size);

  final bg = img.ColorRgba8(27, 94, 32, 255);   // #1B5E20 dark forest green
  final fg = img.ColorRgba8(255, 255, 255, 255); // white
  final barColor = img.ColorRgba8(27, 94, 32, 255); // bars cut back to bg color

  // Background
  if (withBackground) {
    img.fill(image, color: bg);
  } else {
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  }

  final cx = size / 2.0;
  final cy = size / 2.0;

  // --- Crescent moon ---
  final outerR = size * 0.38;
  final innerR = size * 0.32;
  final innerOffsetX = size * 0.10;
  final innerOffsetY = size * -0.02;

  // --- Barcode lines parameters ---
  const lineCount = 11;
  final lineWidth = (size * 0.030).round();
  final spacing = size * 0.058;
  final startX = cx - (lineCount / 2.0) * spacing;

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx1 = x - cx;
      final dy1 = y - cy;
      final inOuter = dx1 * dx1 + dy1 * dy1 <= outerR * outerR;

      final dx2 = x - (cx + innerOffsetX);
      final dy2 = y - (cy + innerOffsetY);
      final inInner = dx2 * dx2 + dy2 * dy2 <= innerR * innerR;

      final inCrescent = inOuter && !inInner;
      if (!inCrescent) continue;

      // Check if this pixel is inside a barcode bar
      bool inBar = false;
      for (var i = 0; i < lineCount; i++) {
        final lx = startX + i * spacing;
        if (x >= lx && x < lx + lineWidth) {
          // Vary bar height: taller in centre
          final mid = (lineCount - 1) / 2.0;
          final t = 1.0 - ((i - mid).abs() / mid);
          final barH = outerR * 2 * (0.5 + t * 0.42);
          final barTop = cy - barH / 2;
          final barBot = cy + barH / 2;
          if (y >= barTop && y <= barBot) {
            inBar = true;
            break;
          }
        }
      }

      image.setPixelRgba(x, y,
        inBar ? barColor.r.toInt() : fg.r.toInt(),
        inBar ? barColor.g.toInt() : fg.g.toInt(),
        inBar ? barColor.b.toInt() : fg.b.toInt(),
        255,
      );
    }
  }

  // --- 4-point star above the crescent tip ---
  final starCx = cx + outerR * 0.52;
  final starCy = cy - outerR * 0.68;
  final starR = size * 0.055;
  _drawStar(image, starCx, starCy, starR, fg);

  File(path).writeAsBytesSync(img.encodePng(image));
}

void _drawStar(img.Image image, double cx, double cy, double outerR, img.Color color) {
  const points = 4;
  final innerR = outerR * 0.42;

  final vertices = <(double, double)>[];
  for (var i = 0; i < points * 2; i++) {
    final angle = (i * math.pi / points) - math.pi / 2;
    final r = i.isEven ? outerR : innerR;
    vertices.add((cx + r * math.cos(angle), cy + r * math.sin(angle)));
  }

  // Rasterise by scanning bounding box and testing point-in-polygon
  final minX = vertices.map((v) => v.$1).reduce(math.min).floor();
  final maxX = vertices.map((v) => v.$1).reduce(math.max).ceil();
  final minY = vertices.map((v) => v.$2).reduce(math.min).floor();
  final maxY = vertices.map((v) => v.$2).reduce(math.max).ceil();

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      if (_pointInPolygon(x.toDouble(), y.toDouble(), vertices)) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixelRgba(x, y, color.r.toInt(), color.g.toInt(), color.b.toInt(), 255);
        }
      }
    }
  }
}

bool _pointInPolygon(double px, double py, List<(double, double)> poly) {
  var inside = false;
  final n = poly.length;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final xi = poly[i].$1, yi = poly[i].$2;
    final xj = poly[j].$1, yj = poly[j].$2;
    if ((yi > py) != (yj > py) && px < (xj - xi) * (py - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}
