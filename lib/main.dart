import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/ui_translations.dart';
import 'screens/gacha/inventory_manager.dart';
import 'state/app_data.dart';
import 'screens/gacha/coin_manager.dart';

/// アプリ起動時に翻訳しておくUI固定文言の一覧（日本語）。
/// 新しい画面・文言を追加したら、ここにも追加する。
const List<String> kUiTexts = [
  // ボトムナビ
  '地図',
  'ガチャ',
  '口コミ',
  '保存',
  'プロフィール',
  // 地図画面
  'すべて',
  '再読み込み',
  '写真を撮る',
  '現在地にTips投稿',
  // 投稿ダイアログ
  'Tipsを投稿',
  'スポット名 / 場所の名前:',
  '例: ○○公園、駅前カフェ',
  'カテゴリ:',
  'Tips / アドバイス:',
  '旅行者へのおすすめポイントや注意点...',
  'キャンセル',
  '投稿する',
];

/// アプリ起動時に翻訳しておくUI固定文言の一覧（英語）。
/// カテゴリ名など、もともと英語で管理されている文言はこちら。
const List<String> kUiTextsEn = [
  'All',
  'Food',
  'Onsen',
  'Culture',
  'Transportation',
  'Manners',
  'Money',
  'Other',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/app.env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AuthService.instance.ensureInitialized();

  // AppDataを先に読み込む
  await AppData.instance.ensureLoaded();

  // UI文言の翻訳をプリロード（初回のみAPI呼び出し、以降はローカルキャッシュ）
  await UiTranslations.preload(kUiTexts, originalLang: 'ja');
  await UiTranslations.preload(kUiTextsEn, originalLang: 'en');

  // Inventoryをアプリ全体で1つだけ作る
  final inventoryData = InventoryData();
  await inventoryData.loadFromStorage();

  // Coinもアプリ全体で1つだけ作る
  final coinData = CoinData();

  runApp(
    CoinDataProvider(
      coinData: coinData,
      child: InventoryProvider(
        inventoryData: inventoryData,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qoo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
