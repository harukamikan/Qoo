import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:qoo/services/nearby_alert_service.dart';

void main() {
  // 福岡の適当な地点を基準に、100m圏内/圏外のダミーコメントを用意する。
  final here = ll.LatLng(33.5902, 130.4017);

  test('100m圏内の未通知コメントだけを返す', () {
    final result = findNewlyNearby(
      here: here,
      commentsById: {
        'near': {
          'place_name': 'すぐそこカフェ',
          'latitude': 33.5905, // 数十m程度の近距離
          'longitude': 130.4017,
        },
        'far': {
          'place_name': '遠くの神社',
          'latitude': 33.6500, // 明らかに100m超
          'longitude': 130.4017,
        },
      },
      alreadyNotified: {},
    );

    expect(result.map((e) => e.key), ['near']);
    expect(result.single.value, 'すぐそこカフェ');
  });

  test('通知済みのコメントは再通知しない', () {
    final result = findNewlyNearby(
      here: here,
      commentsById: {
        'near': {
          'place_name': 'すぐそこカフェ',
          'latitude': 33.5905,
          'longitude': 130.4017,
        },
      },
      alreadyNotified: {'near'},
    );

    expect(result, isEmpty);
  });

  test('緯度経度が欠けているコメントは無視する', () {
    final result = findNewlyNearby(
      here: here,
      commentsById: {
        'broken': {'place_name': '座標なし'},
      },
      alreadyNotified: {},
    );

    expect(result, isEmpty);
  });
}
