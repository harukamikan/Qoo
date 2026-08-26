// lib/models/review.dart

class Review {
  final String commentId;
  final String spotName;
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final String category;
  final String content;
  final String userCountry;
  final DateTime createdAt;
  int helpfulCount;

  Review({
    required this.commentId,
    required this.spotName,
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.content,
    required this.userCountry,
    required this.createdAt,
    this.helpfulCount = 0,
  });
}
