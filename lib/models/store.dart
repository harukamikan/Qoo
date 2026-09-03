/// 店舗アカウントのプロフィール。Firestore の `stores/{uid}` に対応する。
class Store {
  final String id; // == ownerUid
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phoneNumber; // 電話番号認証はせず、連絡先として保存するのみ
  final String ownerUid;
  final String description; // 店舗コメント欄
  final DateTime? createdAt;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.ownerUid,
    this.description = '',
    this.createdAt,
  });

  // Firestoreに保存するときの形式に変換
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'ownerUid': ownerUid,
      'description': description,
    };
  }

  // Firestoreから取得したデータをStoreに変換
  factory Store.fromMap(String id, Map<String, dynamic> map) {
    return Store(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: map['phoneNumber'] ?? '',
      ownerUid: map['ownerUid'] ?? id,
      description: map['description'] ?? '',
      createdAt: null, // createdAt は serverTimestamp のため一覧表示等では別途取得
    );
  }
}
