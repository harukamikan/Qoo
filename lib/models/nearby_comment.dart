import 'package:latlong2/latlong.dart' as ll;

/// 地図上に表示する、現在地周辺のTips（Firestoreのcommentsコレクション由来）。
class NearbyComment {
  final String id;
  final String placeName;
  final String category;
  final String content;
  final String userName;
  final String userCountry;
  int helpfulCount;
  final ll.LatLng position;
  final double distanceMeters;
  final Map<String, String> translations;
  final String originalLang;
  final DateTime createdAt; // 投稿日時（Firestoreのcreated_atから変換）

  NearbyComment({
    required this.id,
    required this.placeName,
    required this.category,
    required this.content,
    required this.userName,
    required this.userCountry,
    required this.helpfulCount,
    required this.position,
    required this.distanceMeters,
    required this.createdAt,
    this.translations = const {},
    this.originalLang = 'ja',
  });

  /// 指定した言語での表示テキストを返す。
  /// translationsに該当言語が無ければ、原文（content）にフォールバックする。
  String contentFor(String langCode) {
    return translations[langCode] ?? content;
  }

  /// 「3時間前」「2日前」のような相対時間表記を返す。
  /// 30日以上前の投稿は「2026/9/4」のような日付表記にフォールバックする。
  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.isNegative || diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 30) return '${diff.inDays}日前';
    return '${createdAt.year}/${createdAt.month}/${createdAt.day}';
  }
}
