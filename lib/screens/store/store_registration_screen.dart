import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

/// 店舗登録フロー（店名 → 地図で位置指定 → 電話番号 → 登録）の入り口。
///
/// 現時点ではスタブ。フォーム本体は Step 4 で実装する。
/// [AuthGate] は「ログイン済み・店舗ロール選択・stores/{uid} 未登録」の状態で
/// この画面を表示する。
class StoreRegistrationScreen extends StatelessWidget {
  const StoreRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('店舗登録')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 56),
              const SizedBox(height: 16),
              const Text(
                '店舗登録フォームは準備中です',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => AuthService.instance.signOut(),
                child: const Text('ログアウト'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
