import 'package:flutter/material.dart';
import '../../models/place.dart';
import '../gacha/gacha_item.dart';
import '../../state/app_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/category_chip.dart';
import '../review_detail/review_detail_screen.dart';
import '../gacha/inventory_manager.dart';
import 'comment_bubble.dart';
import 'map_painter.dart';

/// 画像3に対応する「地図」画面（ボトムナビの初期タブ）。
class MapScreen extends StatefulWidget {
  final void Function(int tabIndex) onSwitchTab;

  const MapScreen({super.key, required this.onSwitchTab});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedFilter = 'すべて';
  final _searchController = TextEditingController();

  static const _filters = ['すべて', '食事', '温泉', '文化', '交通'];

  // 地図フィルターのラベル → Placeカテゴリー名 の対応
  static const _filterToCategory = {
    '食事': 'グルメ',
    '温泉': '温泉',
    '文化': '文化',
    '交通': '交通',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _bubbleVisible(String placeCategory) {
    if (_selectedFilter == 'すべて') return true;
    return _filterToCategory[_selectedFilter] == placeCategory;
  }

  void _openDetail(String placeId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReviewDetailScreen(placeId: placeId)),
    );
  }

  void _runSearch(String query) {
    if (query.trim().isEmpty) return;
    final results = AppData.instance.searchPlaces(query);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '「$query」の検索結果',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('該当するスポットが見つかりませんでした',
                        style: TextStyle(color: AppColors.textGrey)),
                  )
                else
                  ...results.map(
                    (p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(p.photoIcon, color: AppColors.primary),
                      title: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${p.category} • ${p.locationLabel}'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _openDetail(p.id);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNearbyReviewsTeaser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('近くの旅行者の口コミ'),
        content: const Text(
          'あなたの近くで新しい口コミが投稿されました。地図上の吹き出しをタップすると詳細を確認できます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showCommentSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('人気の口コミ'),
        content:
            const Text('このエリアには合計9,999件の口コミが投稿されています。カテゴリーを絞り込んで探してみましょう。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 装備中マーカースキンのバッジをコメント吹き出しの右上に重ねて表示する
  Widget _decorateWithMarkerSkin(Widget bubble, GachaItem? markerSkin) {
    if (markerSkin == null) return bubble;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: markerSkin.rarity.color, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Text(markerSkin.iconOrAsset, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  /// 装備中アバタースキンを使った「現在地」マーカー
  Widget _buildSelfAvatarMarker(GachaItem? avatarSkin) {
    final ringColor = avatarSkin != null ? avatarSkin.rarity.color : AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: ringColor, width: 3),
            boxShadow: [
              BoxShadow(color: ringColor.withValues(alpha: 0.5), blurRadius: 12),
            ],
          ),
          child: Center(
            child: Text(
              avatarSkin?.iconOrAsset ?? '📍',
              style: const TextStyle(fontSize: 26),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '現在地',
            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryData = InventoryProvider.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([AppData.instance, inventoryData]),
      builder: (context, _) {
        final p1 = AppData.instance.places.firstWhere(
          (p) => p.id == 'p1',
          orElse: () => AppData.instance.places.isNotEmpty
              ? AppData.instance.places.first
              : Place(
                  id: 'p1',
                  name: '一楽ラーメン',
                  category: 'グルメ',
                  quote: '',
                  rating: 4.8,
                  ratingCount: 100,
                  locationLabel: '福岡',
                  footerLabel: '4.8',
                  footerIconKey: 'star',
                  photoIconKey: 'ramen',
                  gradientColors: const [0xFF5A3320, 0xFFB5651D],
                  isSaved: true,
                  lat: 33.5902,
                  lng: 130.4017,
                ),
        );
        final p2 = AppData.instance.places.firstWhere(
          (p) => p.id == 'p2',
          orElse: () => AppData.instance.places.isNotEmpty
              ? AppData.instance.places.first
              : Place(
                  id: 'p2',
                  name: '東京タワー',
                  category: '文化',
                  quote: '',
                  rating: 4.6,
                  ratingCount: 100,
                  locationLabel: '東京',
                  footerLabel: '',
                  footerIconKey: '',
                  photoIconKey: 'city',
                  gradientColors: const [0xFF0D1B4C, 0xFF3A4A9A],
                  isSaved: true,
                  lat: 35.6586,
                  lng: 139.7454,
                ),
        );
        final p5 = AppData.instance.places.firstWhere(
          (p) => p.id == 'p5',
          orElse: () => AppData.instance.places.isNotEmpty
              ? AppData.instance.places.first
              : Place(
                  id: 'p5',
                  name: '新宿駅 東口',
                  category: '交通',
                  quote: '',
                  rating: 2.1,
                  ratingCount: 50,
                  locationLabel: '東京',
                  footerLabel: '',
                  footerIconKey: '',
                  photoIconKey: 'train',
                  gradientColors: const [0xFF555555, 0xFF8A8A8A],
                  isSaved: false,
                  lat: 35.6896,
                  lng: 139.7006,
                ),
        );

        final markerSkin = inventoryData.getEquippedItem(GachaItemType.markerSkin);
        final avatarSkin = inventoryData.getEquippedItem(GachaItemType.avatarSkin);

        return Scaffold(
          body: Stack(
            children: [
              // ---- 背景マップ ----
              Positioned.fill(
                child: CustomPaint(painter: MapBackgroundPainter()),
              ),

              // ---- 吹き出し群 ----
              if (_bubbleVisible('グルメ'))
                Positioned(
                  left: 20,
                  top: 300,
                  child: _decorateWithMarkerSkin(
                    CommentBubble(
                      background: AppColors.primary,
                      borderColor: Colors.black.withValues(alpha: 0.85),
                      onTap: () => _openDetail(p1.id),
                      child: const _BubbleContent(
                        text: 'いいね！このご飯は',
                        icon: Icons.restaurant,
                        textColor: Colors.white,
                      ),
                    ),
                    markerSkin,
                  ),
                ),
              if (_bubbleVisible('文化'))
                Positioned(
                  right: 16,
                  top: 380,
                  child: _decorateWithMarkerSkin(
                    CommentBubble(
                      background: AppColors.navy,
                      borderColor: Colors.black.withValues(alpha: 0.85),
                      onTap: () => _openDetail(p2.id),
                      child: const _BubbleContent(
                        text: 'すごい！歴史を感じる',
                        icon: Icons.account_balance,
                        textColor: Colors.white,
                      ),
                    ),
                    markerSkin,
                  ),
                ),
              Positioned(
                right: 40,
                top: 190,
                child: CommentBubble(
                  background: AppColors.navy,
                  borderColor: Colors.black.withValues(alpha: 0.85),
                  onTap: _showCommentSummary,
                  child: const _BubbleContent(
                    title: 'コメント',
                    text: '9999個',
                    textColor: Colors.white,
                    big: true,
                  ),
                ),
              ),
              if (_bubbleVisible('交通'))
                Positioned(
                  left: 30,
                  top: 520,
                  child: _decorateWithMarkerSkin(
                    CommentBubble(
                      background: AppColors.primary,
                      borderColor: Colors.black.withValues(alpha: 0.85),
                      onTap: () => _openDetail(p5.id),
                      child: const _BubbleContent(
                        text: 'ムリ',
                        icon: Icons.tram,
                        textColor: Colors.white,
                      ),
                    ),
                    markerSkin,
                  ),
                ),

              // ---- 自分の現在地アバター ----
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - 28,
                top: 440,
                child: _buildSelfAvatarMarker(avatarSkin),
              ),

              // ---- 上部UI（検索バー・フィルター・通知バナー） ----
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.menu, color: AppColors.navy),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onSubmitted: _runSearch,
                                decoration: const InputDecoration(
                                  hintText: '目的地を検索...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => widget.onSwitchTab(4),
                              borderRadius: BorderRadius.circular(30),
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: AppColors.primaryLight,
                                child: avatarSkin != null
                                    ? Text(avatarSkin.iconOrAsset,
                                        style: const TextStyle(fontSize: 16))
                                    : const Icon(Icons.person,
                                        color: AppColors.primary, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final f = _filters[index];
                            return CategoryChip(
                              label: f,
                              selected: f == _selectedFilter,
                              onTap: () => setState(() => _selectedFilter = f),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: _showNearbyReviewsTeaser,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Text('🔔', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '近くの旅行者の口コミが見つかりました！',
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---- 右下フローティングボタン ----
              Positioned(
                right: 18,
                bottom: 90,
                child: FloatingActionButton(
                  heroTag: 'locate',
                  mini: true,
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.navy,
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('現在地に移動しました')),
                      );
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
              Positioned(
                right: 18,
                bottom: 20,
                child: FloatingActionButton(
                  heroTag: 'addReview',
                  backgroundColor: AppColors.primary,
                  onPressed: () => widget.onSwitchTab(2),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BubbleContent extends StatelessWidget {
  final String text;
  final String? title;
  final IconData? icon;
  final Color textColor;
  final bool big;

  const _BubbleContent({
    required this.text,
    this.title,
    this.icon,
    required this.textColor,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        if (icon != null) Icon(icon, color: textColor, size: 20),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: big ? 22 : 14,
          ),
        ),
      ],
    );
  }
}
