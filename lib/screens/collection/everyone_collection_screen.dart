import 'package:flutter/material.dart';
import '../../models/travel_collection.dart';
import '../../models/collection_spot.dart';
import '../../services/collection_service.dart';
import '../../services/user_repository.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';

/// コレクション達成者みんなの投稿を、コレクション（テーマ）別に、
/// ユーザーごとの「シート」として並べる画面。
class EveryoneCollectionScreen extends StatefulWidget {
  final String collectionName;
  final List<String> spotIds;
  final Map<String, String> spotNames;

  const EveryoneCollectionScreen({
    super.key,
    required this.collectionName,
    required this.spotIds,
    this.spotNames = const {},
  });

  @override
  State<EveryoneCollectionScreen> createState() =>
      _EveryoneCollectionScreenState();
}

class _Photo {
  final String url;
  final String spotName;
  _Photo(this.url, this.spotName);
}

class _UserSheet {
  final String ownerUid;
  final String name;
  final List<_Photo> photos;
  _UserSheet(this.ownerUid,this.name, this.photos);
}

class _EveryoneCollectionScreenState extends State<EveryoneCollectionScreen> {
  List<TravelCollection> _collections = [];
  TravelCollection? _selected;
  List<_UserSheet> _sheets = [];
    // sheetKey ("ownerUid_collectionId") -> いいねしたuidのセット
  Map<String, Set<String>> _sheetLikes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final collections = await CollectionService.fetchCollections();
    if (!mounted) return;
    setState(() => _collections = collections);
    if (collections.isNotEmpty) {
      _selectCollection(collections.first);
    } else {
      setState(() => _loading = false);
    }
  }
  

  Future<void> _selectCollection(TravelCollection collection) async {
    setState(() {
      _selected = collection;
      _loading = true;
    });
      

    // そのコレクションのスポット（id -> 名前）
    final spots = await CollectionService.fetchSpots(collection.id);
    final spotNames = {for (final CollectionSpot s in spots) s.id: s.name};
    final spotIds = spots.map((s) => s.id).toList();

    final posts = await CollectionService.fetchAllPostsForSpots(spotIds);
    final grouped = <String, List<_Photo>>{};
    for (final post in posts) {
      final uid = post['userId'] as String? ?? 'unknown';
      final url = post['imageUrl'] as String?;
      if (url == null) continue;
      final spotId = post['spotId'] as String? ?? '';
      final spotName = spotNames[spotId] ?? '';
      grouped.putIfAbsent(uid, () => []).add(_Photo(url, spotName));
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
      sheets.add(_UserSheet(entry.key,name, entry.value));
    }
    
    // 各シートのいいねを取得
    final likes = <String, Set<String>>{};
    for (final sheet in sheets) {
      final key = '${sheet.ownerUid}_${_selected!.id}';
      likes[key] = await CollectionService.fetchSheetLikers(
        sheet.ownerUid,
        _selected!.id,
      );
    }

    if (!mounted) return;
    setState(() {
      _sheets = sheets;
      _sheetLikes = likes;
      _loading = false;
    });
  }
  
  Future<void> _toggleLike(String ownerUid, bool currentlyLiked) async {
    final myUid = AuthService.instance.uid;
    if (myUid == null || _selected == null) return;
    final collectionId = _selected!.id;
    final key = '${ownerUid}_$collectionId';

    setState(() {
      final set = _sheetLikes[key] ?? <String>{};
      if (currentlyLiked) {
        set.remove(myUid);
      } else {
        set.add(myUid);
      }
      _sheetLikes[key] = set;
    });

    try {
      if (currentlyLiked) {
        await CollectionService.removeSheetLike(
          sheetOwnerUid: ownerUid,
          collectionId: collectionId,
          likerUid: myUid,
        );
      } else {
        await CollectionService.addSheetLike(
          sheetOwnerUid: ownerUid,
          collectionId: collectionId,
          likerUid: myUid,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E9),
      appBar: AppBar(
        title: const Text('みんなのコレクション'),
        backgroundColor: const Color(0xFFFDF6E9),
        elevation: 0,
      ),
      body: Column(
        children: [
          // コレクション切り替えチップ
          if (_collections.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _collections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final c = _collections[index];
                  final selected = c.id == _selected?.id;
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textGrey,
                    ),
                    onSelected: (_) => _selectCollection(c),
                  );
                },
              ),
            ),
          Expanded(
            child: _loading
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${sheet.name}の${_selected?.name ?? ''}',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                      Builder(builder: (context) {
                                        final key =
                                            '${sheet.ownerUid}_${_selected?.id ?? ''}';
                                        final likers = _sheetLikes[key] ?? {};
                                        final myUid = AuthService.instance.uid;
                                        final liked =
                                            myUid != null && likers.contains(myUid);
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                liked
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: liked
                                                    ? Colors.redAccent
                                                    : Colors.grey,
                                              ),
                                              onPressed: () =>
                                                  _toggleLike(sheet.ownerUid, liked),
                                            ),
                                            Text('${likers.length}'),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemCount: sheet.photos.length,
                                  itemBuilder: (context, i) {
                                    final photo = sheet.photos[i];
                                    return Column(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(photo.url,
                                                fit: BoxFit.cover,
                                                width: double.infinity),
                                          ),
                                        ),
                                        if (photo.spotName.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              photo.spotName,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
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