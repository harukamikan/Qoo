import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー投稿によるゴミ箱の位置情報。
///
/// Overpass API（OSM）のゴミ箱データは日本だと数が少なく地図に出せないため、
/// Tips投稿のついでにユーザー自身に登録してもらい、Firestoreの `trash_bins`
/// コレクションに貯めていく方式。
class TrashBin {
  final String id;
  final double latitude;
  final double longitude;
  final String userId;
  final DateTime? createdAt;

  TrashBin({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.userId,
    this.createdAt,
  });

  factory TrashBin.fromMap(String id, Map<String, dynamic> map) {
    return TrashBin(
      id: id,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      userId: map['userId'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
