// lib/models/review.dart

class Review {
  final String id;
  final String commentId;

  final String placeId;
  final String spotName;

  final String userId;
  final String userName;

  final double latitude;
  final double longitude;

  final String category;

  final String comment;

  final String userCountry;

  final DateTime createdAt;

  final int stars;

  final int avatarColor;

  final String userTag;

  final bool isMine;

  final int photoCount;

  // seed_data.dart などで直接指定できるようにする
  final String timeAgo;

  int helpfulCount;

  Review({
    String? id,
    String? commentId,

    this.placeId = '',
    this.spotName = '',

    this.userId = '',
    this.userName = '',

    this.latitude = 0.0,
    this.longitude = 0.0,

    this.category = '',

    String? comment,
    String? content,

    this.userCountry = '',

    DateTime? createdAt,

    this.stars = 0,

    this.avatarColor = 0xFF90CAF9,

    this.userTag = 'JP',

    this.isMine = false,

    this.photoCount = 0,

    String? timeAgo,

    this.helpfulCount = 0,
  })  : id = id ?? commentId ?? '',
        commentId = commentId ?? id ?? '',
        comment = comment ?? content ?? '',
        createdAt = createdAt ?? DateTime.now(),
        timeAgo = timeAgo ?? '';

  // JSON → Review
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String?,
      commentId: json['commentId'] as String?,
      placeId: json['placeId'] as String? ?? '',
      spotName: json['spotName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      comment: json['comment'] as String?,
      content: json['content'] as String?,
      userCountry: json['userCountry'] as String? ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      avatarColor:
          (json['avatarColor'] as num?)?.toInt() ?? 0xFF90CAF9,
      userTag: json['userTag'] as String? ?? 'JP',
      isMine: json['isMine'] as bool? ?? false,
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      timeAgo: json['timeAgo'] as String? ?? '',
      helpfulCount:
          (json['helpfulCount'] as num?)?.toInt() ?? 0,
    );
  }

  // Review → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commentId': commentId,
      'placeId': placeId,
      'spotName': spotName,
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'comment': comment,
      'content': comment,
      'userCountry': userCountry,
      'createdAt': createdAt.toIso8601String(),
      'stars': stars,
      'avatarColor': avatarColor,
      'userTag': userTag,
      'isMine': isMine,
      'photoCount': photoCount,
      'timeAgo': timeAgo,
      'helpfulCount': helpfulCount,
    };
  }

  // 既存コードとの互換用
  String get content => comment;
}