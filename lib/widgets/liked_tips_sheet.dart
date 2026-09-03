import 'package:flutter/material.dart';
import '../models/review.dart'; // 既存のモデルクラスをインポート

class LikedTipsSheet extends StatelessWidget {
  // 本来はFirestore等から「自分がいいねしたTips」の一覧を取得して渡します
  final List<Review> likedTips;
  final Function(String id)? onDelete;

  const LikedTipsSheet({
    Key? key,
    required this.likedTips,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6, // 最初表示される高さ（画面の60%）
      minChildSize: 0.3, // 最小高さ
      maxChildSize: 0.9, // 最大高さ
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0F3), // 薄いピンクの背景
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ヘッダータイトル
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    // 掴みバー（グレーの横線）
                    SizedBox(
                      width: 40,
                      height: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'あなたが👍をしたTips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Tipsカード一覧
              Expanded(
                child: likedTips.isEmpty
                    ? const Center(child: Text('まだいいねしたTipsはありません'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: likedTips.length,
                        itemBuilder: (context, index) {
                          final tip = likedTips[index];
                          return _buildTipCard(context, tip);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // カードUIのコンポーネント
  Widget _buildTipCard(BuildContext context, Review tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上段：ユーザータグ & カテゴリタグ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.pinkAccent,
                      child: Icon(Icons.person, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'You',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '自分',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
                // カテゴリタグ（Manners, Food など）
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    tip.category ?? 'General',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 本文
            Text(
              tip.content ?? '',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            // 下段：ゴミ箱（自分のみ）& いいね数
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    if (onDelete != null) onDelete!(tip.id);
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.thumb_up, size: 14, color: Colors.redAccent),
                      SizedBox(width: 4),
                      Text(
                        '1', // エラー回避のため仮表示（Reviewモデルの定義に合わせて適宜調整可能）
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}