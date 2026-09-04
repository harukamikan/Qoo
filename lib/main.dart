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
import 'services/local_hack_service.dart';

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
  '地域コレクション',
  '店舗承認（Admin）',
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
  // 言語と地域設定画面
  '表示言語',
  '地域',
  '言語と地域を更新しました',
  '保存',
  // 保存タブ（友達の写真）
  '友達の写真',
  '公開された写真を友達・自分の範囲で見られます',
  '自分',
  '友達',
  '両方',
  '写真がまだありません',
  '写真を読み込めませんでした',
  // 店舗登録画面
  '店舗名を入力してください',
  'マップから住所・位置を指定してください',
  '電話番号を入力してください',
  'ログイン情報が取得できませんでした。もう一度ログインしてください',
  '登録に失敗しました。通信環境を確認してもう一度お試しください',
  '店舗登録',
  'お店の情報を登録してください',
  '店舗名',
  'マップから住所・位置を指定',
  '緯度',
  '経度',
  '電話番号',
  'SMS等での認証は行いません。連絡先として保存されます',
  '店舗を登録する',
  // 店舗管理画面
  '既にメール確認済みです',
  '確認メールを',
  'に再送信しました',
  '送信しすぎです。しばらく待ってから再度お試しください',
  '送信に失敗しました',
  '店舗管理',
  'ログイン情報を取得できませんでした',
  '店舗情報が見つかりませんでした',
  'メール確認済み',
  'メール未確認',
  '確認メールを再送信',
  '届かない場合は迷惑メールフォルダもご確認ください',
  '店舗コメント・Local Hackの編集は準備中です',
  '観光客側の地図をプレビュー',
  // Local Hack（観光ガイド）
  '櫛田神社 参拝ガイド（7 Step）',
  '東長寺 拝観＆護摩焚きガイド',
  '🚌 バスの乗り方ガイド（博多エリア）',
  '♨ 銭湯・温泉の基本マナー（博多エリア）',
  '🏮 屋台（Yatai）を楽しむマナー＆コツ',
  '🍜 博多ラーメンを楽しむマナー＆コツ',
  LocalHackService.kushidaContent,
  LocalHackService.tochojiContent,
  LocalHackService.busContent,
  LocalHackService.onsenContent,
  LocalHackService.yataiContent,
  LocalHackService.ramenContent,
  // Local Hackカテゴリ
  '神社',
  '寺',
  '温泉・銭湯',
  'グルメ・屋台',
  'グルメ・ラーメン',
  // 地域コレクション画面
  '達成しました！',
  'ご当地コレクション',
  'コレクションがまだありません',
  '達成',
  'お店コレクション',
  'マイコレクション',
  'みんなのコレクション',
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
      title: 'Jam',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
