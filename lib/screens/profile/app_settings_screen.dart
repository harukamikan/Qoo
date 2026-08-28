import 'package:flutter/material.dart';

import '../../state/app_data.dart';
import '../../theme/app_colors.dart';

/// プロフィール画面の「アプリ設定」から遷移する画面。
class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,
      builder: (context, _) {
        final data = AppData.instance;
        return Scaffold(
          appBar: AppBar(title: const Text('アプリ設定')),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: data.alertEnabled,
                    onChanged: (v) {
                      data.setAlertEnabled(v);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(v ? '100mアラートをオンにしました' : '100mアラートをオフにしました'),
                        ),
                      );
                    },
                    title: const Text(
                      '100mアラート',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('保存したスポットの100m以内に近づいたら通知します'),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('🔔 テスト通知：近くに保存済みスポットがあります')),
                    );
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('通知をテストする'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
