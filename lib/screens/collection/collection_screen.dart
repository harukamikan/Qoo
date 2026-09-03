import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/travel_collection.dart';
import '../../models/collection_spot.dart';
import '../../services/collection_service.dart';
import '../../services/photo_upload_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'package:latlong2/latlong.dart' as ll;

/// 地域コレクション画面。コレクション一覧、スポット一覧、達成状況、写真投稿を1画面で扱う。
class TravelCollectionScreen extends StatefulWidget {
  const TravelCollectionScreen({super.key});

  @override
  State<TravelCollectionScreen> createState() => _TravelCollectionScreenState();
}

class _TravelCollectionScreenState extends State<TravelCollectionScreen> {
  List<TravelCollection> _collections = [];
  TravelCollection? _selectedCollection;
  List<CollectionSpot> _spots = [];
  Set<String> _postedSpotIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
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
        ? await CollectionService.fetchMyPostedSpotIds(uid)
        : <String>{};
    if (!mounted) return;
    setState(() {
      _spots = spots;
      _postedSpotIds = posted;
      _loading = false;
    });
  }

  Future<void> _postPhoto(CollectionSpot spot) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('アップロード中...')),
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
        const SnackBar(content: Text('アップロードに失敗しました')),
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
      const SnackBar(content: Text('達成しました！')),
    );
    if (_selectedCollection != null) {
      _selectCollection(_selectedCollection!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('地域コレクション')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _collections.isEmpty
              ? const Center(child: Text('コレクションがまだありません'))
              : Column(
                  children: [
                    if (_selectedCollection != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCollection!.name,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedCollection!.description,
                              style: const TextStyle(color: AppColors.textGrey),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _spots.isEmpty
                                  ? 0
                                  : _postedSpotIds.length / _spots.length,
                              backgroundColor: Colors.grey.shade200,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_postedSpotIds.length} / ${_spots.length} 達成',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _spots.length,
                        itemBuilder: (context, index) {
                          final spot = _spots[index];
                          final done = _postedSpotIds.contains(spot.id);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(
                                done ? Icons.check_circle : Icons.circle_outlined,
                                color: done ? AppColors.primary : Colors.grey,
                                size: 32,
                              ),
                              title: Text(spot.name),
                              subtitle: Text(spot.description),
                              trailing: done
                                  ? const Icon(Icons.photo, color: AppColors.primary)
                                  : IconButton(
                                      icon: const Icon(Icons.camera_alt),
                                      onPressed: () => _postPhoto(spot),
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
