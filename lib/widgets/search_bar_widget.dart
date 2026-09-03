import 'package:flutter/material.dart';
import '../services/ui_translations.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String query, String selectedCategory) onSearchChanged;
  final bool showCategoryChips;

  const SearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.showCategoryChips = true,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  // 表示ラベル(日本語) と 内部値(英語・Firestoreのcategoryと一致) の対応表。
  // Firestoreのcommentsコレクションのcategoryフィールドと合わせてある。
  static const Map<String, String> _categoryLabels = {
    'All': 'すべて',
    'Food': 'グルメ',
    'Onsen': '温泉',
    'Culture': '文化',
    'Transportation': '交通',
    'Manners': 'マナー',
    'Money': 'お金',
    'Other': 'その他',
  };

  String _selectedCategory = 'All'; // 内部値で保持する
  void _notifyParent() {
    widget.onSearchChanged(_searchController.text, _selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // キーワード検索バー
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: UiTranslations.t('キーワードやスポット名で検索...'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _notifyParent();
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (value) => _notifyParent(),
          ),
          if (widget.showCategoryChips) ...[
            const SizedBox(height: 8),

            // カテゴリ切り替えチップ（横スクロール）
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categoryLabels.length,
                itemBuilder: (context, index) {
                  final entry = _categoryLabels.entries.elementAt(index);
                  final categoryValue = entry.key;
                  final categoryLabel = entry.value;
                  final isSelected = categoryValue == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(UiTranslations.t(categoryLabel)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = categoryValue;
                          });
                          _notifyParent();
                        }
                      },
                      selectedColor: Colors.blue.shade100,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.blue.shade900 : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
