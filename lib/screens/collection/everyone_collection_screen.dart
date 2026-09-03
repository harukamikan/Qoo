import 'package:flutter/material.dart';
import '../../services/collection_service.dart';
import '../../services/user_repository.dart';

/// コレクション達成者みんなの投稿を、ユーザーごとの「シート」として並べる画面。
class EveryoneCollectionScreen extends StatefulWidget {
  final String collectionName;
  final List<String> spotIds;

  const EveryoneCollectionScreen({
    super.key,
    required this.collectionName,
    required this.spotIds,
  });

  @override
  State<EveryoneCollectionScreen> createState() =>
      _EveryoneCollectionScreenState();
}

class _UserSheet {
  final String name;
  final List<String> photos;
  _UserSheet(this.name, this.photos);
}

class _EveryoneCollectionScreenState extends State<EveryoneCollectionScreen> {
  List<_UserSheet> _sheets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final posts = await CollectionService.fetchAllPostsForSpots(widget.spotIds);
    final grouped = <String, List<String>>{};
    for (final post in posts) {
      final uid = post['userId'] as String? ?? 'unknown';
      final url = post['imageUrl'] as String?;
      if (url == null) continue;
      grouped.putIfAbsent(uid, () => []).add(url);
    }

    final sheets = <_UserSheet>[];
    for (final entry in grouped.entries) {
      String name = 'ある旅行者';
      try {
        final profile = await UserRepository.instance.fetchProfile(entry.key);
        if (profile != null && profile.name.isNotEmpty) {
          name = profile.name;
        }
      } catch (_) {}
      sheets.add(_UserSheet(name, entry.value));
    }

    if (!mounted) return;
    setState(() {
      _sheets = sheets;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E9),
      appBar: AppBar(
        title: Text('みんなの${widget.collectionName}'),
        backgroundColor: const Color(0xFFFDF6E9),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sheets.isEmpty
              ? const Center(child: Text('まだ投稿がありません'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sheets.length,
                  itemBuilder: (context, index) {
                    final sheet = _sheets[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            child: Text(
                              '${sheet.name}の${widget.collectionName}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: sheet.photos.length,
                            itemBuilder: (context, i) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(sheet.photos[i],
                                    fit: BoxFit.cover),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}