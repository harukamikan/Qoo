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