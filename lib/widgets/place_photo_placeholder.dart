import 'package:flutter/material.dart';

/// ネットワーク画像の代わりに、スポットのイメージカラーとアイコンで
/// 「写真」を表現するプレースホルダー。
class PlacePhotoPlaceholder extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final double height;
  final BorderRadius? borderRadius;

  const PlacePhotoPlaceholder({
    super.key,
    required this.gradient,
    required this.icon,
    this.height = 180,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: height * 0.4,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
