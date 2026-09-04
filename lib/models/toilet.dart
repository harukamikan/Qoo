import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー投稿によるトイレの位置情報。
///
/// Overpass API（OSM）のトイレデータは不安定で取得できないことがあるため、
/// ユーザー投稿でもFirestoreの `toilets` コレクションに貯めて、
/// API分と合わせて地図に表示する。
class Toilet {
  final String id;
  final double latitude;
  final double longitude;
  final String userId;
  final DateTime? createdAt;

  Toilet({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.userId,
    this.createdAt,
  });

  factory Toilet.fromMap(String id, Map<String, dynamic> map) {
    return Toilet(
      id: id,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      userId: map['userId'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}