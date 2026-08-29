import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../models/nearby_comment.dart';
import '../theme/app_colors.dart';
import 'post_tips_dialog.dart';
import 'report_dialog.dart';

/// 同一スポットのTips一覧モーダルを表示する。
///
/// 地図画面（_MapPageState）が持つ状態や処理は、すべて引数・コールバックとして
/// 受け取る。これにより、モーダルのUIをこのファイルに閉じ込めつつ、
/// 実際のデータ操作（削除・Helpful・追加投稿）は地図画面側に残す。
void showLocationTipsModal(
  BuildContext context, {
  required List<NearbyComment> commentsInLoc,
  required ll.LatLng currentCenter,
  // 現在の_nearbyComments全体を返す関数（モーダルは最新の一覧を都度取得する）
  required List<NearbyComment> Function() getAllComments,
  required String Function(ll.LatLng) toLocationKey,
  required Color Function(String) getCategoryColor,
  required bool Function(String) isHelpfulByMe,
  // 削除処理。sheetCtxとsetModalStateを渡して、モーダル側の再描画・閉じるを制御させる
  required void Function(
    NearbyComment comment,
    BuildContext sheetCtx,
    void Function(void Function()) setModalState,
  ) onDeleteTip,
  // Helpfulトグル。onLocalUpdateでモーダル側の再描画を行う
  required void Function(NearbyComment c, {VoidCallback? onLocalUpdate})
      onToggleHelpful,
  // 追加投稿された新Tipsを地図画面側に反映するコールバック
  required void Function(NearbyComment newTip) onPosted,
}) {
  final targetSpot = commentsInLoc.first;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final currentList = getAllComments()
              .where(
                (item) =>
                    toLocationKey(item.position) ==
                    toLocationKey(targetSpot.position),
              )
              .toList();
          currentList.sort(
            (a, b) => b.helpfulCount.compareTo(a.helpfulCount),
          );

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.place,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      targetSpot.placeName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navy,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Tips一覧 (${currentList.length}件) • 約${targetSpot.distanceMeters.toStringAsFixed(0)}m',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text(
                            '追加投稿',
                            style: TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            showPostTipsDialog(
                              context,
                              targetPosition: targetSpot.position,
                              currentCenter: currentCenter,
                              initialPlaceName: targetSpot.placeName,
                              onPosted: onPosted,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: currentList.length,
                      itemBuilder: (context, index) {
                        final c = currentList[index];
                        final catColor = getCategoryColor(c.category);
                        final isMyTip = c.userName == 'You';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.userCountry,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          c.userName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isMyTip
                                                ? AppColors.primary
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (isMyTip) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryFaint,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            child: const Text(
                                              '自分',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (index == 0 &&
                                            currentList.length > 1) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '👑 最多',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.brown,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        c.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: catColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  c.content,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (isMyTip)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'この投稿を削除',
                                        onPressed: () => onDeleteTip(
                                          c,
                                          sheetCtx,
                                          setModalState,
                                        ),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(
                                          Icons.flag_outlined,
                                          size: 18,
                                          color: AppColors.textGrey,
                                        ),
                                        tooltip: 'この投稿を通報',
                                        onPressed: () => showReportDialog(
                                          context,
                                          title: c.placeName,
                                        ),
                                      ),
                                    Builder(
                                      builder: (context) {
                                        final isHelpful = isHelpfulByMe(c.id);
                                        return InkWell(
                                          onTap: () {
                                            onToggleHelpful(
                                              c,
                                              onLocalUpdate: () {
                                                setModalState(() {});
                                                currentList.sort(
                                                  (a, b) => b.helpfulCount
                                                      .compareTo(
                                                          a.helpfulCount),
                                                );
                                              },
                                            );
                                          },
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isHelpful
                                                  ? AppColors.primary
                                                      .withOpacity(0.28)
                                                  : AppColors.primary
                                                      .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: isHelpful
                                                  ? Border.all(
                                                      color: AppColors.primary,
                                                      width: 1,
                                                    )
                                                  : null,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isHelpful
                                                      ? Icons
                                                          .thumb_up_alt_rounded
                                                      : Icons
                                                          .thumb_up_alt_outlined,
                                                  size: 14,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Helpful (${c.helpfulCount})',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
