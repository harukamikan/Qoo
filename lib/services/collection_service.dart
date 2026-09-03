import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_collection.dart';
import '../models/collection_spot.dart';

/// 地域コレクション（コレクション・スポット・投稿）を扱うサービス。
class CollectionService {
  static final _db = FirebaseFirestore.instance;

  /// 全コレクション一覧を取得する。
  static Future<List<TravelCollection>> fetchCollections() async {
    final snapshot = await _db.collection('collections').get();
    return snapshot.docs
        .map((doc) => TravelCollection.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// 指定コレクションに属するスポット一覧を取得する。
  static Future<List<CollectionSpot>> fetchSpots(String collectionId) async {
    final snapshot = await _db
        .collection('collection_spots')
        .where('collectionId', isEqualTo: collectionId)
        .get();
    return snapshot.docs
        .map((doc) => CollectionSpot.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// 自分がそのスポットに投稿済みかどうかをチェックするための、
  /// 投稿済みスポットIDの一覧を取得する。
  static Future<Set<String>> fetchMyPostedSpotIds(String userId) async {
    final snapshot = await _db
        .collection('collection_posts')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => doc.data()['spotId'] as String)
        .toSet();
  }

  /// スポットへの写真投稿を記録する（imageUrlはPhotoUploadServiceでアップロード済みのURL）。
  static Future<void> postToSpot({
    required String spotId,
    required String userId,
    required String imageUrl,
  }) async {
    await _db.collection('collection_posts').add({
      'spotId': spotId,
      'userId': userId,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}