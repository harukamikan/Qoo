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
  // プロフィール画面
  'コレクションを見る',
  '言語と地域',
  'ログアウト',
  '名前未設定',
  // フレンド機能
  '友達ID',
  '公開ID',
  'このIDで検索されます',
  '保存中...',
  'IDを保存',
  'ID検索して申請',
  '友達IDを入力',
  '送信中...',
  '友達申請',
  '今は申請がありません',
  'まだ友達がいません',
  '削除',
  '友達一覧',
  '拒否',
  '承認',
  '友達IDを更新しました',
  '友達申請を送りました',
  // ガチャ画面
  '1000コインを獲得しました！',
  'コイン不足',
  'ガチャを引くためのコインが不足しています。',
  '閉じる',
  'コイン補充',
  '補充',
  '最高レアリティに応じて演出が豪華に昇格！',
  'コイン',
  '1回ガチャ',
  '10連ガチャ',
  '画面タップでスキップ',
  '獲得結果',
  '獲得する',
  '〜 桜吹雪・通常引き 〜',
  '〜 秘伝一閃・SR昇格 〜',
  '〜 大輪極彩・SSR/UR確定 〜',
  // 投稿画面
  '投稿する',
  'Tips投稿',
  '旅先で役立つ情報や困りごとをシェアしよう',
  '旅行写真',
  '旅の思い出を写真で残そう',
  'アップロード中...',
  '写真を投稿しました',
  'アップロードに失敗しました',
  // 位置選択シート
  '選択した場所',
  '場所を選択',
  'スポット名で絞り込み（任意）',
  'この場所で決定',
  // 検索バー
  'キーワードやスポット名で検索...',
  'グルメ',
  '温泉',
  '文化',
  '交通',
  'マナー',
  'お金',
  'その他',
  // 地図バブル
  '一覧',
  // 写真撮影シート
  '今から撮る',
  'アルバムから選ぶ',
  '公開範囲',
  '全体公開',
  '友達のみ',
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
