import 'package:flutter/material.dart';

/// 地図上に固定表示される吹き出し型のコメントバブル。
/// [pointerAlignment] で吹き出しの三角形（しっぽ）の位置を指定する。
class CommentBubble extends StatelessWidget {
  final Widget child;
  final Color background;
  final Color borderColor;
  final Alignment pointerAlignment;
  final VoidCallback? onTap;

  const CommentBubble({
    super.key,
    required this.child,
    required this.background,
    required this.borderColor,
    this.pointerAlignment = Alignment.bottomCenter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBottomPointer = pointerAlignment.y > 0;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor, width: 2.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: child,
    );

    final pointer = CustomPaint(
      size: const Size(18, 10),
      painter: _TrianglePainter(color: background, borderColor: borderColor),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: pointerAlignment.x < 0
              ? CrossAxisAlignment.start
              : (pointerAlignment.x > 0
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.center),
          children: isBottomPointer
              ? [bubble, Transform.translate(offset: const Offset(0, -1), child: pointer)]
              : [Transform.translate(offset: const Offset(0, 1), child: Transform.rotate(angle: 3.14159, child: pointer)), bubble],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5 - 9, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.5 + 9, 0)
      ..close();

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()..color = color;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => false;
}
