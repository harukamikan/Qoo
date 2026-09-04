import 'package:flutter/material.dart';
import '../models/nearby_comment.dart';
import '../theme/app_colors.dart';
import '../screens/gacha/gacha_item.dart';
import '../services/ui_translations.dart';
import '../services/translation_service.dart';
import '../state/app_data.dart';

class GroupedBubbleMarker extends StatelessWidget {
  final List<NearbyComment> comments;
  final String locKey;
  final int carouselIndex;
  final Color Function(String) getCategoryColor;
  final VoidCallback onTap;
  final bool Function(String) isHelpfulByMe;
  final void Function(NearbyComment) onHelpfulTap;
  final GachaItem? markerSkin;

  const GroupedBubbleMarker({
    super.key,
    required this.comments,
    required this.locKey,
    required this.carouselIndex,
    required this.getCategoryColor,
    required this.onTap,
    required this.isHelpfulByMe,
    required this.onHelpfulTap,
    this.markerSkin,
  });

  @override
  Widget build(BuildContext context) {
    final activeIndex = comments.isEmpty ? 0 : carouselIndex % comments.length;
    final activeComment = comments[activeIndex];
    final categoryColor = getCategoryColor(activeComment.category);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 195,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Column(
                key: ValueKey<String>(activeComment.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              activeComment.userCountry,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activeComment.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (comments.length > 1)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${activeIndex + 1}/${comments.length} 🔄',
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          UiTranslations.t(activeComment.category),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activeComment.contentFor(
                      TranslationService.toLanguageCode(
                        AppData.instance.language,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.black87,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                activeComment.placeName,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ' • ${activeComment.relativeTime}',
                              style: TextStyle(
                                fontSize: 8.5,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => onHelpfulTap(activeComment),
                            child: Row(
                              children: [
                                Icon(
                                  isHelpfulByMe(activeComment.id)
                                      ? Icons.thumb_up_alt_rounded
                                      : Icons.thumb_up_alt_outlined,
                                  size: 10,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${activeComment.helpfulCount}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${UiTranslations.t('一覧')}>',
                            style: const TextStyle(
                                fontSize: 8, color: AppColors.navy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: const Size(12, 6),
            painter: TrianglePainter(color: Colors.white),
          ),
          const SizedBox(height: 1),
          if (markerSkin != null)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: markerSkin!.rarity.color, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 3)
                ],
              ),
              child: Text(markerSkin!.iconOrAsset,
                  style: const TextStyle(fontSize: 16)),
            )
          else
            Icon(Icons.place, color: categoryColor, size: 26),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  static final Paint shadowPaint = Paint()
    ..color = Colors.black12
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
