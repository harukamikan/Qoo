import 'package:flutter/material.dart';

/// 「保存した場所」「地図」「口コミ」画面などで共通して使う
/// スポット（場所）のデータモデル。
class Place {
  final String id;
  String name;
  String category; // グルメ / 文化 / 温泉 / 交通 など
  String quote; // カード上に表示される短い引用コメント
  double rating; // 平均評価（0.0〜5.0）
  int ratingCount; // レビュー数
  String locationLabel; // 福岡 / 東京 / 群馬 / 表参道 など
  String footerLabel; // フッターに出す2つ目の情報（"展望台" 等 or 評価点）
  String footerIconKey; // フッターアイコンの種類（下のiconFor()で解決）
  String photoIconKey; // 写真プレースホルダー中央に出すアイコン種類
  List<int> gradientColors; // 写真プレースホルダーのグラデーション（ARGB int）
  bool isSaved;
  double lat;
  double lng;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.quote,
    required this.rating,
    required this.ratingCount,
    required this.locationLabel,
    required this.footerLabel,
    required this.footerIconKey,
    required this.photoIconKey,
    required this.gradientColors,
    required this.isSaved,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quote': quote,
        'rating': rating,
        'ratingCount': ratingCount,
        'locationLabel': locationLabel,
        'footerLabel': footerLabel,
        'footerIconKey': footerIconKey,
        'photoIconKey': photoIconKey,
        'gradientColors': gradientColors,
        'isSaved': isSaved,
        'lat': lat,
        'lng': lng,
      };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        quote: json['quote'] as String,
        rating: (json['rating'] as num).toDouble(),
        ratingCount: json['ratingCount'] as int,
        locationLabel: json['locationLabel'] as String,
        footerLabel: json['footerLabel'] as String,
        footerIconKey: json['footerIconKey'] as String,
        photoIconKey: json['photoIconKey'] as String,
        gradientColors: (json['gradientColors'] as List)
            .map((e) => e as int)
            .toList(),
        isSaved: json['isSaved'] as bool,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );

  List<Color> get gradient =>
      gradientColors.map((c) => Color(c)).toList(growable: false);

  IconData get photoIcon => _iconFor(photoIconKey);

  IconData get footerIcon => _iconFor(footerIconKey);

  static IconData _iconFor(String key) {
    switch (key) {
      case 'ramen':
        return Icons.ramen_dining;
      case 'city':
        return Icons.location_city;
      case 'onsen':
        return Icons.hot_tub;
      case 'coffee':
        return Icons.coffee;
      case 'train':
        return Icons.tram;
      case 'star':
        return Icons.star_rounded;
      case 'visibility':
        return Icons.visibility_outlined;
      case 'spa':
        return Icons.spa_outlined;
      case 'cafe':
        return Icons.local_cafe_outlined;
      case 'transit':
        return Icons.directions_transit_outlined;
      case 'museum':
        return Icons.account_balance_outlined;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.place_outlined;
    }
  }
}
