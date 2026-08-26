import 'dart:ui';

import 'package:flutter/material.dart';

import '../../state/app_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/review_card.dart';
import '../../widgets/star_row.dart';
import '../map/map_painter.dart';

/// 画像4に対応する「口コミ詳細」画面。
/// 背景にぼかした地図、手前に口コミ一覧のシートを重ねて表示する。
class ReviewDetailScreen extends StatelessWidget {
  final String placeId;

  const ReviewDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,
      builder: (context, _) {
        final place = AppData.instance.placeById(placeId);
        final reviews = AppData.instance.reviewsForPlace(placeId);

        return Scaffold(
          backgroundColor: AppColors.navy,
          body: Stack(
            children: [
              // ---- ぼかした地図背景 ----
              Positioned.fill(
                child: CustomPaint(painter: MapBackgroundPainter()),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black.withValues(alpha: 0.15)),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _RoundIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),

              // ---- レビュー一覧シート ----
              DraggableScrollableSheet(
                initialChildSize: 0.68,
                minChildSize: 0.4,
                maxChildSize: 0.92,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 14, 20, 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        StarRow(
                                          stars: place.rating.round(),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${place.rating.toStringAsFixed(1)} (${_formatCount(place.ratingCount)}件)',
                                          style: const TextStyle(
                                            color: AppColors.textGrey,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  AppData.instance.toggleSaved(place.id);
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          place.isSaved
                                              ? '${place.name}を保存しました'
                                              : '${place.name}の保存を解除しました',
                                        ),
                                      ),
                                    );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    place.isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: AppColors.primary,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: reviews.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'まだ口コミがありません。最初の口コミを投稿してみましょう。',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppColors.textGrey),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 16, 20, 24),
                                  itemCount: reviews.length,
                                  itemBuilder: (context, index) {
                                    final review = reviews[index];
                                    return ReviewCard(
                                      review: review,
                                      onHelpfulTap: () => AppData.instance
                                          .incrementHelpful(review.id),
                                      onMoreTap: () =>
                                          _showMoreSheet(context, review.id),
                                      onDeleteTap: review.isMine
                                          ? () {
                                              AppData.instance
                                                  .removeReview(review.id);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text('口コミを削除しました'),
                                                ),
                                              );
                                            }
                                          : null,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreSheet(BuildContext context, String reviewId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('この口コミを報告する'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('報告を受け付けました')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('共有する'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('共有リンクをコピーしました')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
    }
    return count.toString();
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.navy),
        ),
      ),
    );
  }
}
