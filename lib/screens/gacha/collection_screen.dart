import 'package:flutter/material.dart';
import 'gacha_item.dart';
import 'inventory_manager.dart';

/// 所持アイテムの一覧・装備切り替え画面
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryData = InventoryProvider.of(context);

    return AnimatedBuilder(
      animation: inventoryData,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('コレクション')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: GachaItemType.values
                .map((type) => _buildSection(context, inventoryData, type))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    InventoryData inventoryData,
    GachaItemType type,
  ) {
    final items = inventoryData.getAcquiredItemsByType(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type.icon, size: 20, color: const Color(0xFF880E4F)),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '(${items.length})',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('まだ獲得していません', style: TextStyle(color: Colors.grey)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final equipped = inventoryData.isEquipped(item);
                return _buildItemCard(inventoryData, item, equipped);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    InventoryData inventoryData,
    GachaItem item,
    bool equipped,
  ) {
    return GestureDetector(
      onTap: () {
        if (equipped) {
          inventoryData.unequipItem(item.type);
        } else {
          inventoryData.equipItem(item);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: equipped ? item.rarity.color : Colors.grey.shade300,
            width: equipped ? 2.5 : 1,
          ),
          boxShadow: equipped
              ? [BoxShadow(color: item.rarity.color.withOpacity(0.5), blurRadius: 8)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: item.rarity.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.rarity.label,
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(height: 4),
            Text(item.iconOrAsset, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
            if (equipped)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  '装備中',
                  style: TextStyle(
                      fontSize: 8, color: Colors.pink, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
