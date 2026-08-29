class LocalHack {
  final String id;
  final String title;
  final String content;
  final double latitude;
  final double longitude;
  final String category;

  LocalHack({
    required this.id,
    required this.title,
    required this.content,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  // FirestoreなどのMap形式から変換するファクトリ
  factory LocalHack.fromMap(String id, Map<String, dynamic> map) {
    return LocalHack(
      id: id,
      title: map['place_name'] ?? '',
      content: map['content'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      category: map['category'] ?? '',
    );
  }
}