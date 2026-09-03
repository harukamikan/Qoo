import 'package:flutter/material.dart';
import '../../services/collection_service.dart';

/// コレクション達成者みんなの投稿写真を一覧表示する画面。
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

class _EveryoneCollectionScreenState extends State<EveryoneCollectionScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final posts = await CollectionService.fetchAllPostsForSpots(widget.spotIds);
    if (!mounted) return;
    setState(() {
      _posts = posts;
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
          : _posts.isEmpty
              ? const Center(child: Text('まだ投稿がありません'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _posts[index]['imageUrl'] as String?;
                    if (imageUrl == null) return const SizedBox();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    );
                  },
                ),
    );
  }
}