import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'gacha_item.dart';

class GachaService {
  static const String _inventoryPrefsKey = 'user_acquired_item_ids';
  static const String _equippedPrefsKeyPrefix = 'user_equipped_item_';

  /// ガチャの排出ラインナップ（マスターデータ）
  static final List<GachaItem> masterItemList = [
    // --- UR (超激レア) ---
    // const GachaItem(
    //   id: 'frame_hakata_master',
    //   name: '博多マスターフレーム',
    //   description: '博多の街を極めし者に贈られる黄金のラーメン装飾枠！',
    //   // type: GachaItemType.profileFrame,
    //   rarity: Rarity.UR,
    //   iconOrAsset: '🍜',
    //   regionName: '博多',
    // ),

    // --- SSR (激レア) ---
    const GachaItem(
      id: 'skin_ramen_pin',
      name: 'とんこつラーメンピン',
      description: '地図上の投稿ピンが美味しそうなラーメンアイコンに変化します。',
      type: GachaItemType.markerSkin,
      rarity: Rarity.SSR,
      iconOrAsset: '🍜',
      regionName: '博多',
    ),
    const GachaItem(
      id: 'avatar_mentaiko',
      name: '明太子ちゃんアバター',
      description: '自分の現在地アイコンが明太子キャラクターになります。',
      type: GachaItemType.avatarSkin,
      rarity: Rarity.SSR,
      iconOrAsset: '🌶️',
      regionName: '福岡',
    ),

    // --- SR (レア) ---
    // const GachaItem(
    //   id: 'badge_onsen_bugyo',
    //   name: '温泉奉行バッジ',
    //   description: '温泉地のTipsに詳しいことを証明するコレクターズバッジ。',
    //   type: GachaItemType.badge,
    //   rarity: Rarity.SR,
    //   iconOrAsset: '♨️',
    //   regionName: '全国',
    // ),
    const GachaItem(
      id: 'skin_onsen_bubble',
      name: '湯けむり吹き出しスキン',
      description: 'コメントバブルから湯けむりのエフェクトが立ち上ります。',
      type: GachaItemType.markerSkin,
      rarity: Rarity.SR,
      iconOrAsset: '♨️',
      regionName: '別府',
    ),

    // --- R (レア寄りノーマル) ---
    // const GachaItem(
    //   id: 'badge_first_step',
    //   name: 'ビギナー旅人バッジ',
    //   description: '旅の第一歩を踏み出した証。',
    //   type: GachaItemType.badge,
    //   rarity: Rarity.R,
    //   iconOrAsset: '🧳',
    // ),
    const GachaItem(
      id: 'avatar_yuru_chara',
      name: 'ご当地ゆるキャラアバター',
      description: '自分の現在地アイコンがご当地ゆるキャラに変化します。',
      type: GachaItemType.avatarSkin,
      rarity: Rarity.R,
      iconOrAsset: '🐻',
      regionName: '全国',
    ),

    // --- アバタースキン（新規追加） ---
    const GachaItem(
      id: 'avatar_kappa_jar',
      name: '河童瓶アバター',
      description: 'キュウリを持ったカッパが閉じ込められたガラス瓶アバター。',
      type: GachaItemType.avatarSkin,
      rarity: Rarity.R,
      iconOrAsset: 'assets/images/kappa.png',
      regionName: '全国',
    ),

const GachaItem(
  id: 'avatar_katana_jar',
  name: '二本刀瓶アバター',
  description: '交差する二本刀が納められたガラス瓶アバター。',
  type: GachaItemType.avatarSkin,
  rarity: Rarity.R,
  iconOrAsset: 'assets/images/katana.png',
  regionName: '全国',
),

    // --- N (ノーマル) ---
    // const GachaItem(
    //   id: 'frame_simple_wood',
    //   name: 'ウッドフレーム',
    //   description: 'ナチュラルな木目調のプロフィール枠。',
    //   type: GachaItemType.profileFrame,
    //   rarity: Rarity.N,
    //   iconOrAsset: '🪵',
    // ),
    const GachaItem(
      id: 'skin_simple_pin',
      name: 'シンプル旅ピン',
      description: '地図上の投稿ピンをシンプルなしずく型に変更します。',
      type: GachaItemType.markerSkin,
      rarity: Rarity.N,
      iconOrAsset: '📍',
    ),

    const GachaItem(
      id: 'avatar_fuji_jar',
      name: '富士山瓶アバター',
      description: '赤日と富士山が描かれためでたいガラス瓶アバター。',
      type: GachaItemType.avatarSkin,
      rarity: Rarity.N,
      iconOrAsset: 'assets/images/MtFuji.png',
      regionName: '静岡・山梨',
),
  ];

  /// 重み付け抽選でガチャを1回引く
  static GachaItem drawGacha() {
    final random = Random();

    // 全アイテムのレアリティ重みの合計を計算
    final totalWeight = masterItemList.fold<int>(
      0, (sum, item) => sum + item.rarity.weight,
    );

    int randVal = random.nextInt(totalWeight);

    for (final item in masterItemList) {
      if (randVal < item.rarity.weight) {
        return item;
      }
      randVal -= item.rarity.weight;
    }

    return masterItemList.last;
  }

  /// IDからアイテムを取得（見つからない場合は null）
  static GachaItem? getItemById(String itemId) {
    for (final item in masterItemList) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  /// 獲得したアイテムIDをローカルストレージに保存
  static Future<void> saveAcquiredItem(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final acquired = prefs.getStringList(_inventoryPrefsKey) ?? [];
    if (!acquired.contains(itemId)) {
      acquired.add(itemId);
      await prefs.setStringList(_inventoryPrefsKey, acquired);
    }
  }

  /// 所持済みアイテムID一覧を取得
  static Future<Set<String>> getAcquiredItemIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_inventoryPrefsKey) ?? [];
    return list.toSet();
  }

  /// 種別ごとの装備アイテムIDを保存（null を渡すと装備解除）
  static Future<void> saveEquippedItem(GachaItemType type, String? itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _equippedPrefsKeyPrefix + type.name;
    if (itemId == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, itemId);
    }
  }

  /// 種別ごとの装備アイテムID一覧を取得
  static Future<Map<GachaItemType, String?>> getEquippedItemIds() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final type in GachaItemType.values)
        type: prefs.getString(_equippedPrefsKeyPrefix + type.name),
    };
  }
}
