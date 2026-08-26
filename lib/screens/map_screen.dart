import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/nearby_alert_service.dart';
import '../utils/geo_utils.dart';
const double nearbyRadiusMeters = 1000;

final ll.LatLng fukuokaFallback = ll.LatLng(33.5902, 130.4017);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  ll.LatLng _currentCenter = fukuokaFallback;
  List<NearbyComment> _nearbyComments = [];
  bool _isLoading = true;
  final _alertService = NearbyAlertService();

  String _selectedCategoryFilter = 'All';
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

  @override
  void initState() {
    super.initState();
    _loadEverything();
    _startCarouselTimer();
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
    super.dispose();
  }

  String _toLocationKey(ll.LatLng pos) =>
      '${pos.latitude.toStringAsFixed(4)},${pos.longitude.toStringAsFixed(4)}';

  Map<String, List<NearbyComment>> _getGroupedComments() {
    final Map<String, List<NearbyComment>> map = {};
    for (final c in _nearbyComments) {
      if (_selectedCategoryFilter != 'All' &&
          c.category != _selectedCategoryFilter) {
        continue;
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
    setState(() => _isLoading = true);

    ll.LatLng center = fukuokaFallback;
    try {
      final pos = await _getCurrentPosition().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      if (pos != null) {
        center = pos;
      }
    } catch (_) {}

    List<NearbyComment> comments = [];
    try {
      comments = await _fetchNearbyComments(
        center,
      ).timeout(const Duration(milliseconds: 2500), onTimeout: () => []);
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
    }

    if (!mounted) return;
    setState(() {
      _currentCenter = center;
      _nearbyComments = comments;
      _isLoading = false;
    });
  }

  Future<ll.LatLng?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      return ll.LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<List<NearbyComment>> _fetchNearbyComments(ll.LatLng center) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('comments')
        .get();

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
  
  double _distanceMeters(ll.LatLng a, ll.LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h =
        sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

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

    if (!mounted) return;
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

  // --- Tips投稿ダイアログ ---
  void _showPostTipsDialog({
    required ll.LatLng targetPosition,
    String? initialPlaceName,
  }) {
    final placeController = TextEditingController(text: initialPlaceName ?? '');
    final contentController = TextEditingController();
    String selectedCategory = 'Food';
    final categories = [
      'Food',
      'Onsen',
      'Culture',
      'Transportation',
      'Manners',
      'Money',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit_location_alt, color: Colors.teal),
                  SizedBox(width: 8),
                  Text(
                    'Tipsを投稿',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 座標: ${targetPosition.latitude.toStringAsFixed(4)}, ${targetPosition.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.teal[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'スポット名 / 場所の名前:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: placeController,
                      decoration: const InputDecoration(
                        hintText: '例: ○○公園、駅前カフェ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'カテゴリ:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tips / アドバイス:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: contentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '旅行者へのおすすめポイントや注意点...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (contentController.text.trim().isEmpty) return;

                    final placeName = placeController.text.trim().isEmpty
                        ? 'おすすめスポット'
                        : placeController.text.trim();

                    String newDocId = DateTime.now().millisecondsSinceEpoch
                        .toString();
                    try {
                      final ref = await FirebaseFirestore.instance
                          .collection('comments')
                          .add({
                            'place_name': placeName,
                            'category': selectedCategory,
                            'content': contentController.text.trim(),
                            'latitude': targetPosition.latitude,
                            'longitude': targetPosition.longitude,
                            'user_name': 'You',
                            'user_country': '🇯🇵',
                            'helpful_count': 1,
                            'created_at': FieldValue.serverTimestamp(),
                          });
                      newDocId = ref.id;
                    } catch (e) {
                      debugPrint('Firebase save note: $e');
                    }

                    final newTip = NearbyComment(
                      id: newDocId,
                      placeName: placeName,
                      category: selectedCategory,
                      content: contentController.text.trim(),
                      userName: 'You',
                      userCountry: '🇯🇵',
                      helpfulCount: 1,
                      position: targetPosition,
                      distanceMeters: _distanceMeters(
                        _currentCenter,
                        targetPosition,
                      ),
                    );

                    setState(() {
                      _nearbyComments.insert(0, newTip);
                      _carouselIndices[_toLocationKey(targetPosition)] = 0;
                    });

                    if (!mounted) return;
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('「$placeName」にTipsを追加しました！')),
                    );
                  },
                  child: const Text('投稿する'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 同一スポットのTips一覧モーダル ---
  void _showLocationTipsModal(
    BuildContext context,
    List<NearbyComment> commentsInLoc,
  ) {
    final targetSpot = commentsInLoc.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[50],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentList = _nearbyComments
                .where(
                  (item) =>
                      _toLocationKey(item.position) ==
                      _toLocationKey(targetSpot.position),
                )
                .toList();
            currentList.sort(
              (a, b) => b.helpfulCount.compareTo(a.helpfulCount),
            );

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.place,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        targetSpot.placeName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Tips一覧 (${currentList.length}件) • 約${targetSpot.distanceMeters.toStringAsFixed(0)}m',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text(
                              '追加投稿',
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _showPostTipsDialog(
                                targetPosition: targetSpot.position,
                                initialPlaceName: targetSpot.placeName,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          final c = currentList[index];
                          final catColor = _getCategoryColor(c.category);
                          final isMyTip = c.userName == 'You'; // 自分の投稿かどうか判定

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c.userCountry,
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            c.userName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isMyTip
                                                  ? Colors.teal[800]
                                                  : Colors.black87,
                                            ),
                                          ),
                                          if (isMyTip) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.teal.shade200,
                                                ),
                                              ),
                                              child: const Text(
                                                '自分',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  color: Colors.teal,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (index == 0 &&
                                              currentList.length > 1) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                '👑 最多',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.brown,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: catColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          c.category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: catColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    c.content,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 自分の投稿の場合のみ削除ボタンを表示
                                      if (isMyTip)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                          tooltip: 'この投稿を削除',
                                          onPressed: () => _deleteSingleTip(
                                            c,
                                            sheetCtx,
                                            setModalState,
                                          ),
                                        )
                                      else
                                        const SizedBox.shrink(),

                                      InkWell(
                                        onTap: () {
                                          setModalState(() => c.helpfulCount++);
                                          setState(() {
                                            currentList.sort(
                                              (a, b) => b.helpfulCount
                                                  .compareTo(a.helpfulCount),
                                            );
                                          });
                                          FirebaseFirestore.instance
                                              .collection('comments')
                                              .doc(c.id)
                                              .update({
                                                'helpful_count': c.helpfulCount,
                                              })
                                              .catchError((_) {});
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.thumb_up_alt_rounded,
                                                size: 14,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Helpful (${c.helpfulCount})',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
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
                _showPostTipsDialog(targetPosition: point);
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
                    child: const _CurrentLocationDot(),
                  ),
                  for (final entry in groupedComments.entries)
                    if (entry.value.isNotEmpty)
                      Marker(
                        point: entry.value.first.position,
                        width: 200,
                        height: 125,
                        alignment: Alignment.bottomCenter,
                        child: _GroupedBubbleMarker(
                          comments: entry.value,
                          locKey: entry.key,
                          carouselIndex: _carouselIndices[entry.key] ?? 0,
                          getCategoryColor: _getCategoryColor,
                          onTap: () =>
                              _showLocationTipsModal(context, entry.value),
                        ),
                      ),
                ],
              ),
            ],
          ),

          // 上部：カテゴリフィルタ用チップバー
          Positioned(
            top: 16,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categoryFilterList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categoryFilterList[index];
                  final isSelected = _selectedCategoryFilter == cat;
                  final catColor = cat == 'All'
                      ? Colors.teal
                      : _getCategoryColor(cat);

                  return ChoiceChip(
                    label: Text(
                      cat == 'All' ? '🌐 すべて' : cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: catColor,
                    backgroundColor: Colors.white.withOpacity(0.92),
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

          // 右上：ズームボタン
          Positioned(
            top: 70,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
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
                const SizedBox(height: 6),
                FloatingActionButton.small(
                  heroTag: 'zoom_out_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
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
            onPressed: _loadEverything,
            tooltip: '再読み込み',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'post_tips_btn',
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            onPressed: () =>
                _showPostTipsDialog(targetPosition: _currentCenter),
            icon: const Icon(Icons.add_comment),
            label: const Text('現在地にTips投稿'),
          ),
        ],
      ),
    );
  }
}

class NearbyComment {
  final String id;
  final String placeName;
  final String category;
  final String content;
  final String userName;
  final String userCountry;
  int helpfulCount;
  final ll.LatLng position;
  final double distanceMeters;

  NearbyComment({
    required this.id,
    required this.placeName,
    required this.category,
    required this.content,
    required this.userName,
    required this.userCountry,
    required this.helpfulCount,
    required this.position,
    required this.distanceMeters,
  });
}

class _CurrentLocationDot extends StatelessWidget {
  const _CurrentLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}

class _GroupedBubbleMarker extends StatelessWidget {
  final List<NearbyComment> comments;
  final String locKey;
  final int carouselIndex;
  final Color Function(String) getCategoryColor;
  final VoidCallback onTap;

  const _GroupedBubbleMarker({
    required this.comments,
    required this.locKey,
    required this.carouselIndex,
    required this.getCategoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeIndex = comments.isEmpty ? 0 : carouselIndex % comments.length;
    final activeComment = comments[activeIndex];
    final categoryColor = getCategoryColor(activeComment.category);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 195,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Column(
                key: ValueKey<String>(activeComment.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              activeComment.userCountry,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activeComment.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (comments.length > 1)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${activeIndex + 1}/${comments.length} 🔄',
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          activeComment.category,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activeComment.content,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.black87,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activeComment.placeName,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.thumb_up_alt_rounded,
                            size: 10,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${activeComment.helpfulCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '一覧>',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: const Size(12, 6),
            painter: _TrianglePainter(color: Colors.white),
          ),
          const SizedBox(height: 1),
          Icon(Icons.place, color: categoryColor, size: 26),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  static final Paint shadowPaint = Paint()
    ..color = Colors.black12
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
