import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../admin/admin_home_screen.dart';

/// ログイン前に「観光客として使うか」「お店として登録するか」を選ぶ画面。
/// 選択結果は [AuthService.pendingRole] に保持され、[AuthGate] が
/// 次に見せる画面（ログイン画面 → オンボーディング/店舗登録）を判定する。
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.travel_explore, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Jam',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'どちらとして利用しますか？',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () =>
                    AuthService.instance.chooseRole(UserRole.tourist),
                icon: const Icon(Icons.travel_explore),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('観光客として利用する'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    AuthService.instance.chooseRole(UserRole.store),
                icon: const Icon(Icons.storefront),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('お店を登録する'),
                ),
              ),
                            const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminHomeScreen(),
                  ),
                ),
                icon: const Icon(Icons.admin_panel_settings, size: 18),
                label: const Text('運営ページ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
