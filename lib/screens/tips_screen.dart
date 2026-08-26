// lib/screens/tips_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/review.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  double _currentLat = 33.59040;
  double _currentLng = 130.40170;
  final double _detectionRadiusMeters = 150.0;
  final double _step = 0.0004;

  final Map<String, int> _carouselIndices = {};
  Timer? _carouselTimer;

  final List<Review> _allReviews = [
    Review(
      commentId: '1',
      spotName: '博多豚骨 麺処 一光',
      userId: 'user_01',
      userName: 'Alex',
      latitude: 33.59080,
      longitude: 130.40220,
      category: 'Food',
      content: '濃厚な豚骨スープが絶品！食券制で英語メニューもあります🍜',
      userCountry: '🇺🇸',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      helpfulCount: 5,
    ),
    Review(
      commentId: '1_2',
      spotName: '博多豚骨 麺処 一光',
      userId: 'user_04',
      userName: 'Ken',
      latitude: 33.59080,
      longitude: 130.40220,
      category: 'Money',
      content: 'ランチタイムは替え玉が1玉無料でお得です！',
      userCountry: '🇯🇵',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      helpfulCount: 8,
    ),
    Review(
      commentId: '2',
      spotName: '天然温泉 癒しの湯',
      userId: 'user_02',
      userName: 'Min-ji',
      latitude: 33.58990,
      longitude: 130.40110,
      category: 'Manners',
      content: '脱衣所はスマホ撮影禁止＆入浴前にかけ湯をしましょう♨️',
      userCountry: '🇰🇷',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      helpfulCount: 12,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      setState(() {
        final grouped = _getGroupedReviews();
        for (final entry in grouped.entries) {
          if (entry.value.length > 1) {
            final currentIndex = _carouselIndices[entry.key] ?? 0;
            _carouselIndices[entry.key] =
                (currentIndex + 1) % entry.value.length;
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

  String _toLocationKey(double lat, double lng) =>
      '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';

  Map<String, List<Review>> _getGroupedReviews() {
    final Map<String, List<Review>> grouped = {};
    for (final r in _allReviews) {
      final key = _toLocationKey(r.latitude, r.longitude);
      grouped.putIfAbsent(key, () => []).add(r);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
    }
    return grouped;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double r = 6371000;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Offset _latLngToScreenOffset(double lat, double lng, Size mapSize) {
    final centerX = mapSize.width / 2;
    final centerY = mapSize.height / 2;
    const scale = 220000.0;
    final dx = (lng - _currentLng) * scale;
    final dy = -(lat - _currentLat) * scale;
    return Offset(centerX + dx, centerY + dy);
  }

  Map<String, double> _screenTapToLatLng(Offset tapPos, Size mapSize) {
    final centerX = mapSize.width / 2;
    final centerY = mapSize.height / 2;
    const scale = 220000.0;
    final dx = tapPos.dx - centerX;
    final dy = tapPos.dy - centerY;
    return {
      'lat': _currentLat - (dy / scale),
      'lng': _currentLng + (dx / scale),
    };
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

  void _showLocationTipsModal(List<Review> reviewsInLoc) {
    final targetSpotName = reviewsInLoc.first.spotName;
    final targetLat = reviewsInLoc.first.latitude;
    final targetLng = reviewsInLoc.first.longitude;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[50],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                                  color: Colors.red,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        targetSpotName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Tips一覧 (${reviewsInLoc.length}件)',
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
                              Navigator.pop(context);
                              _showPostDialog(
                                targetLat: targetLat,
                                targetLng: targetLng,
                                initialSpotName: targetSpotName,
                                isLocationFixed: true,
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
                        itemCount: reviewsInLoc.length,
                        itemBuilder: (context, index) {
                          final r = reviewsInLoc[index];
                          final catColor = _getCategoryColor(r.category);

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
                                            r.userCountry,
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            r.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (index == 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                '👑 最多いいね',
                                                style: TextStyle(
                                                  fontSize: 10,
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
                                          r.category,
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
                                    r.content,
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
                                      Text(
                                        '${r.createdAt.hour}:${r.createdAt.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setModalState(() {
                                            r.helpfulCount++;
                                          });
                                          setState(() {
                                            reviewsInLoc.sort(
                                              (a, b) => b.helpfulCount
                                                  .compareTo(a.helpfulCount),
                                            );
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
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
                                                'Helpful (${r.helpfulCount})',
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

  void _showPostDialog({
    required double targetLat,
    required double targetLng,
    String? initialSpotName,
    bool isLocationFixed = false,
  }) {
    final spotController = TextEditingController(text: initialSpotName ?? '');
    final textController = TextEditingController();
    String selectedCategory = 'Food';
    final categories = [
      'Food',
      'Onsen',
      'Culture',
      'Transportation',
      'Manners',
      'Money',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isLocationFixed ? 'Tipsを追加投稿' : '新しい場所＆Tipsを投稿'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 座標: ${targetLat.toStringAsFixed(4)}, ${targetLng.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'スポット・場所の名前:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: spotController,
                      enabled: !isLocationFixed,
                      decoration: InputDecoration(
                        hintText: '例: ○○食堂、桜の見えるベンチ',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        fillColor: isLocationFixed ? Colors.grey[100] : null,
                        filled: isLocationFixed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'カテゴリ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                      'Tips・アドバイス:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: textController,
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final spotName = spotController.text.trim().isEmpty
                        ? 'お気に入りスポット'
                        : spotController.text.trim();
                    if (textController.text.trim().isEmpty) return;

                    final newReview = Review(
                      commentId: DateTime.now().millisecondsSinceEpoch
                          .toString(),
                      spotName: spotName,
                      userId: 'current_user',
                      userName: 'You',
                      latitude: targetLat,
                      longitude: targetLng,
                      category: selectedCategory,
                      content: textController.text.trim(),
                      userCountry: '🇯🇵',
                      createdAt: DateTime.now(),
                      helpfulCount: 1,
                    );

                    setState(() {
                      _allReviews.insert(0, newReview);
                      final key = _toLocationKey(targetLat, targetLng);
                      _carouselIndices[key] = 0;
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('「$spotName」に新しいTipsを投稿しました！')),
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final groupedReviews = _getGroupedReviews();

    int nearbyCount = 0;
    for (final r in _allReviews) {
      if (_calculateDistance(
            _currentLat,
            _currentLng,
            r.latitude,
            r.longitude,
          ) <=
          _detectionRadiusMeters) {
        nearbyCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: '初期位置に戻す',
            icon: const Icon(Icons.my_location),
            onPressed: () {
              setState(() {
                _currentLat = 33.59040;
                _currentLng = 130.40170;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final latLng = _screenTapToLatLng(details.localPosition, size);
              _showPostDialog(
                targetLat: latLng['lat']!,
                targetLng: latLng['lng']!,
              );
            },
            child: Container(
              color: const Color(0xFFE8ECEF),
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(painter: GpsMapGridPainter()),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.06),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '現在地',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final entry in groupedReviews.entries)
            if (entry.value.isNotEmpty)
              _buildMarkerWithDynamicBubble(entry.key, entry.value, size),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'マップをタップして新規Tipsを投稿 (近隣: $nearbyCount件)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GPS移動',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  IconButton(
                    iconSize: 28,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.arrow_drop_up,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () => setState(() => _currentLat += _step),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 28,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.arrow_left,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () => setState(() => _currentLng -= _step),
                      ),
                      IconButton(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.center_focus_strong,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() {
                          _currentLat = 33.59040;
                          _currentLng = 130.40170;
                        }),
                      ),
                      IconButton(
                        iconSize: 28,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.arrow_right,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () => setState(() => _currentLng += _step),
                      ),
                    ],
                  ),
                  IconButton(
                    iconSize: 28,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () => setState(() => _currentLat -= _step),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showPostDialog(targetLat: _currentLat, targetLng: _currentLng),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('現在地にTips投稿'),
      ),
    );
  }

  Widget _buildMarkerWithDynamicBubble(
    String locKey,
    List<Review> reviewsInLoc,
    Size size,
  ) {
    final firstRev = reviewsInLoc.first;
    final dist = _calculateDistance(
      _currentLat,
      _currentLng,
      firstRev.latitude,
      firstRev.longitude,
    );
    final isNearby = dist <= _detectionRadiusMeters;

    final pos = _latLngToScreenOffset(
      firstRev.latitude,
      firstRev.longitude,
      size,
    );

    final rawIndex = _carouselIndices[locKey] ?? 0;
    final currentIndex = reviewsInLoc.isEmpty
        ? 0
        : rawIndex % reviewsInLoc.length;
    final activeReview = reviewsInLoc[currentIndex];

    final catColor = _getCategoryColor(activeReview.category);

    final isEast = firstRev.longitude >= _currentLng;
    final bubbleLeft = isEast ? -20.0 : -200.0;
    final arrowOffset = isEast ? 35.0 : 195.0;

    return Positioned(
      left: pos.dx - 20,
      top: pos.dy - 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => _showLocationTipsModal(reviewsInLoc),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isNearby ? Colors.white : Colors.white70,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeReview.userCountry,
                        style: TextStyle(fontSize: isNearby ? 11 : 9),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        activeReview.spotName.length > 6
                            ? '${activeReview.spotName.substring(0, 6)}..'
                            : activeReview.spotName,
                        style: TextStyle(
                          fontSize: isNearby ? 9.5 : 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (reviewsInLoc.length > 1) ...[
                        const SizedBox(width: 2),
                        Text(
                          '(${reviewsInLoc.length})',
                          style: TextStyle(
                            fontSize: isNearby ? 9 : 7.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.location_on,
                  size: isNearby ? 34 : 26,
                  color: isNearby ? catColor : catColor.withOpacity(0.55),
                ),
              ],
            ),
          ),
          if (isNearby)
            Positioned(
              left: bubbleLeft,
              bottom: 44,
              child: GestureDetector(
                onTap: () => _showLocationTipsModal(reviewsInLoc),
                child: CustomPaint(
                  painter: OffsetSpeechBubblePainter(
                    color: Colors.white,
                    arrowX: arrowOffset,
                  ),
                  child: Container(
                    width: 225,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: Column(
                        key: ValueKey<String>(activeReview.commentId),
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
                                      activeReview.userCountry,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        activeReview.userName,
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
                              if (reviewsInLoc.length > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${currentIndex + 1}/${reviewsInLoc.length} 🔄',
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeReview.content,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  activeReview.category,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: catColor,
                                  ),
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
                                    '${activeReview.helpfulCount}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '一覧 >',
                                    style: TextStyle(
                                      fontSize: 8.5,
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
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OffsetSpeechBubblePainter extends CustomPainter {
  final Color color;
  final double arrowX;

  OffsetSpeechBubblePainter({required this.color, required this.arrowX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    const radius = 10.0;
    const arrowWidth = 12.0;
    const arrowHeight = 9.0;
    final rectHeight = size.height - arrowHeight;

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, rectHeight),
        const Radius.circular(radius),
      ),
    );

    final clampedArrowX = arrowX.clamp(
      radius + arrowWidth / 2,
      size.width - radius - arrowWidth / 2,
    );

    final arrowPath = Path()
      ..moveTo(clampedArrowX - arrowWidth / 2, rectHeight)
      ..lineTo(clampedArrowX, size.height)
      ..lineTo(clampedArrowX + arrowWidth / 2, rectHeight)
      ..close();

    path.addPath(arrowPath, Offset.zero);
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GpsMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;

    canvas.drawLine(
      Offset(0, size.height * 0.38),
      Offset(size.width, size.height * 0.38),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, 0),
      Offset(size.width * 0.48, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.58),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
