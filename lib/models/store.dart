class Store {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final String ownerUid;
  final String description;
  final String category;
  final bool isApproved;
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
    this.category = 'その他',
    this.isApproved = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'ownerUid': ownerUid,
      'description': description,
      'category': category,
      'isApproved': isApproved,
    };
  }

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
      category: map['category'] ?? 'その他',
      isApproved: map['isApproved'] ?? false,
      createdAt: null,
    );
  }
}