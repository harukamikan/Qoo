/// スポットに紐づく口コミ（レビュー）のデータモデル。
class Review {
  final String id;
  final String placeId;
  String userName;
  String userTag; // "US" / "JP" のような国タグ
  int avatarColor; // アバターの背景色（ARGB int）
  int stars; // 1〜5
  String comment;
  String timeAgo; // "2日前" のような表示用テキスト
  int helpfulCount;
  int photoCount;
  bool isMine; // 自分（Traveler Explorer）が投稿したものかどうか
  final DateTime createdAt;

  Review({
    required this.id,
    required this.placeId,
    required this.userName,
    required this.userTag,
    required this.avatarColor,
    required this.stars,
    required this.comment,
    required this.timeAgo,
    required this.helpfulCount,
    required this.photoCount,
    required this.isMine,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'placeId': placeId,
        'userName': userName,
        'userTag': userTag,
        'avatarColor': avatarColor,
        'stars': stars,
        'comment': comment,
        'timeAgo': timeAgo,
        'helpfulCount': helpfulCount,
        'photoCount': photoCount,
        'isMine': isMine,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        placeId: json['placeId'] as String,
        userName: json['userName'] as String,
        userTag: json['userTag'] as String,
        avatarColor: json['avatarColor'] as int,
        stars: json['stars'] as int,
        comment: json['comment'] as String,
        timeAgo: json['timeAgo'] as String,
        helpfulCount: json['helpfulCount'] as int,
        photoCount: json['photoCount'] as int,
        isMine: json['isMine'] as bool,
        createdAt: DateTime.tryParse(json['createdAt'] as String) ??
            DateTime.now(),
      );
}
