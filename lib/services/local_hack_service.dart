import 'package:geolocator/geolocator.dart';
import '../models/local_hack.dart';

class LocalHackService {
  // --------------------------------------------------
  // 1. 共通のマナー文章（リストの外で定義）
  // --------------------------------------------------

  // バス乗車マナー
  static const String busContent = '''🚌バスの乗り方ガイド

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

  // 銭湯・温泉マナー
  static const String onsenContent = '''♨銭湯・温泉の基本マナーカード

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

  // 屋台マナー
  static const String yataiContent = '''🏮 中洲・天神の屋台（Yatai）を楽しむマナー＆コツ
福岡・博多だけにしかない特別な夜の体験です！ルールを守って楽しくハシゴ（Food hopping）しましょう。

【基本のマナー＆準備】
・トイレは事前に済ませる: 屋台にはトイレがありません。行く前に済ませるか、困ったら店主に近くの公衆トイレを聞きましょう。
・荷物は小さくまとめる: 店内が狭いため、大きなスーツケースはホテルやロッカーに預けておくのがスマートです。
・長居はせず席を譲る: 席数が10席前後と少ないため、食べ終わったら次の人に席を譲りましょう。ハシゴ酒を楽しむのが屋台流です。
・詰め合って座る: お互いに少しずつ席を詰めて、みんなで気持ちよく座りましょう。

【注文＆料金のルール】
・ルールと価格を事前にチェック: お通し（Appetizer charge）や「1人1品注文（One drink/food order）」などのルールがある店もあります。入店時にメニュー表を確認しましょう。
・予約は基本的に不可: 来た順番に案内されるのが基本です。行列がある場合は並んで待ちましょう。''';

  // ラーメンマナー
  static const String ramenContent = '''🍜 博多ラーメン（Hakata Ramen）を楽しむマナー＆コツ
とんこつラーメンの本場・博多での食事体験を100%楽しむためのローカルルールです。サクッと食べて粋に楽しもう！

【注文のルール】
・麺の硬さを指定する: 注文時に麺の硬さを伝えるのが博多流です。「カタ（Hard）」や「バリカタ（Very Hard）」が人気です。
・替え玉（Kaedama）は早めに注文: おかわり（追加の麺）を頼む場合は、1玉目の麺が半分〜1/3くらい残っているタイミングで頼むと、途切れず美味しく食べられます。
・スープは残しておく: 替え玉をする予定があるなら、最初にスープを飲み干さないように注意しましょう。

【食事中・店内でのマナー】
・卓上トッピングは後から: 紅生姜や高菜、ゴマなどの無料トッピングは、まずオリジナルのスープを味わってから少しずつ入れましょう。
・写真は手短に: 熱いうちに食べるのが一番です。写真撮影は手短に済ませ、調理中のスタッフを直接撮影するのは控えましょう。

【退店時のマナー】
・食べ終わったらすぐ退店: ラーメン店は回転率が大切です。食後の長居は避け、席を譲りましょう。
・「Gochisosama!（ごちそうさま）」: お店を出る時に店主に一言感謝を伝えると、とても喜ばれます。''';


  // --------------------------------------------------
  // 2. マスターデータリスト
  // --------------------------------------------------
  static final List<LocalHack> initialHacks = [
    // ⛩️ 神社・寺
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

    // 🚌 バス乗り場
    LocalHack(
      id: 'hack_bus_hakata_bt',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5908,
      longitude: 130.4194,
      content: busContent,
    ),
    LocalHack(
      id: 'hack_bus_hakata_mae_a',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5896,
      longitude: 130.4185,
      content: busContent,
    ),
    LocalHack(
      id: 'hack_bus_hakata_mae_bcd',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5898,
      longitude: 130.4190,
      content: busContent,
    ),
    LocalHack(
      id: 'hack_bus_hakata_mae_ef',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5888,
      longitude: 130.4198,
      content: busContent,
    ),
    LocalHack(
      id: 'hack_bus_hakata_chikushi',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5898,
      longitude: 130.4210,
      content: busContent,
    ),
    LocalHack(
      id: 'hack_bus_hakata_godo',
      title: '🚌 バスの乗り方ガイド（博多エリア）',
      category: '交通',
      latitude: 33.5912,
      longitude: 130.4225,
      content: busContent,
    ),

    // ♨ 銭湯・温泉
    LocalHack(
      id: 'hack_onsen_yaoji',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.5872,
      longitude: 130.4168,
      content: onsenContent,
    ),
    LocalHack(
      id: 'hack_onsen_manyo',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.5828,
      longitude: 130.4385,
      content: onsenContent,
    ),
    LocalHack(
      id: 'hack_onsen_namiha',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.6038,
      longitude: 130.3980,
      content: onsenContent,
    ),
    LocalHack(
      id: 'hack_onsen_tsurukame',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.5855,
      longitude: 130.4120,
      content: onsenContent,
    ),
    LocalHack(
      id: 'hack_onsen_chiyo',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.6042,
      longitude: 130.4165,
      content: onsenContent,
    ),
    LocalHack(
      id: 'hack_onsen_yoshizuka',
      title: '♨ 銭湯・温泉の基本マナー（博多エリア）',
      category: '温泉・銭湯',
      latitude: 33.6080,
      longitude: 130.4285,
      content: onsenContent,
    ),

    // 🏮 屋台
    LocalHack(
      id: 'hack_yatai_nakasu',
      title: '🏮 屋台（Yatai）を楽しむマナー＆コツ',
      category: 'グルメ・屋台',
      latitude: 33.5898,
      longitude: 130.4075,
      content: yataiContent,
    ),
    LocalHack(
      id: 'hack_yatai_tenjin',
      title: '🏮 屋台（Yatai）を楽しむマナー＆コツ',
      category: 'グルメ・屋台',
      latitude: 33.5916,
      longitude: 130.3988,
      content: yataiContent,
    ),
    LocalHack(
      id: 'hack_yatai_tenjin_south',
      title: '🏮 屋台（Yatai）を楽しむマナー＆コツ',
      category: 'グルメ・屋台',
      latitude: 33.5885,
      longitude: 130.4002,
      content: yataiContent,
    ),
    LocalHack(
      id: 'hack_yatai_nagahama',
      title: '🏮 屋台（Yatai）を楽しむマナー＆コツ',
      category: 'グルメ・屋台',
      latitude: 33.5960,
      longitude: 130.3895,
      content: yataiContent,
    ),

    // 🍜 ラーメン
    LocalHack(
      id: 'hack_ramen_issou_hakata',
      title: '🍜 博多ラーメンを楽しむマナー＆コツ',
      category: 'グルメ・ラーメン',
      latitude: 33.5891,
      longitude: 130.4233,
      content: ramenContent,
    ),
    LocalHack(
      id: 'hack_ramen_ikkousha_main',
      title: '🍜 博多ラーメンを楽しむマナー＆コツ',
      category: 'グルメ・ラーメン',
      latitude: 33.5882,
      longitude: 130.4162,
      content: ramenContent,
    ),
    LocalHack(
      id: 'hack_ramen_shinshin_kitte',
      title: '🍜 博多ラーメンを楽しむマナー＆コツ',
      category: 'グルメ・ラーメン',
      latitude: 33.5888,
      longitude: 130.4198,
      content: ramenContent,
    ),
    LocalHack(
      id: 'hack_ramen_ichiran_hakata',
      title: '🍜 博多ラーメンを楽しむマナー＆コツ',
      category: 'グルメ・ラーメン',
      latitude: 33.5896,
      longitude: 130.4178,
      content: ramenContent,
    ),
    LocalHack(
      id: 'hack_ramen_ippudo_deitos',
      title: '🍜 博多ラーメンを楽しむマナー＆コツ',
      category: 'グルメ・ラーメン',
      latitude: 33.5898,
      longitude: 130.4208,
      content: ramenContent,
    ),
    LocalHack(
      id: 'hack_ramen_kawabata',
      title: '🍜 博多ラーメンを楽しむマナー＆コツ',
      category: 'グルメ・ラーメン',
      latitude: 33.5925,
      longitude: 130.4105,
      content: ramenContent,
    ),
  ];

  // --------------------------------------------------
  // 3. 周辺Hack抽出ロジック
  // --------------------------------------------------
  List<LocalHack> getHacksAroundUser({
    required double userLat,
    required double userLng,
    List<LocalHack>? allHacks,
  }) {
    final targetHacks = allHacks ?? initialHacks;
    List<LocalHack> nearbyHacks = [];

    for (var hack in targetHacks) {
      double distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        hack.latitude,
        hack.longitude,
      );

      if (distanceInMeters <= 500) {
        nearbyHacks.add(hack);
      }
    }

    return nearbyHacks;
  }
}