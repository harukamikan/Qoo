import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_hack.dart';
import '../state/liked_tips_provider.dart';

class LikedTipsBottomSheet extends ConsumerWidget {
  const LikedTipsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedTipsAsync = ref.watch(likedTipsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF0F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Image.asset(
                'assets/images/jam_jar.png',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Text('🫙', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 8),
              const Text(
                'いいねしたTips（JAM瓶）',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: likedTipsAsync.when(
              data: (tips) {
                if (tips.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'まだ「いいね」したTipsはありません',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: tips.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tip = tips[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        tip.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // description がない場合に対応できるよう toString または title を代替表示
                      subtitle: Text(
                        tip.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.pink),
                        onPressed: () {
                          ref.read(likedTipsProvider.notifier).toggleLike(tip);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('エラーが発生しました: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}