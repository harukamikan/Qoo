import 'dart:math';

import 'package:flutter/material.dart';

/// 実際の地図タイル（ネットワーク）の代わりに、道路・公園・街区を
/// 模した簡易マップを描画するCustomPainter。
class MapBackgroundPainter extends CustomPainter {
  final Color baseColor;

  MapBackgroundPainter({this.baseColor = const Color(0xFFE7E4DD)});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 緑地（公園）ブロック
    final parkPaint = Paint()..color = const Color(0xFFCBDDBB);
    final parkRects = [
      Rect.fromLTWH(size.width * 0.05, size.height * 0.10,
          size.width * 0.22, size.height * 0.12),
      Rect.fromLTWH(size.width * 0.62, size.height * 0.55,
          size.width * 0.30, size.height * 0.16),
      Rect.fromLTWH(size.width * 0.10, size.height * 0.68,
          size.width * 0.18, size.height * 0.10),
    ];
    for (final r in parkRects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(10)),
        parkPaint,
      );
    }

    // 主要道路（太line）
    final mainRoadPaint = Paint()
      ..color = const Color(0xFFF6F3EC)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    final mainRoadBorder = Paint()
      ..color = const Color(0xFFD8D2C4)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;

    final random = Random(7); // 固定シードで毎回同じ見た目に
    final horizontalYs = List.generate(
        5, (i) => size.height * (0.1 + i * 0.2) + random.nextDouble() * 10);
    for (final y in horizontalYs) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y + 6), mainRoadBorder);
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y + 6), mainRoadPaint);
    }
    final verticalXs = List.generate(
        4, (i) => size.width * (0.15 + i * 0.28) + random.nextDouble() * 10);
    for (final x in verticalXs) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + 4, size.height), mainRoadBorder);
      canvas.drawLine(
          Offset(x, 0), Offset(x + 4, size.height), mainRoadPaint);
    }

    // 細街路（薄い線）
    final smallRoadPaint = Paint()
      ..color = const Color(0xFFEDEAE1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 14; i++) {
      final y = random.nextDouble() * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), smallRoadPaint);
    }

    // 川（曲線）
    final riverPaint = Paint()
      ..color = const Color(0xFFBFD7E6)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.30,
          size.width * 0.45, size.height * 0.48)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.66,
          size.width, size.height * 0.5);
    canvas.drawPath(riverPath, riverPaint);
  }

  @override
  bool shouldRepaint(covariant MapBackgroundPainter oldDelegate) => false;
}
