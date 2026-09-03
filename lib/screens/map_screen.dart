import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/nearby_alert_service.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';
import '../services/ui_translations.dart';
import '../utils/geo_utils.dart';
import '../theme/app_colors.dart';
import '../widgets/search_bar_widget.dart';
import '../models/nearby_comment.dart';
import '../models/travel_photo.dart';
import '../widgets/current_location_dot.dart';
import '../widgets/grouped_bubble_marker.dart';
//import '../widgets/report_dialog.dart';
import '../widgets/post_tips_dialog.dart';
import '../widgets/location_tips_modal.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_upload_service.dart';
import '../widgets/photo_capture_sheet.dart';
import '../screens/gacha/coin_manager.dart';
import '../screens/gacha/inventory_manager.dart';
import '../screens/gacha/gacha_item.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/local_hack.dart';
import '../widgets/local_hack_marker.dart';
import '../services/local_hack_service.dart';
import '../services/osm_amenity_service.dart';

/// 現在地からこの半径（メートル）以内の投稿だけを表示する。
const double nearbyRadiusMeters = 1000;

final ll.LatLng fukuokaFallback = ll.LatLng(33.5902, 130.4017);

/// 現在地取得がなぜうまくいかなかったかを表す。成功時は none。
enum LocationIssue {
  none,
  serviceDisabled, // 端末の位置情報サービス自体がオフ
  permissionDenied, // 今回拒否された（次回また聞ける）
  permissionDeniedForever, // 完全拒否（設定から手動で有効にするしかない）
}

enum MapPhotoFilter {
  publicOnly,
  friendsOnly,
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  ll.LatLng _currentCenter = fukuokaFallback;
  List<NearbyComment> _nearbyComments = [];
  List<LocalHack> _localHacks = [];
  List<TravelPhoto> _nearbyPhotos = [];
  UserProfile? _currentProfile;
  bool _isLoading = true;
  final _alertService = NearbyAlertService();
  LocationIssue _locationIssue = LocationIssue.none;
  String? _commentsError;
  MapPhotoFilter _photoFilter = MapPhotoFilter.publicOnly;

  String _selectedCategoryFilter = 'All';
  String _searchKeyword = '';
  // --- 地図モード（Tips表示 / 写真表示の切り替え） ---
  bool _isPhotoMode = false; // false = Tips(💬)モード, true = 写真(📷)モード
  bool _showAmenities = false;
List<Amenity> _amenities = [];

  final List<String> _categoryFilterList = [
    'All',
    'Food',
    'Onsen',
    'Culture',
    'Transportation',
    'Manners',
    'Money',
    'Other',
  ];

  final Map<String, int> _carouselIndices = {};
  Timer? _carouselTimer;

  static const String _helpfulPrefsKey = 'helpful_marked_comment_ids';
  Set<String> _myHelpfulIds = {};

  Future<void> _loadMyHelpfulIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_helpfulPrefsKey) ?? [];
    if (!mounted) return;
    setState(() {
      _myHelpfulIds = list.toSet();
    });
  }

  Future<void> _saveMyHelpfulIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_helpfulPrefsKey, _myHelpfulIds.toList());
  }

  bool _isHelpfulByMe(String commentId) => _myHelpfulIds.contains(commentId);

  void _toggleHelpful(NearbyComment c, {VoidCallback? onLocalUpdate}) {
    final wasHelpful = _myHelpfulIds.contains(c.id);
    setState(() {
      if (wasHelpful) {
        c.helpfulCount = c.helpfulCount > 0 ? c.helpfulCount - 1 : 0;
        _myHelpfulIds.remove(c.id);
      } else {
        c.helpfulCount++;
        _myHelpfulIds.add(c.id);
      }
    });
    onLocalUpdate?.call();
    _saveMyHelpfulIds();
    FirebaseFirestore.instance
        .collection('comments')
        .doc(c.id)
        .update({'helpful_count': c.helpfulCount}).catchError((_) {});
  }

  /// Tips投稿成功時にコインを加算して通知を出す共通処理
  void _handleTipPosted(NearbyComment newTip) {
    setState(() {
      _nearbyComments.insert(0, newTip);
      _carouselIndices[_toLocationKey(newTip.position)] = 0;
    });

    // コインを30加算
    CoinDataProvider.of(context).addCoins(30);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tipsを投稿しました！ +30コイン獲得🎉'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadEverything();
    _loadMyHelpfulIds();
    _startCarouselTimer();
    _alertService.start();
    _localHacks = LocalHackService.initialHacks;
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      setState(() {
        final grouped = _getGroupedComments();
        for (final entry in grouped.entries) {
          if (entry.value.length > 1) {
            final cur = _carouselIndices[entry.key] ?? 0;
            _carouselIndices[entry.key] = (cur + 1) % entry.value.length;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _alertService.stop();
    super.dispose();
  }

  String _toLocationKey(ll.LatLng pos) =>
      '${pos.latitude.toStringAsFixed(4)},${pos.longitude.toStringAsFixed(4)}';

  Map<String, List<NearbyComment>> _getGroupedComments() {
    final Map<String, List<NearbyComment>> map = {};
    final keyword = _searchKeyword.trim().toLowerCase();
    for (final c in _nearbyComments) {
      if (_selectedCategoryFilter != 'All' &&
          c.category != _selectedCategoryFilter) {
        continue;
      }
      if (keyword.isNotEmpty) {
        final matchesPlaceName = c.placeName.toLowerCase().contains(keyword);
        final matchesContent = c.content.toLowerCase().contains(keyword);
        if (!matchesPlaceName && !matchesContent) {
          continue;
        }
      }
      final key = _toLocationKey(c.position);
      map.putIfAbsent(key, () => []).add(c);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
    }
    return map;
  }

  Future<void> _loadEverything() async {
    setState(() {
      _isLoading = true;
      _commentsError = null;
    });

    ll.LatLng center = fukuokaFallback;
    LocationIssue locationIssue = LocationIssue.none;
    UserProfile? profile;
    try {
      final uid = AuthService.instance.uid;
      if (uid != null) {
        profile = await UserRepository.instance.fetchProfile(uid);
      }

      final result = await _getCurrentPosition().timeout(
        const Duration(seconds: 10),
        onTimeout: () => (position: null, issue: LocationIssue.serviceDisabled),
      );
      if (result.position != null) {
        center = result.position!;
      }
      locationIssue = result.issue;
    } catch (_) {}

    List<NearbyComment> comments = [];
    String? commentsError;
    try {
      comments = await _fetchNearbyComments(
        center,
      ).timeout(const Duration(milliseconds: 2500), onTimeout: () => []);
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
      commentsError = '投稿データを取得できませんでした。右下のボタンで再読み込みしてください。';
    }
    List<TravelPhoto> photos = [];
    try {
      photos = await _fetchNearbyPhotos(
        center,
        currentUserId: AuthService.instance.uid,
        friendIds: profile?.friends.toSet() ?? const {},
        filter: _photoFilter,
      ).timeout(const Duration(milliseconds: 2500), onTimeout: () => []);
    } catch (e) {
      debugPrint('Firestore photo fetch error: $e');
    }

    if (!mounted) return;
    setState(() {
      _currentCenter = center;
      _locationIssue = locationIssue;
      _currentProfile = profile;
      _nearbyComments = comments;
      _nearbyPhotos = photos;
      _commentsError = commentsError;
      _isLoading = false;
    });

    _showIssueMessageIfNeeded();
  }

  void _showIssueMessageIfNeeded() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    switch (_locationIssue) {
      case LocationIssue.permissionDeniedForever:
        messenger.showSnackBar(
          SnackBar(
            content: const Text('位置情報の許可がオフです。福岡市中心を表示しています。'),
            action: SnackBarAction(
              label: '設定を開く',
              onPressed: () => Geolocator.openAppSettings(),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      case LocationIssue.permissionDenied:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('位置情報が許可されなかったため、福岡市中心を表示しています。'),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      case LocationIssue.serviceDisabled:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('端末の位置情報サービスがオフになっています。'),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      case LocationIssue.none:
        break;
    }

    if (_commentsError != null) {
      messenger.showSnackBar(SnackBar(content: Text(_commentsError!)));
    }
  }

  Future<({ll.LatLng? position, LocationIssue issue})>
      _getCurrentPosition() async {
    try {
      // Web環境以外（iOS/Android実機・エミュレータ）の場合のみ端末の位置情報スイッチを確認
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return (position: null, issue: LocationIssue.serviceDisabled);
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return (position: null, issue: LocationIssue.permissionDeniedForever);
      }
      if (permission == LocationPermission.denied) {
        return (position: null, issue: LocationIssue.permissionDenied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      return (
        position: ll.LatLng(position.latitude, position.longitude),
        issue: LocationIssue.none,
      );
    } catch (_) {
      return (position: null, issue: LocationIssue.serviceDisabled);
    }
  }

  Future<List<NearbyComment>> _fetchNearbyComments(ll.LatLng center) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('comments').get();

    final results = <NearbyComment>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final point = ll.LatLng(lat, lng);
      final distance = distanceMeters(center, point);
      if (distance <= nearbyRadiusMeters) {
        results.add(
          NearbyComment(
            id: doc.id,
            placeName: data['place_name'] as String? ?? '(名称未設定)',
            category: data['category'] as String? ?? 'General',
            content: data['content'] as String? ?? '',
            userName: data['user_name'] as String? ?? 'Traveler',
            userCountry: data['user_country'] as String? ?? '🇯🇵',
            helpfulCount: (data['helpful_count'] as num?)?.toInt() ?? 0,
            position: point,
            distanceMeters: distance,
            translations: (data['translations'] as Map<String, dynamic>?)
                    ?.map((key, value) => MapEntry(key, value.toString())) ??
                const {},
            originalLang: data['original_lang'] as String? ?? 'ja',
          ),
        );
      }
    }

    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }

  Future<List<TravelPhoto>> _fetchNearbyPhotos(
    ll.LatLng center, {
    required String? currentUserId,
    required Set<String> friendIds,
    required MapPhotoFilter filter,
  }) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('travel_photos').get();
    final results = <TravelPhoto>[];
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
      if (lat == null || lng == null || imageUrl == null || ownerId.isEmpty)
        continue;
      final point = ll.LatLng(lat, lng);
      final distance = distanceMeters(center, point);
      final isMine = ownerId == currentUserId;
      final isFriend = friendIds.contains(ownerId);
      final matchesFilter = switch (filter) {
        MapPhotoFilter.publicOnly => visibility == 'public',
        MapPhotoFilter.friendsOnly =>
          visibility == 'friends' && (isMine || isFriend),
      };
      if (distance <= nearbyRadiusMeters && matchesFilter) {
        results.add(
          TravelPhoto(
            id: doc.id,
            imageUrl: imageUrl,
            position: point,
            userId: ownerId,
            visibility: visibility,
            createdAt: createdAt,
            distanceMeters: distance,
          ),
        );
      }
    }
    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Onsen':
        return Colors.blue;
      case 'Culture':
        return Colors.purple;
      case 'Transportation':
        return Colors.green;
      case 'Manners':
        return Colors.redAccent;
      case 'Money':
        return Colors.amber.shade800;
      default:
        return Colors.teal;
    }
  }

  Future<void> _deleteSingleTip(
    NearbyComment comment,
    BuildContext sheetCtx,
    void Function(void Function()) setModalState,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tipsを削除しますか？'),
        content: Text('「${comment.placeName}」への投稿を削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(comment.id)
          .delete();
    } catch (e) {
      debugPrint('Firestore delete error: $e');
    }

    setState(() {
      _nearbyComments.removeWhere((item) => item.id == comment.id);
    });
    setModalState(() {});

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tipsを削除しました')));

    final remaining = _nearbyComments
        .where(
          (item) =>
              _toLocationKey(item.position) == _toLocationKey(comment.position),
        )
        .toList();
    if (remaining.isEmpty) {
      Navigator.pop(sheetCtx);
    }
  }

  Widget _mapSearch() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 12),
                      ],
                    ),
                    child: SearchBarWidget(
                      showCategoryChips: false,
                      onSearchChanged: (query, category) {
                        setState(() {
                          _searchKeyword = query;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _modeToggleButton(),
                 const SizedBox(width: 8),
                _amenityToggleButton(),
              ],
            ),
          ],
        ),
      );

  Widget _photoFilterToggleButtons() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !_isPhotoMode
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.centerRight,
                child: Container(
                  key: const ValueKey('photo_filter_toggle'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12),
                    ],
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      ChoiceChip(
                        label: const Text('全体公開'),
                        selected: _photoFilter == MapPhotoFilter.publicOnly,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(
                            () => _photoFilter = MapPhotoFilter.publicOnly,
                          );
                          _reloadPhotos();
                        },
                      ),
                      ChoiceChip(
                        label: const Text('友達のみ'),
                        selected: _photoFilter == MapPhotoFilter.friendsOnly,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(
                            () => _photoFilter = MapPhotoFilter.friendsOnly,
                          );
                          _reloadPhotos();
                        },
                      ),
                    ],
                  ),
                ),
              ),
      );

  Widget _modeToggleButton() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12),
          ],
        ),
        child: IconButton(
          icon: Text(
            _isPhotoMode ? '💬' : '📷',
            style: const TextStyle(fontSize: 20),
          ),
          onPressed: () {
            setState(() {
              _isPhotoMode = !_isPhotoMode;
            });
          },
        ),
      );
        Widget _amenityToggleButton() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _showAmenities ? AppColors.primary : Colors.white.withValues(alpha: .94),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12),
          ],
        ),
        child: IconButton(
          icon: Text(
            '🚻',
            style: TextStyle(
              fontSize: 20,
              color: _showAmenities ? Colors.white : null,
            ),
          ),
          onPressed: () async {
            setState(() => _showAmenities = !_showAmenities);
            if (_showAmenities && _amenities.isEmpty) {
              final amenities = await OsmAmenityService.fetchAmenities(
                center: _currentCenter,
              );
              if (!mounted) return;
              setState(() => _amenities = amenities);
            }
          },
        ),
      );
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groupedComments = _getGroupedComments();
    final inventoryData = InventoryProvider.of(context);

    return AnimatedBuilder(
      animation: inventoryData,
      builder: (context, _) {
        final markerSkin =
            inventoryData.getEquippedItem(GachaItemType.markerSkin);
        final avatarSkin =
            inventoryData.getEquippedItem(GachaItemType.avatarSkin);
        final currentSkin = markerSkin ?? avatarSkin;

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter,
                  initialZoom: 15.0,
                  minZoom: 4.0,
                  maxZoom: 17.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onLongPress: (tapPosition, point) {
                    showPostTipsDialog(
                      context,
                      targetPosition: point,
                      currentCenter: _currentCenter,
                      onPosted: _handleTipPosted, // コイン加算対応
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.qoo',
                    maxZoom: 17,
                    maxNativeZoom: 17,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentCenter,
                        width: currentSkin != null ? 48 : 24,
                        height: currentSkin != null ? 48 : 24,
                        alignment: Alignment.center,
                        child: CurrentLocationDot(skin: currentSkin),
                      ),
                      if (!_isPhotoMode)
                        for (final entry in groupedComments.entries)
                          if (entry.value.isNotEmpty)
                            Marker(
                              point: entry.value.first.position,
                              width: 200,
                              height: 125,
                              alignment: Alignment.bottomCenter,
                              child: GroupedBubbleMarker(
                                comments: entry.value,
                                locKey: entry.key,
                                carouselIndex: _carouselIndices[entry.key] ?? 0,
                                getCategoryColor: _getCategoryColor,
                                isHelpfulByMe: _isHelpfulByMe,
                                onHelpfulTap: (c) => _toggleHelpful(c),
                                markerSkin: markerSkin,
                                onTap: () => showLocationTipsModal(
                                  context,
                                  commentsInLoc: entry.value,
                                  currentCenter: _currentCenter,
                                  getAllComments: () => _nearbyComments,
                                  toLocationKey: _toLocationKey,
                                  getCategoryColor: _getCategoryColor,
                                  isHelpfulByMe: _isHelpfulByMe,
                                  onDeleteTip: _deleteSingleTip,
                                  onToggleHelpful: _toggleHelpful,
                                  onPosted: _handleTipPosted, // コイン加算対応
                                ),
                              ),
                            ),
                      if (_isPhotoMode)
                        for (final entry in _getGroupedPhotos().entries)
                          Marker(
                            point: entry.value.first.position,
                            width: 72,
                            height: 72,
                            child: GestureDetector(
                              onTap: () => entry.value.length == 1
                                  ? _showPhotoDetail(entry.value.first)
                                  : _showPhotoListDetail(entry.value),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26, blurRadius: 6),
                                  ],
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        entry.value.first.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          for (final hack in _localHacks)
                        Marker(
                          point: ll.LatLng(hack.latitude, hack.longitude),
                          width: 80,
                          height: 60,
                          child: LocalHackMarker(hack: hack),
                        ),
                        if (_showAmenities)
                        for (final amenity in _amenities)
                          Marker(
                            point: amenity.position,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: amenity.type == 'toilets'
                                      ? Colors.blue
                                      : Colors.brown,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  amenity.type == 'toilets' ? '🚻' : '🗑️',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
              _mapSearch(),
              Positioned(
                top: 96,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 66,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categoryFilterList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final cat = _categoryFilterList[index];
                      final isSelected = _selectedCategoryFilter == cat;
                      final catColor = cat == 'All'
                          ? AppColors.navy
                          : _getCategoryColor(cat);

                      return ChoiceChip(
                        label: Text(
                          cat == 'All'
                              ? '🌐 ${UiTranslations.t('すべて')}'
                              : UiTranslations.t(cat),
                          style: const TextStyle(fontSize: 16),
                        ),
                        selected: isSelected,
                        selectedColor: catColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textGrey,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: .92),
                        elevation: isSelected ? 3 : 1,
                        side: BorderSide(
                          color: isSelected ? catColor : Colors.grey.shade300,
                          width: 1,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategoryFilter = cat;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 24,
                bottom: 165,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoom_in_btn',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textGrey,
                      onPressed: () {
                        final zoom = _mapController.camera.zoom;
                        if (zoom < 17.0) {
                          _mapController.move(
                            _mapController.camera.center,
                            zoom + 1,
                          );
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out_btn',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textGrey,
                      onPressed: () {
                        final zoom = _mapController.camera.zoom;
                        if (zoom > 4.0) {
                          _mapController.move(
                            _mapController.camera.center,
                            zoom - 1,
                          );
                        }
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'refresh_btn',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textGrey,
                onPressed: _loadEverything,
                tooltip: UiTranslations.t('再読み込み'),
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'post_tips_btn',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: _isPhotoMode
                    ? () => showPhotoCaptureSheet(
                          context,
                          onTakePhoto: _handleTakePhoto,
                          onPickFromGallery: _handlePickFromGallery,
                        )
                    : () => showPostTipsDialog(
                          context,
                          targetPosition: _currentCenter,
                          currentCenter: _currentCenter,
                          onPosted: _handleTipPosted, // コイン加算対応
                        ),
                icon: Icon(_isPhotoMode ? Icons.camera_alt : Icons.add_comment),
                label: Text(
                  _isPhotoMode
                      ? UiTranslations.t('写真を撮る')
                      : UiTranslations.t('現在地にTips投稿'),
                ),
              ),
              const SizedBox(height: 12),
              _photoFilterToggleButtons(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleTakePhoto(String visibility) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('アップロード中...')),
    );

    final result = await PhotoUploadService.uploadAndSave(
      bytes: await photo.readAsBytes(),
      filename: photo.name,
      position: _currentCenter,
      visibility: visibility,
    );

    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真を投稿しました')),
      );
      await _reloadPhotos(); // 写真リストを更新して即座にマップに反映
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アップロードに失敗しました')),
      );
    }
  }

  Future<void> _reloadPhotos() async {
    try {
      final photos = await _fetchNearbyPhotos(
        _currentCenter,
        currentUserId: AuthService.instance.uid,
        friendIds: _currentProfile?.friends.toSet() ?? const {},
        filter: _photoFilter,
      ).timeout(const Duration(milliseconds: 2500), onTimeout: () => []);
      if (!mounted) return;
      setState(() {
        _nearbyPhotos = photos;
      });
    } catch (e) {
      debugPrint('写真リスト更新エラー: $e');
    }
  }

  Future<void> _handlePickFromGallery(String visibility) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('アップロード中...')),
    );

    final result = await PhotoUploadService.uploadAndSave(
      bytes: await photo.readAsBytes(),
      filename: photo.name,
      position: _currentCenter,
      visibility: visibility,
    );

    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真を投稿しました')),
      );
      await _reloadPhotos(); // 写真リストを更新して即座にマップに反映
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アップロードに失敗しました')),
      );
    }
  }

  Map<String, List<TravelPhoto>> _getGroupedPhotos() {
    final Map<String, List<TravelPhoto>> map = {};
    for (final photo in _nearbyPhotos) {
      final key = _toLocationKey(photo.position);
      map.putIfAbsent(key, () => []).add(photo);
    }
    return map;
  }

  void _showPhotoListDetail(List<TravelPhoto> photos) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            '${photos.length}枚の写真',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: photos.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showPhotoDetail(photos[index]);
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(photos[index].imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showPhotoDetail(TravelPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
