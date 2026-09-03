import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../models/travel_photo.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';
import '../theme/app_colors.dart';

enum FriendPhotoFeedFilter { mineOnly, friendsOnly, both }

class FriendPhotoFeedScreen extends StatefulWidget {
  const FriendPhotoFeedScreen({super.key});

  @override
  State<FriendPhotoFeedScreen> createState() => _FriendPhotoFeedScreenState();
}

class _FriendPhotoFeedScreenState extends State<FriendPhotoFeedScreen> {
  FriendPhotoFeedFilter _filter = FriendPhotoFeedFilter.both;
  bool _loading = true;
  String? _error;
  List<TravelPhoto> _photos = [];
  Map<String, UserProfile> _profilesById = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await UserRepository.instance.fetchProfile(uid);
      final friendIds = profile?.friends.toSet() ?? <String>{};
      final snapshot =
          await FirebaseFirestore.instance.collection('travel_photos').get();

      final photos = <TravelPhoto>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        final imageUrl = data['imageUrl'] as String?;
        final ownerId = data['userId'] as String? ?? '';
        final visibility = data['visibility'] as String? ?? 'friends';
        final createdAtRaw = data['createdAt'];
        final createdAt = createdAtRaw is Timestamp
            ? createdAtRaw.toDate()
            : createdAtRaw as DateTime?;

        if (lat == null || lng == null || imageUrl == null || ownerId.isEmpty) {
          continue;
        }

        final isMine = ownerId == uid;
        final isFriend = friendIds.contains(ownerId);
        final matchesFilter = switch (_filter) {
          FriendPhotoFeedFilter.mineOnly => isMine,
          FriendPhotoFeedFilter.friendsOnly => isFriend,
          FriendPhotoFeedFilter.both => isMine || isFriend,
        };

        if (!matchesFilter) continue;

        photos.add(
          TravelPhoto(
            id: doc.id,
            imageUrl: imageUrl,
            position: ll.LatLng(lat, lng),
            userId: ownerId,
            visibility: visibility,
            createdAt: createdAt,
            distanceMeters: 0,
          ),
        );
      }

      photos.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      final ownerIds = photos.map((photo) => photo.userId).toSet();
      final fetchedProfiles =
          await UserRepository.instance.fetchProfilesByUids(ownerIds);

      if (!mounted) return;
      setState(() {
        _photos = photos;
        _profilesById = {
          for (final profile in fetchedProfiles) profile.userId: profile,
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '写真を読み込めませんでした';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
  // 画像のデザインに合わせたカラー定義
  const primaryCoral = Color(0xFFE85A3C); // テーマアクセント（コーラルオレンジ）
  const bgLightPink = Color(0xFFFAF5F8);  // ほんのりピンクがかった明るい背景色
  const subTextColor = Color(0xFF757575);  // サブテキストのグレー

  return Scaffold(
    backgroundColor: bgLightPink,
    appBar: AppBar(
      title: const Text('友達の写真'),
      backgroundColor: bgLightPink,
      elevation: 0,
    ),
    body: RefreshIndicator(
      color: primaryCoral,
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text(
            '公開された写真を友達・自分の範囲で見られます',
            style: TextStyle(color: subTextColor),
          ),
          const SizedBox(height: 12),
          SegmentedButton<FriendPhotoFeedFilter>(
          style: SegmentedButton.styleFrom(
          selectedBackgroundColor: primaryCoral,
          selectedForegroundColor: Colors.white,
          ),
            segments: const [
              ButtonSegment(
                value: FriendPhotoFeedFilter.mineOnly,
                label: Text('自分'),
                icon: Icon(Icons.person),
              ),
              ButtonSegment(
                value: FriendPhotoFeedFilter.friendsOnly,
                label: Text('友達'),
                icon: Icon(Icons.group),
              ),
              ButtonSegment(
                value: FriendPhotoFeedFilter.both,
                label: Text('両方'),
                icon: Icon(Icons.people),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (selection) {
              setState(() => _filter = selection.first);
              _reload();
            },
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: CircularProgressIndicator(color: primaryCoral),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(child: Text(_error!)),
            )
          else if (_photos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Text(
                  '写真がまだありません',
                  style: TextStyle(color: subTextColor),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                final ownerName =
                    _profilesById[photo.userId]?.name ?? 'Traveler';
                return _buildPhotoTile(photo, ownerName);
              },
            ),
        ],
      ),
    ),
  );
}

// ポラロイド風の写真タイルウィジェット
Widget _buildPhotoTile(TravelPhoto photo, String ownerName) {
  return GestureDetector(
    onTap: () => _showPhotoDetail(photo),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // ソフトなシャドウ
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ownerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A4A4A),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

  void _showPhotoDetail(TravelPhoto photo) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(dialogContext),
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 3.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
