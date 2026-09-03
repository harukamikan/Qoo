class TravelCollection {
  final String id;
  final String name;
  final String description;
  final String area;
  final int totalSpots;

  TravelCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.area,
    required this.totalSpots,
  });

  factory TravelCollection.fromMap(String id, Map<String, dynamic> map) {
    return TravelCollection(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      area: map['area'] ?? '',
      totalSpots: (map['totalSpots'] as num?)?.toInt() ?? 0,
    );
  }
}