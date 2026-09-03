class CollectionSpot {
  final String id;
  final String collectionId;
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  CollectionSpot({
    required this.id,
    required this.collectionId,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory CollectionSpot.fromMap(String id, Map<String, dynamic> map) {
    return CollectionSpot(
      id: id,
      collectionId: map['collectionId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}