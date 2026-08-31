import 'package:flutter/material.dart';

/// 排出アイテムの種別
enum GachaItemType {
  markerSkin,   // マーカー用スキン（ラーメンピン等）
  avatarSkin,   // ご当地アバター
  profileFrame, // プロフィールフレーム
  badge,        // 限定バッジ
}

/// 種別ごとの表示用ラベル・アイコン
extension GachaItemTypeExtension on GachaItemType {
  String get label {
    switch (this) {
      case GachaItemType.markerSkin:
        return 'マーカースキン';
      case GachaItemType.avatarSkin:
        return 'アバタースキン';
      case GachaItemType.profileFrame:
        return 'プロフィールフレーム';
      case GachaItemType.badge:
        return 'バッジ';
    }
  }

  /// 装備を切り替えられる種別かどうか（バッジも「代表バッジ」として1つ装備できる）
  IconData get icon {
    switch (this) {
      case GachaItemType.markerSkin:
        return Icons.location_on;
      case GachaItemType.avatarSkin:
        return Icons.face_retouching_natural;
      case GachaItemType.profileFrame:
        return Icons.crop_square;
      case GachaItemType.badge:
        return Icons.military_tech;
    }
  }
}

/// レアリティ定義
enum Rarity {
  N(weight: 50, label: 'N', color: Colors.grey),
  R(weight: 30, label: 'R', color: Colors.blue),
  SR(weight: 15, label: 'SR', color: Colors.purple),
  SSR(weight: 4, label: 'SSR', color: Colors.orange),
  UR(weight: 1, label: 'UR', color: Colors.redAccent);

  final int weight; // 抽選時の重み（確率）
  final String label;
  final Color color;

  const Rarity({required this.weight, required this.label, required this.color});
}

/// ガチャアイテムのデータモデル
class GachaItem {
  final String id;
  final String name;
  final String description;
  final GachaItemType type;
  final Rarity rarity;
  final String iconOrAsset; // アイコン画像パス または 絵文字
  final String? regionName;  // ご当地（博多、別府など）

  const GachaItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.iconOrAsset,
    this.regionName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'rarity': rarity.name,
    'iconOrAsset': iconOrAsset,
    'regionName': regionName,
  };
}
