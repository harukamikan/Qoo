import 'package:flutter/material.dart';
import 'gacha_item.dart';
import 'gacha_service.dart';

/// 所持アイテム & 装備状態（マーカースキン・アバタースキン・フレーム・バッジ）を管理
class InventoryData extends ChangeNotifier {
  final Set<String> _acquiredItemIds = {};
  final Map<GachaItemType, String?> _equippedItemIds = {
    for (final type in GachaItemType.values) type: null,
  };

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Set<String> get acquiredItemIds => Set.unmodifiable(_acquiredItemIds);

  /// アプリ起動時にローカルストレージから読み込む
  Future<void> loadFromStorage() async {
    final acquired = await GachaService.getAcquiredItemIds();
    final equipped = await GachaService.getEquippedItemIds();
    _acquiredItemIds
      ..clear()
      ..addAll(acquired);
    _equippedItemIds.addAll(equipped);
    _isLoaded = true;
    notifyListeners();
  }

  bool isAcquired(String itemId) => _acquiredItemIds.contains(itemId);

  bool isEquipped(GachaItem item) => _equippedItemIds[item.type] == item.id;

  /// 指定した種別の現在の装備アイテムを取得（未装備なら null）
  GachaItem? getEquippedItem(GachaItemType type) {
    final id = _equippedItemIds[type];
    if (id == null) return null;
    return GachaService.getItemById(id);
  }

  /// ガチャなどで新規アイテムを獲得した際に呼び出す
  Future<void> addAcquiredItem(GachaItem item) async {
  debugPrint('ADD ITEM: ${item.id} / ${item.name}');

  if (_acquiredItemIds.add(item.id)) {
    debugPrint('ADDED: $_acquiredItemIds');

    await GachaService.saveAcquiredItem(item.id);

    debugPrint('SAVED: ${await GachaService.getAcquiredItemIds()}');

    notifyListeners();
  } else {
    debugPrint('ALREADY ACQUIRED: ${item.id}');
  }
}

  /// アイテムを装備する（種別ごとに1つまで。未所持のアイテムは装備不可）
  Future<void> equipItem(GachaItem item) async {
    if (!_acquiredItemIds.contains(item.id)) return;
    _equippedItemIds[item.type] = item.id;
    await GachaService.saveEquippedItem(item.type, item.id);
    notifyListeners();
  }

  /// 指定種別の装備を解除する
  Future<void> unequipItem(GachaItemType type) async {
    _equippedItemIds[type] = null;
    await GachaService.saveEquippedItem(type, null);
    notifyListeners();
  }

  /// 指定種別で所持しているアイテム一覧を取得
  List<GachaItem> getAcquiredItemsByType(GachaItemType type) {
    return GachaService.masterItemList
        .where((item) => item.type == type && _acquiredItemIds.contains(item.id))
        .toList();
  }
}

class InventoryProvider extends InheritedNotifier<InventoryData> {
  const InventoryProvider({
    super.key,
    required InventoryData inventoryData,
    required super.child,
  }) : super(notifier: inventoryData);

  static InventoryData of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<InventoryProvider>();
    assert(provider != null, 'InventoryProvider がコンテキスト内に見つかりません。');
    return provider!.notifier!;
  }
}
