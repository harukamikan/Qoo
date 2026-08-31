import 'package:flutter/material.dart';

import '../models/review.dart';
import '../theme/app_colors.dart';
import 'star_row.dart';

/// 口コミ1件分のカード。長文コメントは「続きを読む」で開閉できる。
class ReviewCard extends StatefulWidget {
  final Review review;
  final VoidCallback onHelpfulTap;
  final VoidCallback onMoreTap;
  final VoidCallback? onDeleteTap;

  const ReviewCard({
    super.key,
    required this.review,
    required this.onHelpfulTap,
    required this.onMoreTap,
    this.onDeleteTap,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _expanded = false;
  bool _helpfulTapped = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(review.avatarColor),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName.substring(0, 1)
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.userName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _CountryTag(code: review.userTag),
                        if (review.isMine) ...[
                          const SizedBox(width: 6),
                          const _MineTag(),
                        ],
                      ],
                    ),
                    Text(
                      review.timeAgo,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onMoreTap,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.more_horiz, color: AppColors.textGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StarRow(stars: review.stars, size: 18),
          const SizedBox(height: 8),
          Text(
            review.comment,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
          if (review.comment.length > 60)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? '閉じる' : '続きを読む',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _helpfulTapped
                    ? null
                    : () {
                        setState(() => _helpfulTapped = true);
                        widget.onHelpfulTap();
                      },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _helpfulTapped
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 18,
                        color: _helpfulTapped
                            ? AppColors.primary
                            : AppColors.textGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${review.helpfulCount}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _helpfulTapped
                              ? AppColors.primary
                              : AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (review.photoCount > 0) ...[
                const SizedBox(width: 16),
                const Icon(Icons.photo_camera_outlined,
                    size: 17, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(
                  '(${review.photoCount})',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              ],
              const Spacer(),
              if (widget.onDeleteTap != null)
                InkWell(
                  onTap: widget.onDeleteTap,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline,
                        size: 19, color: AppColors.textGrey),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountryTag extends StatelessWidget {
  final String code;

  const _CountryTag({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textGrey.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}

class _MineTag extends StatelessWidget {
  const _MineTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '自分',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
