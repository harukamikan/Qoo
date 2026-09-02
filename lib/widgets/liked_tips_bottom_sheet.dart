// liked_tips_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 以下のパスは実際のプロジェクト構造に合わせて調整してください
import '../models/local_hack.dart'; // Tip または LocalHack のモデル
import '../state/liked_tips_provider.dart';

class LikedTipsBottomSheet extends ConsumerWidget {
  const LikedTipsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedTipsAsync = ref.watch(likedTipsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF0F5), // 淡いピンク背景
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上部のドラッグハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // ヘッダータイトル
          const Text(
            'あなたが 👍 をしたTips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // リスト表示エリア
          Expanded(
            child: likedTipsAsync.when(
              data: (tips) {
                if (tips.isEmpty) {
                  return const Center(child: Text('まだいいねしたTipsはありません'));
                }
                return ListView.builder(
                  itemCount: tips.length,
                  itemBuilder: (context, index) {
                    final tip = tips[index];
                    // カード形式のリスト表示（既存のCardコンポーネントがあればそちらに置換してください）
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(tip.title),
                        subtitle: Text(tip.description),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('エラーが発生しました: $err')),
            ),
          ),
        ],
      ),
    );
  }
}