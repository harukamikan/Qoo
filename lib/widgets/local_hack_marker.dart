import 'package:flutter/material.dart';
import '../models/local_hack.dart';
import 'local_hack_dialog.dart';

class LocalHackMarker extends StatelessWidget {
  final LocalHack hack;
  final bool isVisible; // 追加: オン/オフを判定するフラグ

  const LocalHackMarker({
    super.key,
    required this.hack,
    this.isVisible = true, // デフォルトは表示（true）
  });

  @override
  Widget build(BuildContext context) {
    // オフ（false）のときは画面に何も出さない
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => LocalHackDialog.show(context, hack),
      child: const Text('💡', style: TextStyle(fontSize: 30)),
    );
  }
}