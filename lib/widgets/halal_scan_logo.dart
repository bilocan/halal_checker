import 'dart:math' as math;
import 'package:flutter/material.dart';

class HalalScanLogo extends StatelessWidget {
  final double size;
  final Color color;

  const HalalScanLogo({super.key, this.size = 80, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(color: color)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;

  const _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // --- Crescent moon ---
    // Outer circle fills the crescent body
    final outerRadius = w * 0.42;
    // Inner circle is offset right to carve out the crescent
    final innerRadius = w * 0.36;
    final innerOffsetX = w * 0.12;

    final crescentPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius));

    final cutPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(cx + innerOffsetX, cy - h * 0.02),
          radius: innerRadius,
        ),
      );

    final crescent = Path.combine(
      PathOperation.difference,
      crescentPath,
      cutPath,
    );

    // --- Barcode lines clipped to the crescent ---
    final lineCount = 9;
    final lineWidth = w * 0.028;
    final spacing = w * 0.062;
    final startX = cx - (lineCount / 2) * spacing;

    final barcodePath = Path();
    for (var i = 0; i < lineCount; i++) {
      // Vary heights for barcode feel
      final heightFactor = _barHeightFactor(i, lineCount);
      final lineH = outerRadius * 2 * heightFactor;
      final lx = startX + i * spacing;
      final ly = cy - lineH / 2;
      barcodePath.addRect(Rect.fromLTWH(lx, ly, lineWidth, lineH));
    }

    // Only draw lines inside the crescent
    final barcodeInCrescent = Path.combine(
      PathOperation.intersect,
      barcodePath,
      crescent,
    );

    // Draw crescent outline, then overwrite with background-colored bars
    canvas.drawPath(crescent, paint);

    // Use background-like color to "cut" lines through crescent
    // We layer: crescent (solid) → lines (transparent gap)
    final bgPaint = Paint()
      ..color = _darken(color, 0.55)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(barcodeInCrescent, bgPaint);

    // --- Small star / dot above crescent tip ---
    final starX = cx + outerRadius * 0.55;
    final starY = cy - outerRadius * 0.72;
    _drawStar(canvas, Offset(starX, starY), w * 0.055, paint);
  }

  double _barHeightFactor(int index, int total) {
    // Create a lens/arch shape: taller in the middle
    final mid = (total - 1) / 2;
    final t = 1 - ((index - mid).abs() / mid);
    return 0.55 + t * 0.38;
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 4;
    final outerR = radius;
    final innerR = radius * 0.42;
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}
