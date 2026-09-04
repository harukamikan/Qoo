import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nearby_comment.dart';
import '../utils/geo_utils.dart';
import '../theme/app_colors.dart';
import '../services/translation_service.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';
import '../services/ui_translations.dart';

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
  bool hasTrashBin = false; // 「ここにゴミ箱がある」チェック
  bool hasToilet = false; // 「ここにトイレがある」チェック
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
            title: Row(
              children: [
                const Icon(Icons.edit_location_alt, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  UiTranslations.t('Tipsを投稿'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
                  Text(
                    UiTranslations.t('スポット名 / 場所の名前:'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: placeController,
                    decoration: InputDecoration(
                      hintText: UiTranslations.t('例: ○○公園、駅前カフェ'),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    UiTranslations.t('カテゴリ:'),
                    style: const TextStyle(
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
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(UiTranslations.t(cat)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    UiTranslations.t('Tips / アドバイス:'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: UiTranslations.t('旅行者へのおすすめポイントや注意点...'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    value: hasTrashBin,
                    onChanged: (checked) {
                      setDialogState(() => hasTrashBin = checked ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      '🗑️ ${UiTranslations.t('ここにゴミ箱がある')}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                    CheckboxListTile(
                    value: hasToilet,
                    onChanged: (checked) {
                      setDialogState(() => hasToilet = checked ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      '🚻 ${UiTranslations.t('ここにトイレがある')}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(UiTranslations.t('キャンセル')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (contentController.text.trim().isEmpty) return;

                  // ユーザー名をFirestoreから取得
                  final uid = AuthService.instance.uid;
                  String userName = 'Traveler';
                  if (uid != null) {
                    final profile =
                        await UserRepository.instance.fetchProfile(uid);
                    if (profile != null) userName = profile.name;
                  }

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

                  // ローカルの即時反映用（Firestoreのserver timestampが
                  // 確定するまでのつなぎとして、投稿した瞬間の時刻を使う）
                  final localCreatedAt = DateTime.now();

                  String newDocId = localCreatedAt.millisecondsSinceEpoch.toString();
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
                      'user_name': userName,
                      'user_country': '🇯🇵',
                      'helpful_count': 1,
                      'created_at': FieldValue.serverTimestamp(),
                    });
                    newDocId = ref.id;
                  } catch (e) {
                    debugPrint('Firebase save note: $e');
                  }

                  // 「ここにゴミ箱がある」がチェックされていれば、ついでに
                  // trash_bins コレクションにも登録する。失敗してもTips投稿
                  // 自体は継続する（トイレ🚻と同じくOSMのゴミ箱データが
                  // 日本だと少ないため、ユーザー投稿で補う）。
                  if (hasTrashBin) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('trash_bins')
                          .add({
                        'latitude': targetPosition.latitude,
                        'longitude': targetPosition.longitude,
                        'userId': uid ?? '',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } catch (e) {
                      debugPrint('trash_bins save error: $e');
                    }
                  }
                                    if (hasToilet) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('toilets')
                          .add({
                        'latitude': targetPosition.latitude,
                        'longitude': targetPosition.longitude,
                        'userId': uid ?? '',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } catch (e) {
                      debugPrint('toilets save error: $e');
                    }
                  }

                  final newTip = NearbyComment(
                    id: newDocId,
                    placeName: placeName,
                    category: selectedCategory,
                    content: originalContent,
                    userName: userName,
                    userCountry: '🇯🇵',
                    helpfulCount: 1,
                    position: targetPosition,
                    distanceMeters: distanceMeters(
                      currentCenter,
                      targetPosition,
                    ),
                    translations: translations,
                    originalLang: originalLang,
                    createdAt: localCreatedAt, // ← サーバー確定前の仮の投稿日時
                  );

                  onPosted(newTip);

                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('「$placeName」にTipsを追加しました！')),
                  );
                },
                child: Text(UiTranslations.t('投稿する')),
              ),
            ],
          );
        },
      );
    },
  );
}
