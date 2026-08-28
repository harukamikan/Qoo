import 'package:flutter/material.dart';

class SavedSpotsScreen extends StatefulWidget {
  const SavedSpotsScreen({super.key});

  @override
  State<SavedSpotsScreen> createState() => _SavedSpotsScreenState();
}

class _SavedSpotsScreenState extends State<SavedSpotsScreen> {
  // ダミーの保存済みスポットデータリスト
  final List<Map<String, String>> _savedSpots = [
    {
      'place_name': 'キャナルシティ博多',
      'category': 'ショッピング',
      'content': '噴水ショーが綺麗でした！周辺にショップも多いです。',
    },
    {
      'place_name': '太宰府天満宮',
      'category': '観光',
      'content': '参道の梅ヶ枝餅が美味しかった。休日で人は多め。',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('保存したスポット・口コミ'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _savedSpots.isEmpty
          ? const Center(
              child: Text(
                '保存されたスポットはありません',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _savedSpots.length,
              itemBuilder: (context, index) {
                final spot = _savedSpots[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        spot['category'] == 'ショッピング'
                            ? Icons.shopping_bag
                            : Icons.place,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    title: Text(
                      spot['place_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            spot['category'] ?? '',
                            style: const TextStyle(fontSize: 10),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        Text(
                          spot['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_remove,
                          color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _savedSpots.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('保存を解除しました')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
