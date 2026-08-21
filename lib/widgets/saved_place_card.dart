import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme/app_colors.dart';
import 'place_photo_placeholder.dart';

/// 「保存した場所」画面に並ぶカード。
/// タップで詳細画面へ、ブックマークアイコンタップで保存解除。
class SavedPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  const SavedPlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlacePhotoPlaceholder(
              gradient: place.gradient,
              icon: place.photoIcon,
              height: 180,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          place.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onToggleSaved,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            place.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '「${place.quote}」',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(place.footerIcon,
                          size: 16, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        place.footerLabel,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•',
                          style: TextStyle(color: AppColors.textGrey)),
                      const SizedBox(width: 8),
                      Text(
                        place.locationLabel,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
