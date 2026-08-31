import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../state/app_data.dart';
import '../../theme/app_colors.dart';

/// 画像5に対応する「口コミを作成」画面。
/// [initialPlaceId] を渡すと、そのスポットに対する口コミとして投稿される。
class CreateReviewScreen extends StatefulWidget {
  final String? initialPlaceId;

  const CreateReviewScreen({super.key, this.initialPlaceId});

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  static const _categories = ['食事', '温泉', '文化', '交通'];
  static const _categoryToPlaceCategory = {
    '食事': 'グルメ',
    '温泉': '温泉',
    '文化': '文化',
    '交通': '交通',
  };

  final _textController = TextEditingController();
  final List<String> _photos = [];
  String _selectedCategory = '食事';
  String _locationLabel = '現在地付近';
  String? _boundPlaceId;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
    if (widget.initialPlaceId != null) {
      final place = AppData.instance.placeById(widget.initialPlaceId!);
      _boundPlaceId = place.id;
      _locationLabel = '${place.name}付近';
      final matchedCategory = _categoryToPlaceCategory.entries
          .firstWhere(
            (e) => e.value == place.category,
            orElse: () => const MapEntry('食事', 'グルメ'),
          )
          .key;
      _selectedCategory = matchedCategory;
    } else {
      _locationLabel = '東京タワー付近';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _editLocation() async {
    final controller = TextEditingController(text: _locationLabel);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('位置を編集'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例：渋谷スクランブル交差点付近'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _locationLabel = result);
    }
  }

  void _addPhoto() {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真は最大5枚まで追加できます')),
      );
      return;
    }
    setState(() {
      _photos.add('photo_${_photos.length + 1}');
    });
  }

  void _removePhoto(String id) {
    setState(() => _photos.remove(id));
  }

  void _appendEmoji(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    final insertAt = selection.start >= 0 ? selection.start : text.length;
    final newText = text.replaceRange(insertAt, insertAt, emoji);
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertAt + emoji.length),
    );
  }

  void _showEmojiPicker() {
    const emojis = ['😋', '😍', '👍', '🎉', '☕', '🍜', '♨️', '🗼'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: emojis
                .map(
                  (e) => InkWell(
                    onTap: () {
                      _appendEmoji(e);
                      Navigator.of(context).pop();
                    },
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('口コミの内容を入力してください')),
      );
      return;
    }

    // 位置が既存スポットに紐づいていない場合は、新規スポットとして
    // 検索・保存できるよう最も近いカテゴリーのプレースホルダーIDを使う。
    final placeId = _boundPlaceId ?? _fallbackPlaceIdForCategory();

    final review = Review(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      placeId: placeId,
      userName: 'あなた',
      userTag: 'JP',
      avatarColor: 0xFFE8552E,
      stars: _draftStars,
      comment: _textController.text.trim(),
      timeAgo: 'たった今',
      helpfulCount: 0,
      photoCount: _photos.length,
      isMine: true,
      createdAt: DateTime.now(),
    );

    AppData.instance.addReview(review);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('口コミを投稿しました')),
    );
    Navigator.of(context).pop(true);
  }

  int _draftStars = 5;

  String _fallbackPlaceIdForCategory() {
    final targetCategory = _categoryToPlaceCategory[_selectedCategory];
    final match = AppData.instance.places.firstWhere(
      (p) => p.category == targetCategory,
      orElse: () => AppData.instance.places.first,
    );
    return match.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '口コミを作成',
          style: TextStyle(color: AppColors.primary),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ---- 検出位置カード ----
            InkWell(
              onTap: _editLocation,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '自動検出された位置',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 12.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locationLabel,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '編集',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),

            // ---- カテゴリー ----
            const Text(
              'カテゴリー',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((c) {
                final selected = c == _selectedCategory;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = c),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.chipInactiveBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconForCategory(c),
                          size: 18,
                          color: selected ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),

            // ---- 評価（星） ----
            const Text(
              '評価',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                final filled = i < _draftStars;
                return InkWell(
                  onTap: () => setState(() => _draftStars = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 26),

            // ---- 口コミ本文 ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'あなたの口コミ',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${_textController.text.length} / 500',
                  style:
                      const TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    maxLength: 500,
                    maxLines: 6,
                    minLines: 5,
                    decoration: const InputDecoration(
                      hintText: '体験をシェアしましょう...',
                      counterText: '',
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('AI文章提案は準備中です')),
                                );
                              },
                              child: const Icon(Icons.autorenew,
                                  size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: _showEmojiPicker,
                              child: const Icon(Icons.emoji_emotions_outlined,
                                  size: 18, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ---- 写真追加 ----
            if (_photos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _photos
                      .map(
                        (id) => Stack(
                          children: [
                            Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.image,
                                  color: AppColors.primary),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: InkWell(
                                onTap: () => _removePhoto(id),
                                child: const CircleAvatar(
                                  radius: 11,
                                  backgroundColor: AppColors.navy,
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            InkWell(
              onTap: _addPhoto,
              borderRadius: BorderRadius.circular(18),
              child: DottedBorderBox(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_photo_alternate,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '写真を追加',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '最大5枚まで',
                      style:
                          TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ---- 投稿ボタン ----
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send),
                label: const Text('口コミを投稿'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case '食事':
        return Icons.restaurant;
      case '温泉':
        return Icons.hot_tub;
      case '文化':
        return Icons.account_balance;
      case '交通':
        return Icons.directions_transit;
      default:
        return Icons.place;
    }
  }
}

/// 破線風の枠を持つボックス（写真追加エリア用）
class DottedBorderBox extends StatelessWidget {
  final Widget child;

  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );

    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
