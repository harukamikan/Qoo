import 'package:geolocator/geolocator.dart';
import '../models/local_hack.dart';

class LocalHackService {
  // ★ 事前登録しておく運営のHackデータリスト（櫛田神社などをここに追加）
  static final List<LocalHack> initialHacks = [
    LocalHack(
      id: 'hack_kushida_01',
      title: '櫛田神社 参拝ガイド（7 Step）',
      category: '神社',
      latitude: 33.5930,
      longitude: 130.4106,
      content: '''⛩️ 櫛田神社 参拝ガイド（7 Step）
信仰に関わらず、誰でも歓迎されます。心を落ち着かせてお参りしましょう！

1. 鳥居の前で一礼：境内の入口（鳥居）をくぐる前に、敬意を込めて1回お辞儀をします。
2. 参道は端を歩く：中央は「神様の通り道」です。真ん中を避けて端を歩きましょう。
3. 手水舎（ちょうずや）で清める：右手で柄杓（ひしゃく）を持って水を汲み、「左手→右手」の順にかけます。手のひらに水を溜めて口をすすぎます（※柄杓に直接口をつけるのは厳禁！）。もう一度左手を洗い、最後に柄杓の柄を流して戻します。
4. 鈴を鳴らす：紐を揺らしてカランカランと音を立て、神様に訪問を知らせます。
5. お賽銭（さいせん）を入れる：箱へそっと入れます。「ご縁（Good fortune）」につながる「5円玉」が人気ですが、金額は自由です。
6. 二礼 二拍手 一礼：2回 深くお辞儀をする ➔ 手を2回 叩いて音を鳴らし、手を合わせたままお祈りをする ➔ 最後に1回 深くお辞儀をする。
7. 最後にもう一度一礼：鳥居を出て境内を去る際、本殿に向かって「ありがとう」の気持ちを込めてお辞儀をします。''',
    ),
    // 今後新しいスポットを追加する場合は、ここに同じように書いて並べます
  LocalHack(
      id: 'hack_tochoji_01',
      title: '東長寺 拝観＆護摩焚きガイド',
      category: '寺',
      latitude: 33.5952,
      longitude: 130.4143,
      content: '''🛕 東長寺（とうちょうじ） 拝観＆護摩焚きガイド
空海が創建した日本最古の密教寺院です。大仏様や厳粛な儀式をリスペクトを持って拝観しましょう！

【基本の境内マナー】
・撮影は完全禁止（Strictly No Photos）: 「福岡大仏」の鎮座する大仏殿内、および本堂内での写真・動画撮影は一切禁止です。
・静寂を保つ: 観光地であると同時に「祈りの場」です。大声での会話は控え、スマホはマナーモードか電源OFFにしてバッグへ。
・大仏殿への入場は100円: 福岡大仏と「地獄・極楽めぐり」の拝観には100円（灯明・線香代）が必要です。あらかじめ小銭を用意しておきましょう。

【毎月開催！「護摩焚き」参加マナー】
・靴下（ストッキング等）の着用が必須: 28日に本堂（畳敷き）へ上がる際はもちろん、1日の大仏殿も靴を脱いで入場するため素足は厳禁です。必ず綺麗な靴下を着用していきましょう。
・僧侶の修行・祈りの場: 護摩焚きは僧侶の厳粛な修行でもあります。お堂に入ったら静かに手を合わせ、心を落ち着かせて拝観してください。''',
    ),

    // --- バス乗り方マナー（共通文章） ---
    const String busContent = '''🚌バスの乗り方ガイド

乗車時のマナー
・バス停では危ないので、完全に止まるまで下がって待つ
・順番を守り、一列に並んで乗り込む
・ドア付近で立ち止まらず、車内の中ほどへ進む
・大きな荷物は、他の人の邪魔にならないよう体の前や足元に置く

車内でのマナー
・携帯電話はマナーモードにし、通話は控える
・大きな声での私語や、周囲の迷惑になる騒音は避ける
・混雑時は席を譲り合い、空席があれば座る
・走行中の立ち歩きや移動はしない
・両替は、バスが完全に止まっている時に行う

降車時のマナー
・アナウンスを聞き、早めに降車ボタンを押す
・バスが完全に止まるまで、席を立たない''';

    // 1. 博多駅バスターミナル
    LocalHack(
      id: 'hack_bus_hakata_bt',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5908,
      longitude: 130.4194,
      content: busContent,
    ),

    // 2. 博多駅前 Aのりば（西日本シティ銀行前）
    LocalHack(
      id: 'hack_bus_hakata_mae_a',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5896,
      longitude: 130.4185,
      content: busContent,
    ),

    // 3. 博多駅前 B・C・Dのりば（博多駅博多口前）
    LocalHack(
      id: 'hack_bus_hakata_mae_bcd',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5898,
      longitude: 130.4190,
      content: busContent,
    ),

    // 4. 博多駅前 E・Fのりば（KITTE博多前）
    LocalHack(
      id: 'hack_bus_hakata_mae_ef',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5888,
      longitude: 130.4198,
      content: busContent,
    ),

    // 5. 博多駅筑紫口バス停
    LocalHack(
      id: 'hack_bus_hakata_chikushi',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5898,
      longitude: 130.4210,
      content: busContent,
    ),

    // 6. 博多駅筑紫口（合同庁舎前）バス停
    LocalHack(
      id: 'hack_bus_hakata_godo',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5912,
      longitude: 130.4225,
      content: busContent,
    ),

    // --- 銭湯・温泉マナー（共通文章） ---
    const String onsenContent = '''♨銭湯・温泉の基本マナーカード

【基本の6大マナー】
・水着・下着はNG（服をすべて脱いで入る）
・かけ湯・体を洗う（湯船に入る前に汚れを洗い流す）
・シャワーの使い方（座って使い、出っぱなしにしない）
・タオルは湯船に入れない（頭に乗せるか縁に置く）
・洗濯は禁止
・脱衣場へ戻る時は体を拭く（脱衣所の床を濡らさない）

【博多・福岡エリアでの注意点】
・全館完全禁煙：福岡県内の公衆浴場は法律・条例により店内全面禁煙となっています。
・入れ墨（タトゥー）のルール：レトロな街の銭湯はタトゥーOKな場所も多いですが、大型スーパー銭湯や温泉施設では「タトゥー不可」または「シールで隠す必要あり」の場合が多いです。
・混浴の年齢制限：福岡県では、6歳以上の男女の混浴は禁止されています。''';

    // 1. 八百治の湯（博多駅近く）
    LocalHack(
      id: 'hack_onsen_yaoji',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.5872,
      longitude: 130.4168,
      content: onsenContent,
    ),

    // 2. 博多由布院・武雄温泉 万葉の湯
    LocalHack(
      id: 'hack_onsen_manyo',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.5828,
      longitude: 130.4385,
      content: onsenContent,
    ),

    // 3. 天然温泉 波葉の湯（ベイサイドプレイス博多）
    LocalHack(
      id: 'hack_onsen_namiha',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.6038,
      longitude: 130.3980,
      content: onsenContent,
    ),

    // 4. 鶴亀湯（博多区住吉のレトロ銭湯）
    LocalHack(
      id: 'hack_onsen_tsurukame',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.5855,
      longitude: 130.4120,
      content: onsenContent,
    ),

    // 5. 千代の湯（博多区千代）
    LocalHack(
      id: 'hack_onsen_chiyo',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.6042,
      longitude: 130.4165,
      content: onsenContent,
    ),

    // 6. 吉塚温泉（博多区吉塚）
    LocalHack(
      id: 'hack_onsen_yoshizuka',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.6080,
      longitude: 130.4285,
      content: onsenContent,
    ),
  ];

  // 現在地から500m以内にあるHackを抽出する関数
  List<LocalHack> getHacksAroundUser({
    required double userLat,
    required double userLng,
    List<LocalHack>? allHacks, // 引数が渡されない場合は上記の initialHacks を使う
  }) {
    final targetHacks = allHacks ?? initialHacks;
    List<LocalHack> nearbyHacks = [];

    for (var hack in targetHacks) {
      // ユーザーの現在地とHackの距離（メートル単位）を計算
      double distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        hack.latitude,
        hack.longitude,
      );

      // 500m以内の場合に追加
      if (distanceInMeters <= 500) {
        nearbyHacks.add(hack);
      }
    }

    return nearbyHacks;
  }
}