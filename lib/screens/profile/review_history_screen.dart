import 'package:flutter/material.dart';

import '../../state/app_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/review_card.dart';
import '../review_detail/review_detail_screen.dart';

/// プロフィール画面の「レビュー履歴」から遷移する画面。
/// 自分（isMine）が投稿した口コミの一覧を表示・削除できる。
class ReviewHistoryScreen extends StatelessWidget {
  const ReviewHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,
      builder: (context, _) {
        final myReviews = AppData.instance.myReviews;

        return Scaffold(
          appBar: AppBar(title: const Text('レビュー履歴')),
          body: SafeArea(
            top: false,
            child: myReviews.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'まだ口コミを投稿していません。\n地図画面の「＋」ボタンから投稿してみましょう。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: myReviews.length,
                    itemBuilder: (context, index) {
                      final review = myReviews[index];
                      final place = AppData.instance.placeById(review.placeId);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReviewDetailScreen(placeId: place.id),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                place.name,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          ReviewCard(
                            review: review,
                            onHelpfulTap: () =>
                                AppData.instance.incrementHelpful(review.id),
                            onMoreTap: () {},
                            onDeleteTap: () {
                              AppData.instance.removeReview(review.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('口コミを削除しました')),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
