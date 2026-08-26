import 'package:flutter/material.dart';

import '../../models/place.dart';
import '../../state/app_data.dart';
import '../../theme/app_colors.dart';
import '../review_detail/review_detail_screen.dart';

/// 「検索」タブ。スポット名・カテゴリー・地域名で絞り込み検索ができる。
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,
      builder: (context, _) {
        final results = _query.isEmpty
            ? AppData.instance.places
            : AppData.instance.searchPlaces(_query);

        return Scaffold(
          appBar: AppBar(title: const Text('スポットを検索')),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.navy),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (v) => setState(() => _query = v),
                            decoration: const InputDecoration(
                              hintText: 'スポット名・地域・カテゴリーで検索',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(Icons.close,
                                color: AppColors.textGrey, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: results.isEmpty
                      ? const Center(
                          child: Text(
                            '該当するスポットが見つかりませんでした',
                            style: TextStyle(color: AppColors.textGrey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _SearchResultTile(place: results[index]);
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

class _SearchResultTile extends StatelessWidget {
  final Place place;

  const _SearchResultTile({required this.place});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReviewDetailScreen(placeId: place.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: place.gradient),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(place.photoIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${place.category} • ${place.locationLabel}',
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Icon(
                place.isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
