import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/nearby_alert_service.dart';
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

// main.dart に定義されている AppColors をそのまま参照する想定。
// 参照できない場合は `import '../main.dart';` か、
// AppColors を独立ファイルに切り出して両方からimportしてください。

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

// Akitoさんの HomeShell の pages 配列に合わせて MapPage という名前にしている。
// 元の MapScreen をそのままの中身で名前だけ変更したクラス。
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  ll.LatLng _currentCenter = fukuokaFallback;
  List<NearbyComment> _nearbyComments = [];
  List<TravelPhoto> _nearbyPhotos = [];
  bool _isLoading = true;
  final _alertService = NearbyAlertService();
  LocationIssue _locationIssue = LocationIssue.none;
  String? _commentsError;

  String _selectedCategoryFilter = 'All';
  String _searchKeyword = '';
  // --- 地図モード（Tips表示 / 写真表示の切り替え） ---
  bool _isPhotoMode = false; // false = Tips(💬)モード, true = 写真(📷)モード

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
  // --- Helpfulボタンの二重カウント防止 ---
  // このアプリにはまだユーザー認証が無いため、「誰が押したか」ではなく
  // 「この端末で、このTips(comment.id)に自分は既に押したか」を
  // SharedPreferencesに保存して、トグル（押す/取り消す）できるようにする。
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

  /// Helpfulボタンのトグル処理（マップ上の吹き出し・一覧モーダル共通）。
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

  @override
  void initState() {
    super.initState();
    _loadEverything();
    _loadMyHelpfulIds();
    _startCarouselTimer();
    _alertService.start();
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

  /// 現在地取得→Firestoreから投稿取得→距離計算、を一括で行う。
  Future<void> _loadEverything() async {
    setState(() {
      _isLoading = true;
      _commentsError = null;
    });

    ll.LatLng center = fukuokaFallback;
    LocationIssue locationIssue = LocationIssue.none;
    try {
      final result = await _getCurrentPosition().timeout(
        const Duration(seconds: 2),
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
      // Firestore取得失敗時は、空のリストのまま進めて画面は表示する。
      // 「ぐるぐる止まったまま」にならないよう、必ずここでエラーを吸収する。
      commentsError = '投稿データを取得できませんでした。右下のボタンで再読み込みしてください。';
    }
     List<TravelPhoto> photos = [];
    try {
      photos = await _fetchNearbyPhotos(
        center,
      ).timeout(const Duration(milliseconds: 2500), onTimeout: () => []);
    } catch (e) {
      debugPrint('Firestore photo fetch error: $e');
    }

    if (!mounted) return;
    setState(() {
      _currentCenter = center;
      _locationIssue = locationIssue;
      _nearbyComments = comments;
      _nearbyPhotos = photos;
      _commentsError = commentsError;
      _isLoading = false;
    });

    _showIssueMessageIfNeeded();
  }

  /// 位置情報・投稿取得で何か問題があれば、画面下部に一言メッセージを出す。
  /// 優先度: 位置情報の問題 > 投稿取得の問題（両方あっても一つだけ出す）
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

  /// 位置情報の許可を確認し、現在地を取得する。
  /// 成功しなかった場合、理由(LocationIssue)を合わせて返す。
  Future<({ll.LatLng? position, LocationIssue issue})>
      _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (position: null, issue: LocationIssue.serviceDisabled);
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
          ),
        );
      }
    }

    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }
  
  Future<List<TravelPhoto>> _fetchNearbyPhotos(ll.LatLng center) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('travel_photos').get();
    final results = <TravelPhoto>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      final imageUrl = data['imageUrl'] as String?;
      if (lat == null || lng == null || imageUrl == null) continue;
      final point = ll.LatLng(lat, lng);
      final distance = distanceMeters(center, point);
      if (distance <= nearbyRadiusMeters) {
        results.add(
          TravelPhoto(
            id: doc.id,
            imageUrl: imageUrl,
            position: point,
            userId: data['userId'] as String? ?? '',
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

  // --- 自分のTipsを1件削除する処理 ---
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

    // その場所にTipsがもう無くなったらモーダルを閉じる
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
      child: Row(
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
        ],
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
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groupedComments = _getGroupedComments();

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
                  onPosted: (newTip) {
                    setState(() {
                      _nearbyComments.insert(0, newTip);
                      _carouselIndices[_toLocationKey(newTip.position)] = 0;
                    });
                  },
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.qoo',
                maxZoom: 17,
                maxNativeZoom: 17,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentCenter,
                    width: 24,
                    height: 24,
                    child: const CurrentLocationDot(),
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
                onPosted: (newTip) {
                  setState(() {
                    _nearbyComments.insert(0, newTip);
                    _carouselIndices[
                        _toLocationKey(newTip.position)] = 0;
                  });
                },
              ),
            ),
          ),
    if (_isPhotoMode)
      for (final photo in _nearbyPhotos)
        Marker(
          point: photo.position,
          width: 72,
          height: 72,
          child: GestureDetector(
                        onTap: () => _showPhotoDetail(photo),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
                image: DecorationImage(
                  image: NetworkImage(photo.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
  ],
              ),
            ],
          ),

          // 上部：Akitoさんの検索バー
          _mapSearch(),

          // 検索バーの下：カテゴリフィルタ用チップバー（Akitoさんの見た目＋はるかの中身）
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
                  final catColor =
                      cat == 'All' ? AppColors.navy : _getCategoryColor(cat);

                  return ChoiceChip(
                    label: Text(
                      cat == 'All' ? '🌐 すべて' : cat,
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

          // 右下：ズームボタン（Akitoさんの右下寄せ配置に合わせる）
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
            tooltip: '再読み込み',
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
            onPosted: (newTip) {
              setState(() {
                _nearbyComments.insert(0, newTip);
                _carouselIndices[_toLocationKey(newTip.position)] = 0;
              });
            },
          ),
  icon: Icon(_isPhotoMode ? Icons.camera_alt : Icons.add_comment),
  label: Text(_isPhotoMode ? '写真を撮る' : '現在地にTips投稿'),
),
        ],
      ),
    );
  }
    Future<void> _handleTakePhoto() async {
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
  );

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result != null ? '写真を投稿しました' : 'アップロードに失敗しました')),
  );
}

Future<void> _handlePickFromGallery() async {
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
  );

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result != null ? '写真を投稿しました' : 'アップロードに失敗しました')),
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
