import 'package:flutter/material.dart';

/// 地図上に表示する現在地マーカー（青い丸）。
class CurrentLocationDot extends StatelessWidget {
  const CurrentLocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}