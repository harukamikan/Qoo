import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nearby_comment.dart';
import '../utils/geo_utils.dart';
import '../theme/app_colors.dart';
import '../services/translation_service.dart';

/// Tips投稿ダイアログを表示する。
///
/// 投稿が成功したら [onPosted] に、作成された [NearbyComment] を渡して返す。
/// 地図画面側はそれを受け取って自分の状態（_nearbyComments など）を更新する。
/// こうすることで、ダイアログのUIをこのファイルに閉じ込めつつ、
/// 地図の状態管理は地図画面側に残せる。
void showPostTipsDialog(
  BuildContext context, {
  required ll.LatLng targetPosition,
  required ll.LatLng currentCenter,
  String? initialPlaceName,
  required void Function(NearbyComment newTip) onPosted,
}) {
  final placeController = TextEditingController(text: initialPlaceName ?? '');
  final contentController = TextEditingController();
  String selectedCategory = 'Food';
  final categories = [
    'Food',
    'Onsen',
    'Culture',
    'Transportation',
    'Manners',
    'Money',
    'Other',
  ];

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit_location_alt, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Tipsを投稿',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 座標: ${targetPosition.latitude.toStringAsFixed(4)}, ${targetPosition.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'スポット名 / 場所の名前:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: placeController,
                    decoration: const InputDecoration(
                      hintText: '例: ○○公園、駅前カフェ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'カテゴリ:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tips / アドバイス:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '旅行者へのおすすめポイントや注意点...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (contentController.text.trim().isEmpty) return;

                  final placeName = placeController.text.trim().isEmpty
                      ? 'おすすめスポット'
                      : placeController.text.trim();

                  final originalContent = contentController.text.trim();
                  const originalLang = 'ja'; // TODO: 投稿者の言語をUserProfileから取得する

                  // 投稿内容を全言語に翻訳
                  Map<String, String> translations = {};
                  try {
                    translations = await TranslationService.instance
                        .translateToAllLanguages(
                      text: originalContent,
                      originalLang: originalLang,
                    );
                  } catch (e) {
                    debugPrint('Translation error: $e');
                    translations = {originalLang: originalContent};
                  }

                  String newDocId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  try {
                    final ref = await FirebaseFirestore.instance
                        .collection('comments')
                        .add({
                      'place_name': placeName,
                      'category': selectedCategory,
                      'content': originalContent,
                      'original_lang': originalLang,
                      'translations': translations,
                      'latitude': targetPosition.latitude,
                      'longitude': targetPosition.longitude,
                      'user_name': 'You',
                      'user_country': '🇯🇵',
                      'helpful_count': 1,
                      'created_at': FieldValue.serverTimestamp(),
                    });
                    newDocId = ref.id;
                  } catch (e) {
                    debugPrint('Firebase save note: $e');
                  }

                  final newTip = NearbyComment(
                    id: newDocId,
                    placeName: placeName,
                    category: selectedCategory,
                    content: originalContent,
                    userName: 'You',
                    userCountry: '🇯🇵',
                    helpfulCount: 1,
                    position: targetPosition,
                    distanceMeters: distanceMeters(
                      currentCenter,
                      targetPosition,
                    ),
                    translations: translations,
                    originalLang: originalLang,
                  );

                  onPosted(newTip);

                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('「$placeName」にTipsを追加しました！')),
                  );
                },
                child: const Text('投稿する'),
              ),
            ],
          );
        },
      );
    },
  );
}
