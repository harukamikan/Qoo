import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String query, String selectedCategory) onSearchChanged;

  const SearchBarWidget({
    super.key,
    required this.onSearchChanged,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'すべて';

  // 仕様書に合わせたカテゴリ一覧
  final List<String> _categories = [
    'すべて',
    '観光',
    'グルメ',
    'ショッピング',
    'トラブル・注意',
    'その他',
  ];

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
              hintText: 'キーワードやスポット名で検索...',
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
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
          const SizedBox(height: 8),

          // カテゴリ切り替えチップ（横スクロール）
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _notifyParent();
                      }
                    },
                    selectedColor: Colors.blue.shade100,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}