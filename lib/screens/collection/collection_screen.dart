import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/travel_collection.dart';
import '../../models/collection_spot.dart';
import '../../services/collection_service.dart';
import '../../services/photo_upload_service.dart';
import '../../services/auth_service.dart';
import '../../services/ui_translations.dart';
import '../../theme/app_colors.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../models/store.dart';
import '../../services/store_repository.dart';
import 'everyone_collection_screen.dart';

/// 地域コレクション画面。グリッド型のご当地図鑑スタイルで表示する。
class TravelCollectionScreen extends StatefulWidget {
  const TravelCollectionScreen({super.key});

  @override
  State<TravelCollectionScreen> createState() => _TravelCollectionScreenState();
}

class _TravelCollectionScreenState extends State<TravelCollectionScreen>
    with SingleTickerProviderStateMixin {
  List<TravelCollection> _collections = [];
  TravelCollection? _selectedCollection;
  List<CollectionSpot> _spots = [];
  Map<String, String> _postedPhotos = {};
  List<Store> _approvedStores = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCollections();
    _loadApprovedStores();
  }
  
  /// 承認済みお店をカテゴリごとにまとめる。各カテゴリ最大6件。
  Map<String, List<Store>> get _storesByCategory {
    final map = <String, List<Store>>{};
    for (final store in _approvedStores) {
      final cat = store.category.isEmpty ? 'その他' : store.category;
      map.putIfAbsent(cat, () => []);
      if (map[cat]!.length < 6) {
        map[cat]!.add(store);
      }
    }
    return map;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovedStores() async {
    final stores = await StoreRepository.instance.fetchApprovedStores();
    if (!mounted) return;
    setState(() => _approvedStores = stores);
  }

  Future<void> _loadCollections() async {
    setState(() => _loading = true);
    final collections = await CollectionService.fetchCollections();
    if (!mounted) return;
    setState(() {
      _collections = collections;
      _loading = false;
    });
    if (collections.isNotEmpty) {
      _selectCollection(collections.first);
    }
  }

  Future<void> _selectCollection(TravelCollection collection) async {
    setState(() {
      _selectedCollection = collection;
      _loading = true;
    });
    final spots = await CollectionService.fetchSpots(collection.id);
    final uid = AuthService.instance.uid;
    final posted = uid != null
        ? await CollectionService.fetchMyPostedPhotos(uid)
        : <String, String>{};
    if (!mounted) return;
    setState(() {
      _spots = spots;
      _postedPhotos = posted;
      _loading = false;
    });
  }

  Future<void> _postPhoto(CollectionSpot spot) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(UiTranslations.t('アップロード中...'))),
    );

    final imageUrl = await PhotoUploadService.uploadAndSave(
      bytes: await photo.readAsBytes(),
      filename: photo.name,
      position: ll.LatLng(spot.latitude, spot.longitude),
      visibility: 'public',
    );

    if (imageUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UiTranslations.t('アップロードに失敗しました'))),
      );
      return;
    }

    final uid = AuthService.instance.uid;
    if (uid != null) {
      await CollectionService.postToSpot(
        spotId: spot.id,
        userId: uid,
        imageUrl: imageUrl,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(UiTranslations.t('達成しました！'))),
    );
    if (_selectedCollection != null) {
      _selectCollection(_selectedCollection!);
    }
  }

  Future<void> _postPhotoForStore(Store store) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(UiTranslations.t('アップロード中...'))),
    );

    final imageUrl = await PhotoUploadService.uploadAndSave(
      bytes: await photo.readAsBytes(),
      filename: photo.name,
      position: ll.LatLng(store.latitude, store.longitude),
      visibility: 'public',
    );

    if (imageUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UiTranslations.t('アップロードに失敗しました'))),
      );
      return;
    }

    final uid = AuthService.instance.uid;
    if (uid != null) {
      await CollectionService.postToSpot(
        spotId: store.id,
        userId: uid,
        imageUrl: imageUrl,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(UiTranslations.t('達成しました！'))),
    );
    _loadApprovedStores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E9),
      appBar: AppBar(
        title: Text(UiTranslations.t('ご当地コレクション')),
        backgroundColor: const Color(0xFFFDF6E9),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: UiTranslations.t('マイコレクション')),
            Tab(text: UiTranslations.t('みんなのコレクション')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _collections.isEmpty
                  ? Center(child: Text(UiTranslations.t('コレクションがまだありません')))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
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
                            if (_selectedCollection != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedCollection!.name,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedCollection!.description,
                                      style: const TextStyle(
                                          color: AppColors.textGrey,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: _spots.isEmpty
                                            ? 0
                                            : _postedPhotos.length /
                                                _spots.length,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade200,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_postedPhotos.length} / ${_spots.length} ${UiTranslations.t('達成')}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                              itemCount: _spots.length,
                              itemBuilder: (context, index) {
                                final spot = _spots[index];
                                final photoUrl = _postedPhotos[spot.id];
                                final done = photoUrl != null;
                                return GestureDetector(
                                  onTap: done ? null : () => _postPhoto(spot),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF3E3),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFFE5D9BF)),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(10)),
                                            child: done
                                                ? Image.network(photoUrl,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity)
                                                : Center(
                                                    child: Icon(
                                                      Icons.camera_alt_outlined,
                                                      color:
                                                          Colors.grey.shade400,
                                                      size: 28,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 4),
                                          child: Text(
                                            spot.name,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                                                    if (_approvedStores.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                UiTranslations.t('お店コレクション'),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              for (final entry in _storesByCategory.entries) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${entry.key}巡り',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
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
                                  itemCount: entry.value.length,
                                  itemBuilder: (context, index) {
                                    final store = entry.value[index];
                                    return GestureDetector(
                                      onTap: () => _postPhotoForStore(store),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAF3E3),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                              color: const Color(0xFFE5D9BF)),
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: Icon(
                                                  Icons.storefront,
                                                  color: Colors.grey.shade400,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 6, horizontal: 4),
                                              child: Text(
                                                store.name,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
          EveryoneCollectionScreen(
            collectionName: _selectedCollection?.name ?? '',
            spotIds: _spots.map((s) => s.id).toList(),
          ),
        ],
      ),
    );
  }
}
