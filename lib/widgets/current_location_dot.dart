import 'package:flutter/material.dart';
import '../screens/gacha/gacha_item.dart';

/// 地図上に表示する現在地マーカー。
/// 装備中のマーカースキン（またはアバタースキン）がある場合はそのスキンアイコンを表示し、
/// 未装備の場合はデフォルトの青い丸ドットを表示する。
class CurrentLocationDot extends StatelessWidget {
  final GachaItem? skin;

  const CurrentLocationDot({super.key, this.skin});

  @override
  Widget build(BuildContext context) {
    if (skin != null) {
      final ringColor = skin!.rarity.color;
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: ringColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: ringColor.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            skin!.iconOrAsset,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}
