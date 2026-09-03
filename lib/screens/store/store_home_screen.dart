import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

/// 登録済み店舗オーナー向けのホーム画面。
///
/// 現時点ではスタブ。店舗コメント・Local Hackの編集UIは今後の別ステップで実装する。
/// [AuthGate] は「ログイン済み・stores/{uid} 登録済み」の状態でこの画面を表示する。
class StoreHomeScreen extends StatelessWidget {
  const StoreHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('店舗管理')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 56),
              const SizedBox(height: 16),
              const Text(
                '店舗管理画面は準備中です',
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
