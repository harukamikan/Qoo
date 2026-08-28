import 'package:latlong2/latlong.dart' as ll;

/// 地図上に表示する、現在地周辺のTips（Firestoreのcommentsコレクション由来）。
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