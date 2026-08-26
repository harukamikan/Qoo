import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 1〜5個の塗り星を表示する（口コミ詳細カードなどで使用）。
class StarRow extends StatelessWidget {
  final int stars;
  final double size;

  const StarRow({super.key, required this.stars, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < stars ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: AppColors.star,
        );
      }),
    );
  }
}
