import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// ガチャタブの画面。
/// コインを使ってリアクション絵文字のガチャを引ける機能（担当：別メンバー）。
/// TODO: ガチャ演出・排出ロジック・コイン消費処理を実装する
class GachaScreen extends StatelessWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ガチャ'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.casino_outlined,
              size: 80,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'ガチャ機能は準備中です',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'コインを使ってリアクション絵文字をゲットしよう',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 32),
            // TODO: 所持コイン数を表示（コイン機能担当と連携）
            ElevatedButton(
              onPressed: null, // TODO: ガチャを引く処理を実装
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('ガチャを引く（準備中）'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
