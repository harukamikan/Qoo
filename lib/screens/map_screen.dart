import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 現在地からこの半径（メートル）以内の投稿だけを表示する。
const double nearbyRadiusMeters = 500;

/// 現在地が取れなかった時のフォールバック中心地点（福岡市天神付近）
final ll.LatLng fukuokaFallback = ll.LatLng(33.5902, 130.4017);

/// 現在地取得がなぜうまくいかなかったかを表す。成功時は none。
enum LocationIssue {
  none,
  serviceDisabled, // 端末の位置情報サービス自体がオフ
  permissionDenied, // 今回拒否された（次回また聞ける）
  permissionDeniedForever, // 完全拒否（設定から手動で有効にするしかない）
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  ll.LatLng? _currentLocation;
  List<NearbyComment> _nearbyComments = [];
  bool _isLoading = true;
  LocationIssue _locationIssue = LocationIssue.none;
  String? _commentsError;

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  /// 現在地取得→Firestoreから投稿取得→距離計算、を一括で行う。
  Future<void> _loadEverything() async {
    setState(() {
      _isLoading = true;
      _commentsError = null;
    });

    final locationResult = await _getCurrentPosition();
    final center = locationResult.position ?? fukuokaFallback;

    List<NearbyComment> comments = [];
    String? commentsError;
    try {
      comments = await _fetchNearbyComments(center);
    } catch (_) {
      // Firestore取得失敗時は、空のリストのまま進めて画面は表示する。
      // 「ぐるぐる止まったまま」にならないよう、必ずここでエラーを吸収する。
      commentsError = '投稿データを取得できませんでした。右下のボタンで再読み込みしてください。';
    }

    if (!mounted) return;
    setState(() {
      _currentLocation = locationResult.position;
      _locationIssue = locationResult.issue;
      _nearbyComments = comments;
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
  Future<({ll.LatLng? position, LocationIssue issue})> _getCurrentPosition() async {
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return (
        position: ll.LatLng(position.latitude, position.longitude),
        issue: LocationIssue.none,
      );
    } catch (_) {
      return (position: null, issue: LocationIssue.serviceDisabled);
    }
  }

  /// comments コレクションを全件取得し、現在地からの距離を計算して
  /// nearbyRadiusMeters 以内のものだけ抽出、近い順に並べ替える。
  Future<List<NearbyComment>> _fetchNearbyComments(ll.LatLng center) async {
    final snapshot = await FirebaseFirestore.instance.collection('comments').get();

    final results = <NearbyComment>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final point = ll.LatLng(lat, lng);
      final distance = _distanceMeters(center, point);
      if (distance <= nearbyRadiusMeters) {
        results.add(NearbyComment(
          id: doc.id,
          placeName: data['place_name'] as String? ?? '(名称未設定)',
          category: data['category'] as String? ?? '',
          content: data['content'] as String? ?? '',
          position: point,
          distanceMeters: distance,
        ));
      }
    }

    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }

  /// Haversine公式による2点間の距離計算（メートル）
  double _distanceMeters(ll.LatLng a, ll.LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final center = _currentLocation ?? fukuokaFallback;

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.qoo',
          ),
          MarkerLayer(
            markers: [
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 24,
                  height: 24,
                  child: const _CurrentLocationDot(),
                ),
              for (final comment in _nearbyComments)
                Marker(
                  point: comment.position,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showCommentSheet(context, comment),
                    child: const _CommentPin(),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadEverything,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showCommentSheet(BuildContext context, NearbyComment comment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.placeName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(comment.category, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            Text(comment.content, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class NearbyComment {
  final String id;
  final String placeName;
  final String category;
  final String content;
  final ll.LatLng position;
  final double distanceMeters;

  NearbyComment({
    required this.id,
    required this.placeName,
    required this.category,
    required this.content,
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
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _CommentPin extends StatelessWidget {
  const _CommentPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.deepOrange, width: 2),
      ),
      child: const Icon(Icons.place, color: Colors.deepOrange, size: 20),
    );
  }
}