import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'store_approval_screen.dart';
import 'local_hack_form_screen.dart';

/// 運営用のメニュー画面。店舗承認とローカルルール投稿への入口をまとめる。
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('運営ページ')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoreApprovalScreen(),
                  ),
                ),
                icon: const Icon(Icons.storefront),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(56),
                ),
                label: const Text('店舗の承認'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocalHackFormScreen(),
                  ),
                ),
                icon: const Icon(Icons.lightbulb_outline),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(56),
                ),
                label: const Text('ローカルルールを投稿'),
              ),
            ],
          ),
        ),
      ),
    );
    
  }
}