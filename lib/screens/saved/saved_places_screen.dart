import 'package:flutter/material.dart';

import '../../state/app_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/saved_place_card.dart';
import '../review_detail/review_detail_screen.dart';

/// 画像1に対応する「保存した場所」画面。
/// タブから開く場合は showBackButton=false、
/// プロフィールなどから個別に開く場合は true にする。
class SavedPlacesScreen extends StatefulWidget {
  final bool showBackButton;

  const SavedPlacesScreen({super.key, this.showBackButton = false});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  String _selectedCategory = 'すべて';

  static const _categories = ['すべて', 'グルメ', '文化', '温泉'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,
      builder: (context, _) {
        final places =
            AppData.instance.savedPlacesByCategory(_selectedCategory);

        return Scaffold(
          appBar: AppBar(
            leading: widget.showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            automaticallyImplyLeading: widget.showBackButton,
            title: const Text('保存した場所'),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return CategoryChip(
                          label: cat,
                          selected: cat == _selectedCategory,
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: places.isEmpty
                      ? _EmptyState(category: _selectedCategory)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: places.length,
                          itemBuilder: (context, index) {
                            final place = places[index];
                            return SavedPlaceCard(
                              place: place,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReviewDetailScreen(
                                      placeId: place.id,
                                    ),
                                  ),
                                );
                              },
                              onToggleSaved: () {
                                AppData.instance.toggleSaved(place.id);
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${place.name}を保存リストから削除しました',
                                      ),
                                    ),
                                  );
                              },
                            );
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
}

class _EmptyState extends StatelessWidget {
  final String category;

  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border,
                size: 56, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Text(
              '「$category」に保存されたスポットはまだありません',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
