import 'package:flutter/material.dart';

class CoinData extends ChangeNotifier {
  int coins = 0; // 初期コイン数

  // コイン加算
  void addCoins(int amount) {
    coins += amount;
    notifyListeners(); // 画面全体に更新を通知
  }

  // コイン消費（足りている場合は true）
  bool useCoins(int amount) {
    if (coins >= amount) {
      coins -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }
}

class CoinDataProvider extends InheritedNotifier<CoinData> {
  const CoinDataProvider({
    super.key,
    required CoinData coinData,
    required super.child,
  }) : super(notifier: coinData);

  static CoinData of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<CoinDataProvider>();
    assert(provider != null, 'CoinDataProvider がコンテキスト内に見つかりません。');
    return provider!.notifier!;
  }
}
